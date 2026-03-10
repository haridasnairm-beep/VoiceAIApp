package com.vaanix.app

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.provider.OpenableColumns
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.vaanix.app/file_intent"
    private val AUDIO_CHANNEL = "com.vaanix.app/audio_focus"
    private var pendingFilePath: String? = null
    private var pendingSharedAudioPath: String? = null
    private var pendingSharedAudioFilename: String? = null
    private var wasMediaPlayingBefore: Boolean = false

    // Single audio focus request + listener — never recreated, so abandon
    // always releases the exact same request that was granted.
    private var holdingFocus: Boolean = false
    private val focusListener = AudioManager.OnAudioFocusChangeListener { /* no-op */ }
    private val focusRequest: AudioFocusRequest by lazy {
        AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )
            .setOnAudioFocusChangeListener(focusListener)
            .build()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getOpenFilePath" -> {
                        result.success(pendingFilePath)
                        pendingFilePath = null
                    }
                    "getSharedAudioInfo" -> {
                        if (pendingSharedAudioPath != null) {
                            val info = mapOf(
                                "path" to pendingSharedAudioPath,
                                "filename" to pendingSharedAudioFilename
                            )
                            pendingSharedAudioPath = null
                            pendingSharedAudioFilename = null
                            result.success(info)
                        } else {
                            result.success(null)
                        }
                    }
                    "convertToWav" -> {
                        val inputPath = call.argument<String>("inputPath")
                        val outputPath = call.argument<String>("outputPath")
                        if (inputPath == null || outputPath == null) {
                            result.error("INVALID_ARGS", "inputPath and outputPath required", null)
                        } else {
                            Thread {
                                try {
                                    val success = convertAudioToWav(inputPath, outputPath)
                                    runOnUiThread {
                                        if (success) result.success(outputPath)
                                        else result.error("CONVERT_FAILED", "Audio conversion failed", null)
                                    }
                                } catch (e: Exception) {
                                    runOnUiThread {
                                        result.error("CONVERT_ERROR", e.message, null)
                                    }
                                }
                            }.start()
                        }
                    }
                    "exitApp" -> {
                        result.success(null)
                        finishAffinity()
                        android.os.Process.killProcess(android.os.Process.myPid())
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkMediaActive" -> {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        wasMediaPlayingBefore = audioManager.isMusicActive
                        result.success(wasMediaPlayingBefore)
                    }
                    "requestAudioFocus" -> {
                        requestAudioFocus()
                        result.success(true)
                    }
                    "abandonAudioFocus" -> {
                        abandonAudioFocus()
                        result.success(true)
                    }
                    "resumeMedia" -> {
                        resumeMedia()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    /// Request transient exclusive audio focus before recording.
    /// Other media apps receive AUDIOFOCUS_LOSS_TRANSIENT and should auto-resume
    /// when we abandon focus later.
    private fun requestAudioFocus() {
        holdingFocus = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.requestAudioFocus(focusRequest)
        }
    }

    /// Abandon audio focus so other media apps can resume playback.
    private fun abandonAudioFocus() {
        holdingFocus = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.abandonAudioFocusRequest(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.abandonAudioFocus(null)
        }
    }

    /// Simulate a media "play" button press to resume whatever media app was playing.
    /// Only dispatches if media was actually active before we requested audio focus.
    private fun resumeMedia() {
        if (!wasMediaPlayingBefore) return
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val eventTime = SystemClock.uptimeMillis()
        val downEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PLAY, 0)
        val upEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PLAY, 0)
        audioManager.dispatchMediaKeyEvent(downEvent)
        audioManager.dispatchMediaKeyEvent(upEvent)
        wasMediaPlayingBefore = false
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        // Handle shared audio files (ACTION_SEND with audio/* MIME type)
        if (intent.action == Intent.ACTION_SEND && intent.type?.startsWith("audio/") == true) {
            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            }
            if (uri != null) {
                try {
                    val filename = getDisplayName(uri) ?: "shared_audio"
                    val extension = filename.substringAfterLast('.', "m4a")
                    val tempFile = File(cacheDir, "shared_audio.$extension")
                    val inputStream = contentResolver.openInputStream(uri) ?: return
                    tempFile.outputStream().use { out ->
                        inputStream.copyTo(out)
                    }
                    inputStream.close()
                    pendingSharedAudioPath = tempFile.absolutePath
                    pendingSharedAudioFilename = filename
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            return
        }

        // Handle .vnbak backup file opens (ACTION_VIEW)
        if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data!!
            try {
                val inputStream = contentResolver.openInputStream(uri) ?: return
                val tempFile = File(cacheDir, "restore_backup.vnbak")
                tempFile.outputStream().use { out ->
                    inputStream.copyTo(out)
                }
                inputStream.close()
                pendingFilePath = tempFile.absolutePath
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    /// Get the display name of a content URI (original filename).
    private fun getDisplayName(uri: Uri): String? {
        var name: String? = null
        try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) name = cursor.getString(idx)
                }
            }
        } catch (_: Exception) {}
        return name
    }

    /// Convert any audio file to 16kHz 16-bit mono WAV using Android MediaCodec.
    /// This enables Whisper to process shared audio in .opus, .ogg, .mp3, .aac, etc.
    private fun convertAudioToWav(inputPath: String, outputPath: String): Boolean {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(inputPath)

            // Find the audio track
            var audioTrackIndex = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val trackFormat = extractor.getTrackFormat(i)
                val mime = trackFormat.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("audio/")) {
                    audioTrackIndex = i
                    format = trackFormat
                    break
                }
            }
            if (audioTrackIndex == -1 || format == null) {
                android.util.Log.e("AudioConvert", "No audio track found in $inputPath")
                return false
            }

            extractor.selectTrack(audioTrackIndex)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: return false
            val sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            val channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

            android.util.Log.d("AudioConvert", "Input: mime=$mime, rate=$sampleRate, ch=$channels")

            // Create decoder
            val codec = MediaCodec.createDecoderByType(mime)
            codec.configure(format, null, null, 0)
            codec.start()

            val pcmData = mutableListOf<ByteArray>()
            val bufferInfo = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            var totalPcmBytes = 0

            var decodedRate = sampleRate
            var decodedChannels = channels

            while (!outputDone) {
                // Feed input
                if (!inputDone) {
                    val inputIndex = codec.dequeueInputBuffer(10000)
                    if (inputIndex >= 0) {
                        val inputBuffer = codec.getInputBuffer(inputIndex) ?: continue
                        val sampleSize = extractor.readSampleData(inputBuffer, 0)
                        if (sampleSize < 0) {
                            codec.queueInputBuffer(inputIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            val pts = extractor.sampleTime
                            codec.queueInputBuffer(inputIndex, 0, sampleSize, pts, 0)
                            extractor.advance()
                        }
                    }
                }

                // Drain output
                val outputIndex = codec.dequeueOutputBuffer(bufferInfo, 10000)
                if (outputIndex >= 0) {
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        outputDone = true
                    }
                    val outputBuffer = codec.getOutputBuffer(outputIndex) ?: continue
                    val chunk = ByteArray(bufferInfo.size)
                    outputBuffer.get(chunk)
                    if (chunk.isNotEmpty()) {
                        pcmData.add(chunk)
                        totalPcmBytes += chunk.size
                    }
                    codec.releaseOutputBuffer(outputIndex, false)
                }
            }

            // Read output format BEFORE releasing the codec
            try {
                val outFormat = codec.outputFormat
                decodedRate = outFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                decodedChannels = outFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            } catch (_: Exception) {
                // Fall back to input format values (already set above)
            }

            codec.stop()
            codec.release()
            extractor.release()

            if (totalPcmBytes == 0) {
                android.util.Log.e("AudioConvert", "No PCM data decoded")
                return false
            }

            // Resample to 16kHz mono if needed
            val targetRate = 16000
            val finalPcm = resampleToMono16k(pcmData, totalPcmBytes, decodedRate, decodedChannels, targetRate)

            // Write WAV file
            writeWavFile(outputPath, finalPcm, targetRate, 1, 16)

            android.util.Log.d("AudioConvert", "Converted to WAV: ${finalPcm.size} bytes, 16kHz mono")
            return true

        } catch (e: Exception) {
            android.util.Log.e("AudioConvert", "Conversion failed: ${e.message}", e)
            extractor.release()
            return false
        }
    }

    /// Resample PCM data to 16kHz mono 16-bit.
    private fun resampleToMono16k(
        pcmChunks: List<ByteArray>,
        totalBytes: Int,
        srcRate: Int,
        srcChannels: Int,
        targetRate: Int
    ): ByteArray {
        // Combine all chunks
        val allPcm = ByteArray(totalBytes)
        var offset = 0
        for (chunk in pcmChunks) {
            System.arraycopy(chunk, 0, allPcm, offset, chunk.size)
            offset += chunk.size
        }

        val srcBuffer = ByteBuffer.wrap(allPcm).order(ByteOrder.LITTLE_ENDIAN)
        val bytesPerSample = 2 // 16-bit
        val srcSamplesTotal = totalBytes / bytesPerSample
        val srcSamplesPerFrame = srcChannels
        val srcFrames = srcSamplesTotal / srcSamplesPerFrame

        // Convert to mono float samples
        val monoSamples = FloatArray(srcFrames)
        for (i in 0 until srcFrames) {
            var sum = 0f
            for (ch in 0 until srcChannels) {
                sum += srcBuffer.getShort().toFloat() / 32768f
            }
            monoSamples[i] = sum / srcChannels
        }

        // Resample using linear interpolation
        val ratio = srcRate.toDouble() / targetRate.toDouble()
        val outFrames = (srcFrames / ratio).toInt()
        val outBuffer = ByteBuffer.allocate(outFrames * 2).order(ByteOrder.LITTLE_ENDIAN)

        for (i in 0 until outFrames) {
            val srcPos = i * ratio
            val idx = srcPos.toInt()
            val frac = (srcPos - idx).toFloat()
            val s0 = monoSamples[idx.coerceAtMost(srcFrames - 1)]
            val s1 = monoSamples[(idx + 1).coerceAtMost(srcFrames - 1)]
            val sample = s0 + frac * (s1 - s0)
            val clamped = sample.coerceIn(-1f, 1f)
            outBuffer.putShort((clamped * 32767f).toInt().toShort())
        }

        return outBuffer.array()
    }

    /// Write PCM data as a WAV file with proper header.
    private fun writeWavFile(path: String, pcmData: ByteArray, sampleRate: Int, channels: Int, bitsPerSample: Int) {
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val blockAlign = channels * bitsPerSample / 8
        val dataSize = pcmData.size
        val fileSize = 36 + dataSize

        FileOutputStream(path).use { fos ->
            val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
            // RIFF header
            header.put("RIFF".toByteArray())
            header.putInt(fileSize)
            header.put("WAVE".toByteArray())
            // fmt chunk
            header.put("fmt ".toByteArray())
            header.putInt(16) // chunk size
            header.putShort(1) // PCM format
            header.putShort(channels.toShort())
            header.putInt(sampleRate)
            header.putInt(byteRate)
            header.putShort(blockAlign.toShort())
            header.putShort(bitsPerSample.toShort())
            // data chunk
            header.put("data".toByteArray())
            header.putInt(dataSize)

            fos.write(header.array())
            fos.write(pcmData)
        }
    }
}

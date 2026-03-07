package com.vaanix.app

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.vaanix.app/file_intent"
    private val AUDIO_CHANNEL = "com.vaanix.app/audio_focus"
    private var pendingFilePath: String? = null
    private var activeFocusRequest: AudioFocusRequest? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getOpenFilePath") {
                    result.success(pendingFilePath)
                    pendingFilePath = null
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
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

    private fun buildFocusRequest(): AudioFocusRequest {
        return AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )
            .setOnAudioFocusChangeListener { }
            .build()
    }

    /// Request transient exclusive audio focus before recording.
    /// Other media apps receive AUDIOFOCUS_LOSS_TRANSIENT and should auto-resume
    /// when we abandon focus later.
    private fun requestAudioFocus() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = buildFocusRequest()
            activeFocusRequest = request
            audioManager.requestAudioFocus(request)
        }
    }

    /// Abandon audio focus so other media apps can resume playback.
    private fun abandonAudioFocus() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = activeFocusRequest ?: buildFocusRequest()
            // If we didn't explicitly request, request first then abandon
            if (activeFocusRequest == null) {
                audioManager.requestAudioFocus(request)
            }
            audioManager.abandonAudioFocusRequest(request)
            activeFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }

    /// Simulate a media "play" button press to resume whatever media app was playing.
    /// This works for Spotify, YouTube Music, etc. because they listen for media key events.
    private fun resumeMedia() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val eventTime = SystemClock.uptimeMillis()
        val downEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PLAY, 0)
        val upEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PLAY, 0)
        audioManager.dispatchMediaKeyEvent(downEvent)
        audioManager.dispatchMediaKeyEvent(upEvent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data!!
            try {
                // Copy content:// URI to a temp file the app can read
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
}

# VoiceNotes AI — Product Concept Document

**Version:** 1.0
**Date:** February 2026
**Status:** Concept / Pre-Development

---

## 1. Executive Summary

VoiceNotes AI is a privacy-first, voice-driven note-taking and task management mobile application. Users capture thoughts, tasks, and ideas by voice. The app transcribes audio in real-time, automatically detects the spoken language, and intelligently structures the content into actions, todos, reminders, and general notes — all without requiring the user to type a single word.

**Core Principles:**

- **Privacy-first architecture** — All user data resides locally on-device using Hive database. No persistent data is shared with AI services. All AI interactions are stateless and transactional — audio is sent, processed, and the response is returned with zero memory retention on the AI side.
- **No ads, ever** — The app is funded through a fair freemium model. User attention is never the product.
- **Voice as the primary interface** — Every core feature is accessible through voice. The UI exists to display and organize what the voice captures.
- **Generous free tier** — All core features are available to every user. Only advanced power-user features require a subscription.

**Problem Statement:**

People have ideas, tasks, and thoughts throughout the day but capturing them by typing is disruptive and slow. Existing voice apps either lack intelligent organization, compromise privacy by storing data in the cloud, or lock basic features behind paywalls. VoiceNotes AI solves this by keeping data local, AI processing stateless, and core features free.

---

## 2. Target User

**MVP Target:** Solo personal use — individuals who want to capture and organize thoughts hands-free.

**User Personas:**

- **The Busy Professional** — Captures meeting takeaways, action items, and follow-ups while walking between meetings. Needs structured output without manual sorting.
- **The Multilingual Thinker** — Thinks and speaks in multiple languages throughout the day. Needs seamless language detection without switching settings.
- **The Privacy-Conscious User** — Wants the convenience of AI-powered transcription but refuses to let their personal notes live on someone else's server.
- **The On-the-Go Creator** — Captures ideas, inspiration, and creative fragments throughout the day. Needs them organized and searchable later.

---

## 3. Data Privacy Architecture

Privacy is not a feature — it is the foundation of the entire application.

### 3.1 Local-First Storage with Hive

- All voice recordings, transcriptions, structured notes, user preferences, and conversation groupings are stored locally on-device using **Hive** (lightweight, fast, no-SQL database for Flutter/Dart).
- No user data is uploaded to any cloud server by default.
- Hive boxes are encrypted at rest using AES-256 encryption with a key derived from the device.

### 3.2 Stateless AI Processing

- When a voice note is sent for transcription and structuring, the interaction is **purely transactional**:
  1. Audio is sent to the AI processing service.
  2. The service transcribes, detects language, and structures the content.
  3. The structured response is returned to the device.
  4. **No audio, text, or metadata is retained by the AI service after the response is delivered.**
- The AI has **zero memory** across requests. Each voice note is processed in complete isolation with no context from previous notes.
- API calls use encrypted transport (TLS 1.3) and include no user-identifying information beyond what is necessary for the transaction.

### 3.3 User Control

- Users can view exactly what data exists on their device at any time.
- Users can delete any or all data permanently with a single action.
- No analytics, tracking, or telemetry is collected without explicit opt-in.
- If cloud backup is introduced in later phases, it will be opt-in, end-to-end encrypted, and the encryption key will be held only by the user.

---

## 4. Phase 1 — MVP

**Goal:** Deliver a functional, privacy-first voice note app that captures, transcribes, and structures notes intelligently. No login required. All features free.

**Platform:** Cross-platform (iOS + Android) — built with Flutter.

**Design:** Warm and friendly UI inspired by Otter.ai — soft rounded corners, inviting color palette (warm whites, soft blues, gentle greens), clean typography, minimal visual clutter. The app should feel calm and effortless.

### 4.1 Screens

#### Home / Dashboard

- **Prominent floating "Record" button** — large mic icon, bottom center, always visible. This is the primary entry point to the app's core function.
- **Recent notes feed** — cards displayed in reverse chronological order, each showing:
  - Auto-generated title (derived from content)
  - Date and time of recording
  - Detected language tag (small pill/badge)
  - Category icons showing what was extracted (action, todo, reminder, note)
  - Brief preview of the transcription (first 2 lines)
- **Search bar** — top of screen, searches across all notes by keyword, language, category, or date.
- **Filter chips** — below search bar, quick filters for: All, Actions, Todos, Reminders, Notes.

#### Recording Screen

- Triggered by tapping the Record button.
- **Waveform visualizer** — real-time audio waveform showing input levels. Provides visual feedback that the app is listening.
- **Live transcription preview** — text appears below the waveform as the user speaks, updating in near real-time.
- **Pause / Resume button** — allows the user to pause recording without ending the session.
- **Cancel button** — discards the recording entirely.
- **"Save & Process" button** — ends recording and triggers AI processing (transcription finalization, language detection, structuring).
- **Recording timer** — shows elapsed time.

#### Note Detail Screen

- **Full transcription** — complete text with detected language labeled at the top.
- **Structured output sections** — clearly separated, each with its own visual treatment:
  - **Actions** — specific things to do, extracted from phrases like "I need to...", "let's make sure we...", "action item:..."
  - **Todos** — task items with optional due dates if mentioned ("by Friday", "before the meeting"). Each has a checkbox.
  - **Reminders** — time-based items extracted from phrases like "remind me to...", "don't forget...", "remember to...". Shows scheduled time if mentioned.
  - **General Notes** — anything that doesn't fit the above, preserved as formatted text.
- **AI Follow-up Questions** — displayed only when the user includes a voice trigger like "any suggestions?", "what should I consider?", "what am I missing?", or "follow up on this." The AI generates 2-3 contextually relevant questions. Example: if the user mentions a product launch, the AI might suggest "Have you considered a rollback plan?" or "Would you like to set milestone dates?"
- **Edit capability** — user can manually edit the transcription or any structured item.
- **Audio playback** — original recording can be replayed from this screen.
- **Delete note** — with confirmation prompt.

#### Conversations / Folders View

- **Auto-grouped conversations** — the AI groups notes that reference the same topic, project, person, or theme into conversations. For example, all notes mentioning "kitchen renovation" are grouped together.
- **Manual folders/tags** — users can create their own organizational folders and tag notes.
- **Auto-filing** — when a new voice note references a topic that matches an existing conversation, it is automatically added to that conversation.
- **Conversation timeline** — within each conversation, notes are displayed chronologically, showing how a topic evolved over time.

#### Settings Screen

- **Language preferences** — set a default language or keep auto-detect enabled.
- **Audio quality** — choose between standard and high quality recording (affects storage).
- **Notification settings** — enable/disable reminder notifications, set quiet hours.
- **Storage management** — view storage used, clear old recordings (keep transcriptions), export data.
- **Privacy dashboard** — view what data exists, delete all data, view AI processing policy.
- **About / Help** — app version, FAQ, support contact.

### 4.2 Key Behaviors

| Behavior | Details |
|---|---|
| Auto language detection | Detects spoken language without user selection. Supports: English, Spanish, French, German, Italian, Portuguese, Arabic, Hindi, Mandarin, Japanese, Korean, Russian, Turkish, Dutch, Polish, and more. Mixed-language notes are handled by transcribing each segment in its spoken language. |
| Smart categorization | AI parses natural language cues to automatically tag content as actions, todos, reminders, or general notes. No manual sorting required. |
| Contextual grouping | AI compares new note content against existing notes and auto-links related topics into conversations. |
| Follow-up intelligence | Only activated by voice trigger. AI generates relevant follow-up questions based on the note content. |
| Offline recording | Recording works without internet. Transcription and AI processing happen when connectivity is restored. A queue indicator shows pending items. |
| Local-only storage | All data stored in Hive on-device. No cloud sync in MVP. |
| No login required | App is fully functional without any account creation or sign-in. |

### 4.3 MVP Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (cross-platform iOS + Android) |
| Local database | Hive (encrypted) |
| Audio recording | flutter_sound / record package |
| Speech-to-text | Google Speech-to-Text API or Whisper API (stateless, transactional calls only) |
| AI structuring | OpenAI API or Anthropic API (stateless, no memory, no data retention) |
| State management | Riverpod or Bloc |
| Notifications | flutter_local_notifications (for reminders) |

---

## 5. Phase 2 — Enhanced Intelligence & Connectivity

**Goal:** Introduce user accounts for optional cloud backup, connect to n8n for advanced AI processing, enable WiFi microphone support, and add multi-user voice detection.

**Timeline:** After MVP validation (target: 3-6 months post-MVP launch).

### 5.1 User Accounts (Optional)

- **Optional sign-up** — the app continues to work fully without an account. Accounts unlock cloud backup and cross-device sync.
- **Authentication** — email/password + OAuth (Google, Apple).
- **End-to-end encrypted cloud backup** — user holds the encryption key. Server stores only encrypted blobs. Even the service provider cannot read user data.
- **Cross-device sync** — notes sync across devices via encrypted cloud, with conflict resolution for offline edits.

### 5.2 n8n AI Agent Integration

- **Webhook-based architecture** — the app sends voice audio to an n8n webhook endpoint.
- **n8n workflow processes the audio through a configurable AI pipeline:**
  1. Receive audio → transcribe (Whisper node)
  2. Detect language (AI classification node)
  3. Structure content into actions/todos/reminders (LLM node with custom prompt)
  4. Generate follow-up questions if triggered (LLM node)
  5. Return structured JSON response to the app
- **All n8n processing remains stateless** — no conversation memory, no data persistence in n8n. Each webhook call is independent.
- **Self-hostable** — users who want maximum privacy can self-host their own n8n instance and point the app to it.
- **Custom workflow support** — power users can modify the n8n flow to add their own processing steps (e.g., send action items to Todoist, log notes to Notion).

### 5.3 WiFi Microphone Integration

- **Network discovery** — the app discovers WiFi-enabled microphones on the local network via mDNS/Bonjour or SSDP.
- **Supported protocols** — MQTT, WebSocket, or HTTP streaming for real-time audio input.
- **Use cases:**
  - Record from a conference room mic while the phone stays in your pocket.
  - Use a kitchen smart speaker as input while cooking.
  - Capture from a car's Bluetooth/WiFi mic during a drive.
- **Pairing flow** — simple one-time pairing with QR code or network PIN.
- **Audio routing indicator** — the app clearly shows which microphone is currently active (built-in vs. external).

### 5.4 Multi-User Voice Detection

- **Speaker diarization** — the AI distinguishes between different speakers in a recording and labels them (Speaker 1, Speaker 2, etc.).
- **Speaker profiles** — over time, the system can learn recognized voices and assign names (stored locally only).
- **Attributed notes** — structured output (actions, todos) is attributed to the speaker who said it. Example: "Speaker 1 (Haridas): will send the proposal by Friday" becomes an action item assigned to Speaker 1.
- **Meeting mode** — a dedicated recording mode optimized for multi-speaker capture, with a post-recording summary that includes per-speaker action items.
- **Privacy safeguard** — speaker profiles and voice signatures are stored only in local Hive storage. They are never sent to AI services. Diarization happens on-device or via stateless API call.

### 5.5 Additional Phase 2 Features

- **Sentiment & urgency tagging** — AI flags notes by emotional tone (positive, neutral, concerned, urgent) and urgency level. High-urgency items are surfaced prominently.
- **Auto-linking related notes** — AI creates threads between notes that reference the same topic across different days or weeks.
- **Voice search** — "What did I say about the pricing model last week?" — user queries their note history by voice and gets results.
- **Quick capture widget** — home screen widget (Android) / lock screen widget (iOS) for instant recording without opening the app.
- **Export options** — export notes as Markdown, PDF, or plain text.

---

## 6. Phase 3 — Advanced Features & Ecosystem

**Goal:** Expand into music note capture, intelligent automations, third-party integrations, and collaborative features for power users.

**Timeline:** 6-12 months post-Phase 2.

### 6.1 Music Note Capture

- **Audio classification** — the app detects whether input is speech or music and routes accordingly.
- **Music transcription** — captures melodies, chord progressions, and rhythmic patterns from hummed, sung, or played input.
- **Output formats** — generates basic sheet music notation, MIDI representation, or chord chart.
- **Use case** — a musician hums a melody idea while walking. The app captures it, transcribes it to notation, and stores it in a "Music Ideas" conversation.
- **Tagging** — music notes can be tagged with key, tempo (if detectable), mood, and instrument.

### 6.2 Smart Automations (Power User — Subscription)

- **Voice-triggered workflows** — "Send the proposal to Sarah" triggers an n8n workflow that finds the latest document tagged "proposal" and emails it.
- **Scheduled digests** — daily or weekly AI-generated summary of all notes, open action items, pending decisions, and upcoming reminders. Delivered as a notification or in-app report.
- **Auto-routing to external tools** — action items can be auto-pushed to task managers (Todoist, Asana, Trello), calendar events to Google Calendar / Apple Calendar, and notes to knowledge bases (Notion, Obsidian).
- **Decision log** — when the AI detects a decision was made ("we decided to go with option B"), it extracts and logs it separately from action items.
- **Conflict detection** — in multi-speaker mode, if Speaker 1 says "deadline is Monday" and Speaker 2 says "we need until Wednesday," the AI flags the discrepancy.

### 6.3 Ambient Listening Mode (Power User — Subscription)

- **Continuous capture** — for workshops, brainstorming sessions, or long calls. The app records continuously and the AI processes audio in chunks.
- **Key point extraction** — instead of full transcription, the AI extracts only the key decisions, action items, and important statements.
- **Consent mechanism** — ambient mode requires explicit activation and shows a persistent notification to all participants that recording is active.
- **Battery optimization** — intelligent audio processing to minimize battery drain during long sessions.

### 6.4 Collaborative Features (Power User — Subscription)

- **Shared conversations** — invite others to a conversation thread. Shared notes are end-to-end encrypted in transit.
- **Collaborative annotations** — multiple users can add voice replies or text comments to an existing note thread asynchronously.
- **Team action boards** — shared view of action items across team members, with status tracking.
- **Role-based routing** — in multi-speaker recordings, notes attributed to different speakers can be routed to their respective task boards.

### 6.5 Additional Phase 3 Features

- **Voice annotations on documents** — open a PDF or image in the app, speak a note, and it gets pinned to that document contextually.
- **Template-based capture** — "Client call template" triggers a guided capture flow: client name, topics discussed, next steps, follow-up date.
- **Contextual recall** — "What did I say about the budget last month?" — AI searches note history and provides a synthesized spoken or text answer.
- **Privacy zones / redaction** — AI auto-detects and redacts sensitive information (credit card numbers, health details) from transcriptions. Users can also say "off the record" to pause capture.
- **Handoff to third-party tools** — structured output pushed to CRMs (HubSpot, Salesforce), project management (Jira, Linear), or accounting software.
- **Localized UI** — app interface translated into all supported transcription languages.

---

## 7. Monetization Model

**Philosophy:** No ads. Ever. Core functionality is free for everyone. Revenue comes from power users who need advanced features.

### 7.1 Free Tier (All Core Features)

Available to every user, no account required:

- Unlimited voice note recording
- AI transcription with auto language detection
- Smart categorization (actions, todos, reminders, notes)
- AI follow-up questions
- Contextual conversation grouping
- Full search and filtering
- Offline recording with sync-on-connect
- Local Hive storage with encryption
- Sentiment and urgency tagging
- Voice search
- Export (Markdown, plain text)
- Multi-user voice detection (basic — Speaker 1, Speaker 2 labels)
- WiFi microphone support

### 7.2 Pro Tier (Subscription — Power Users)

Monthly or annual subscription:

- **Smart automations** — voice-triggered workflows, scheduled digests, auto-routing to external tools
- **Ambient listening mode** — continuous capture with key point extraction
- **Collaborative features** — shared conversations, team action boards, collaborative annotations
- **Music note capture** — melody transcription, chord charts, MIDI export
- **Advanced multi-user** — named speaker profiles, per-speaker action routing, conflict detection
- **Cloud backup** — end-to-end encrypted, cross-device sync
- **Template-based capture** — custom guided capture flows
- **Priority AI processing** — faster transcription and structuring
- **PDF export** — formatted, professional note exports
- **Voice annotations on documents**

### 7.3 Pricing Strategy (Suggested)

| Plan | Price | Billing |
|---|---|---|
| Free | $0 | Forever |
| Pro Monthly | $7.99/month | Monthly |
| Pro Annual | $59.99/year | Annual (save ~37%) |

### 7.4 Revenue Principles

- Free users are never degraded or nagged into upgrading.
- Pro features are genuinely advanced — not artificial limitations on basic functionality.
- No data monetization. User data is never sold, analyzed for advertising, or shared with third parties.
- No ads. The app's revenue model is sustainable through subscriptions alone.

---

## 8. Tech Stack Overview (Full)

| Component | MVP (Phase 1) | Phase 2+ |
|---|---|---|
| Frontend framework | Flutter | Flutter |
| Local database | Hive (encrypted) | Hive + optional encrypted cloud sync |
| Audio recording | flutter_sound / record | flutter_sound + WiFi mic streaming (MQTT/WebSocket) |
| Speech-to-text | Whisper API (stateless) | Whisper via n8n or on-device (Whisper.cpp) |
| AI structuring | OpenAI/Anthropic API (stateless) | n8n AI agent pipeline (self-hostable) |
| Speaker diarization | — | pyannote.audio or on-device model |
| Music transcription | — | Basic Pitch (Spotify) or custom model |
| State management | Riverpod or Bloc | Riverpod or Bloc |
| Authentication | None | Firebase Auth or Supabase Auth |
| Cloud storage | None | Supabase Storage or S3 (E2E encrypted) |
| Notifications | flutter_local_notifications | flutter_local_notifications + FCM |
| CI/CD | — | Codemagic or GitHub Actions |

---

## 9. Success Metrics

### Phase 1 (MVP)

- App installs and 7-day retention rate
- Average notes per user per week
- Transcription accuracy rate across languages
- Categorization accuracy (actions/todos/reminders correctly identified)
- App Store / Play Store rating (target: 4.5+)
- Crash-free session rate (target: 99.5%+)

### Phase 2

- Account creation rate (opt-in)
- WiFi microphone pairing success rate
- Multi-speaker detection accuracy
- n8n integration adoption among technical users
- Cloud backup opt-in rate

### Phase 3

- Pro subscription conversion rate (target: 3-5% of active users)
- Monthly recurring revenue (MRR)
- Feature usage distribution across Pro features
- Churn rate (target: < 5% monthly)
- Net Promoter Score (target: 50+)

---

## 10. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| **Transcription accuracy in noisy environments** | Poor user experience, wrong categorization | Offer audio quality indicator during recording; allow manual editing of transcriptions; improve with noise suppression preprocessing |
| **Language detection errors on short phrases** | Wrong language tag, garbled transcription | Allow user to set a preferred/default language; flag low-confidence detections for review |
| **AI categorization mistakes** | Todos tagged as notes, missed reminders | Allow easy manual re-categorization; improve prompt engineering; collect anonymized accuracy feedback (opt-in) |
| **Hive database corruption** | Data loss | Implement automatic local backups; offer manual export; validate Hive box integrity on app start |
| **Privacy perception** | Users may not trust "stateless AI" claims | Publish transparent privacy policy; allow users to audit API calls; offer self-hosted n8n option in Phase 2 |
| **Battery drain from recording** | Poor experience on long recordings | Optimize audio processing; show battery usage estimate; auto-pause after configurable idle time |
| **API costs for AI processing** | Unsustainable free tier | Monitor per-user API costs; implement rate limiting if needed; explore on-device models (Whisper.cpp) to reduce cloud dependency |
| **WiFi microphone compatibility** | Fragmented device landscape | Start with popular protocols (MQTT, WebSocket); maintain a tested device list; provide clear pairing troubleshooting |

---

## 11. Development Roadmap Summary

```
Phase 1 — MVP (Months 1-3)
├── Core voice recording + transcription
├── Auto language detection
├── Smart categorization (actions, todos, reminders, notes)
├── AI follow-up questions (voice-triggered)
├── Conversation auto-grouping
├── Local Hive storage (encrypted, no login)
├── Offline recording with process-on-connect
├── Search and filtering
└── Warm, friendly UI (Otter.ai-inspired)

Phase 2 — Enhanced Intelligence (Months 4-9)
├── Optional user accounts + E2E encrypted cloud backup
├── n8n AI agent integration (self-hostable)
├── WiFi microphone support
├── Multi-user voice detection (speaker diarization)
├── Sentiment & urgency tagging
├── Voice search across note history
├── Auto-linking related notes
├── Quick capture widget
└── Export (Markdown, PDF, plain text)

Phase 3 — Advanced & Ecosystem (Months 10-18)
├── Music note capture + transcription
├── Smart automations (voice-triggered workflows)
├── Ambient listening mode
├── Collaborative features (shared conversations, team boards)
├── Template-based capture
├── Third-party integrations (CRM, project management, calendar)
├── Voice annotations on documents
├── Contextual recall
├── Privacy zones / auto-redaction
└── Pro subscription launch
```

---

## 12. Appendix: Privacy Commitment

VoiceNotes AI is built on the belief that personal thoughts deserve personal protection.

- **Your data stays on your device.** Hive database, encrypted, under your control.
- **AI doesn't remember you.** Every AI interaction is stateless. No memory. No profile. No history.
- **No ads. No tracking. No telemetry.** Unless you explicitly opt in to anonymized crash reporting.
- **You can delete everything.** One tap. Permanent. No hidden copies.
- **Cloud is optional and encrypted.** If you choose cloud backup, you hold the key. We cannot read your notes.
- **Self-host if you want.** In Phase 2, point the app at your own n8n instance for complete control over AI processing.

This isn't just a feature. It's a promise.

---

*End of Concept Document*

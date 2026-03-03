# VoiceNotes AI — Smoke Test Procedure

**Purpose:** Quick manual validation of all core features before a release.
**Estimated time:** 15–20 minutes
**Device:** Android phone with microphone access

---

## Pre-Test Setup

- [ ] Fresh install (or clear app data) for a clean start
- [ ] Grant microphone permission when prompted
- [ ] Ensure phone is not on silent/mute (for sound cue test)

---

## 1. First Launch & Onboarding (2 min)

- [ ] Splash screen shows with logo + "by HDMPixels"
- [ ] Quick Guide (5 pages) appears — swipe through all pages
- [ ] Tap "Get Started" → lands on Home screen
- [ ] Guided recording banner visible ("Tap the mic and say what's on your mind")

---

## 2. Whisper Recording (3 min)

- [ ] Tap the mic FAB → Recording screen opens
- [ ] Recording starts — red dot pulses, timer counts up
- [ ] Speak clearly for 10+ seconds
- [ ] Tap Save → "Saving..." overlay appears briefly → returns to Home
- [ ] New note appears in feed with auto-generated title (not "No speech detected")
- [ ] Tap the note → Note Detail shows transcribed text + audio player
- [ ] Play audio back — audio is audible and matches what you said

---

## 3. Live Transcription Mode (2 min)

- [ ] Go to Settings → Audio & Recording → Transcription Mode → select "Live"
- [ ] Tap mic FAB → Recording screen shows "Instant text as you speak"
- [ ] Speak — live text appears on screen as you talk
- [ ] Tap Save → Note created with transcription (no audio playback for Live mode)

---

## 4. Folders & Tags (2 min)

- [ ] Go to Library → Tap speed dial → "New Folder"
- [ ] Enter name, pick a color → Create
- [ ] Folder appears with chosen color icon
- [ ] Open a note → scroll to Tags section → tap "+ Add tag" → type a tag → Add
- [ ] Tag pill appears on the note
- [ ] Go back to Home — tag chip shows on the note card
- [ ] Go to Library → "Tags" row visible → tap "Manage" → tags page lists your tag

---

## 5. Tasks & Reminders (2 min)

- [ ] Open any note → scroll to Action Items → tap "Add Action" → type text → Save
- [ ] Tap the checkbox — haptic feedback + bounce animation + green highlight
- [ ] Add a Todo with a due date (set to yesterday to test overdue)
- [ ] Go back to Home → note card shows red "overdue" badge
- [ ] Switch to Tasks tab → your tasks appear in the aggregated list

---

## 6. Projects Inside Folders (1 min)

- [ ] Open a folder → tap overflow menu (⋮) → "New Project"
- [ ] Enter title → Create → project card appears below notes
- [ ] Tap the project card → Project Document detail opens

---

## 7. Search (1 min)

- [ ] Tap search icon → type a keyword from a note
- [ ] Results appear with note matches
- [ ] Tag filter chips visible — tap one to filter by tag
- [ ] Folder filter chips visible — tap one to filter by folder

---

## 8. Pin & Sort (30 sec)

- [ ] On Home, long-press a note → selection mode activates
- [ ] Exit selection → open note → overflow menu → "Pin"
- [ ] Pinned note floats to top of feed with pin icon

---

## 9. Backup & Restore (1 min)

- [ ] Home overflow menu → "Backup & Restore"
- [ ] Enter a passphrase → tap "Create Backup"
- [ ] Backup completes → share sheet appears (dismiss it)
- [ ] Backup reminder banner should NOT show (backup just created)

---

## 10. App Lock (1 min)

- [ ] Settings → Security → Set up PIN (4+ digits)
- [ ] Confirm PIN → App Lock enabled
- [ ] Kill the app → reopen → Lock screen appears
- [ ] Enter PIN → unlocks to Home
- [ ] Settings → Security → disable App Lock

---

## 11. Settings & Theme (30 sec)

- [ ] Settings → Preferences → Appearance → switch to "Dark" → UI goes dark
- [ ] Switch to "AMOLED Dark" → true black background
- [ ] Switch back to "System"
- [ ] Verify "Anonymous Crash Reports" toggle exists (default off)

---

## 12. Trash & Delete (30 sec)

- [ ] Delete a note (long-press → select → delete, or from Note Detail overflow)
- [ ] Home overflow → "Trash" → deleted note appears
- [ ] Tap "Restore" → note reappears in feed

---

## 13. Share & Export (30 sec)

- [ ] Open a note → tap share icon → Share Preview sheet appears
- [ ] Toggle options (Include Title, Plain Text Only) → tap Share
- [ ] Android share sheet opens with note text

---

## Post-Test Checklist

- [ ] No crashes during entire flow
- [ ] No "No speech detected" when audio was spoken (Whisper mode)
- [ ] Audio playback works on saved Whisper notes
- [ ] All navigation (back buttons, go_router) works without dead ends
- [ ] Theme changes apply across all screens

---

**If any test fails**, note the step number and exact behavior, then file a bug.

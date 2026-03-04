# Vaanix — Feature Spec: Gesture FAB (Home Page)

**Version:** 1.0  
**Date:** 2026-03-04  
**Status:** Ready for Development  
**Phase:** Phase 1  
**Scope:** Home Page only  
**Reference:** [Project Specification](PROJECT_SPECIFICATION.md) | [Implementation Plan](IMPLEMENTATION_PLAN.md)

---

## 1. Overview

The current Home page SpeedDial FAB requires the user to tap the FAB, wait for the dial to expand, and then tap "Record Note" — three interactions before recording begins. Since recording is the primary action in Vaanix (estimated 60–70% of all FAB interactions), this creates unnecessary friction.

This feature redesigns the Home page FAB into a **Gesture FAB**: a single button that supports two distinct gestures with two distinct outcomes:

| Gesture | Action |
|---|---|
| **Swipe Up** | Navigate directly to Record screen (fastest path) |
| **Tap** | Expand SpeedDial to choose from all available actions |

This keeps the UI to a single FAB, preserves full SpeedDial functionality, and makes the most common action (record) a 1-gesture interaction.

---

## 2. Goals

- Reduce time-to-record to a single gesture from the Home page
- Preserve access to all existing SpeedDial actions (New Folder, New Text Note)
- Maintain a clean, single-FAB UI — no additional buttons on screen
- Make the swipe gesture discoverable without intrusive tutorials
- Work consistently on both Android and iOS

---

## 3. Current State

The existing Home SpeedDial FAB (`SpeedDialFab` widget) has:

| Position | Action |
|---|---|
| Main button (tap) | Expands dial |
| Item 1 (top) | New Text Note → opens template picker sheet |
| Item 2 (middle) | New Folder → opens new folder dialog |
| Item 3 (bottom) | Record Note → navigates to recording screen |

**Problems:**
- Record is the last item (bottom of the expanded dial) — furthest from the main button
- Minimum 2 taps required to record
- No gesture shortcut exists

---

## 4. Proposed Behaviour

### 4.1 Swipe Up → Record

- User places finger on FAB and swipes upward (minimum drag distance: **40px**)
- App navigates **directly to the Recording screen** — no intermediate step
- Recording screen launches immediately, ready to record
- SpeedDial does **not** expand during this gesture
- Works from both the Notes tab and the Tasks tab

**Gesture threshold:**
- Minimum vertical drag: `40px`
- Maximum horizontal drift allowed: `20px` (to avoid conflict with horizontal scroll gestures on note cards)
- Drag must be predominantly upward (dy < 0, |dy| > |dx|)

### 4.2 Tap → SpeedDial Expands

- Standard tap on FAB opens the SpeedDial as it does today
- SpeedDial items remain the same: **New Text Note**, **New Folder**, **Record Note**
- Record Note remains in the SpeedDial as a fallback for discoverability
- Tapping outside the expanded dial collapses it (existing behaviour)

### 4.3 Visual Feedback During Swipe

When the user begins dragging upward on the FAB:

1. **Drag start (0–20px):** No visual change — avoids false triggers from imprecise taps
2. **Drag progress (20–40px):** FAB icon transitions from `+` / `⊕` to `🎙️` mic icon with a subtle crossfade animation
3. **Threshold reached (40px+):** FAB pulses once (scale: 1.0 → 1.15 → 1.0, duration: 150ms) and navigation is triggered
4. **Drag cancelled (released before 40px):** FAB returns to default state, no action taken

### 4.4 Haptic Feedback

| Event | Haptic |
|---|---|
| Drag threshold reached (40px) | `HapticService.medium()` |
| Navigation triggered | `HapticService.light()` |
| Drag cancelled | None |

Uses the existing `HapticService` utility.

---

## 5. Discoverability

The swipe gesture is not self-evident. Three mechanisms ensure users discover it:

### 5.1 Onboarding Hint (First Launch)

Integrate with the existing **Guided First Recording Experience** overlay (Wave 2, Step 12.7):

- After the overlay highlights the FAB with "Tap the mic to record", add a secondary hint line:
  > *"Or swipe up on this button to record instantly."*
- Show an animated upward arrow on the FAB during this hint
- Hint shown once only; dismissed after user interacts with FAB

### 5.2 Animated Idle Hint (Repeat Hint)

If the user has never used the swipe gesture after **5 app sessions**:
- On the 6th session, the FAB plays a subtle idle animation: a small upward arrow fades in above the FAB icon for 2 seconds, then fades out
- Shown maximum **2 times** across the app lifetime
- Controlled by `UserSettings.fabSwipeHintShownCount` (int, max 2)

### 5.3 FAB Subtitle Label

When the SpeedDial is closed (default state), display a small text label just above the FAB:

```
↑ swipe to record
  [ 🎙️ ]
```

- Label: `"↑ swipe to record"` in 10sp, `Colors.white54`, no background
- Shown only for the **first 10 sessions** (`UserSettings.sessionCount <= 10`)
- Hidden permanently after 10 sessions to keep the UI clean for returning users
- Does not appear while SpeedDial is expanded

---

## 6. Flutter Implementation

### 6.1 Widget: `GestureFab`

Replace the current `SpeedDialFab` widget on the Home page with a new `GestureFab` widget that wraps the existing speed dial logic.

```dart
// lib/widgets/gesture_fab.dart

class GestureFab extends StatefulWidget {
  final VoidCallback onRecord;          // Navigate to recording screen
  final VoidCallback onNewTextNote;     // Open template picker
  final VoidCallback onNewFolder;       // Open new folder dialog

  const GestureFab({
    required this.onRecord,
    required this.onNewTextNote,
    required this.onNewFolder,
    super.key,
  });
}
```

### 6.2 Gesture Detection

Use `GestureDetector` wrapping the FAB:

```dart
GestureDetector(
  onVerticalDragUpdate: _handleDragUpdate,
  onVerticalDragEnd: _handleDragEnd,
  onVerticalDragCancel: _handleDragCancel,
  onTap: _handleTap,
  child: _buildFab(),
)
```

**Key logic:**

```dart
static const double _swipeThreshold = 40.0;
static const double _maxHorizontalDrift = 20.0;

double _dragDistance = 0.0;
bool _thresholdReached = false;

void _handleDragUpdate(DragUpdateDetails details) {
  // Only track upward drags
  if (details.delta.dy >= 0) return;

  // Reject if horizontal drift is too large
  if (details.delta.dx.abs() > _maxHorizontalDrift) return;

  _dragDistance += details.delta.dy.abs();

  if (!_thresholdReached && _dragDistance >= _swipeThreshold) {
    _thresholdReached = true;
    HapticService.medium();
    _triggerRecordAnimation();
  }
}

void _handleDragEnd(DragEndDetails details) {
  if (_thresholdReached) {
    widget.onRecord();
  }
  _resetDragState();
}

void _handleDragCancel() {
  _resetDragState();
}

void _resetDragState() {
  _dragDistance = 0.0;
  _thresholdReached = false;
  // Animate FAB icon back to default if mid-transition
}
```

### 6.3 Icon Transition Animation

```dart
// AnimatedSwitcher to crossfade between + and mic icons
AnimatedSwitcher(
  duration: const Duration(milliseconds: 150),
  child: _thresholdReached
      ? const Icon(Icons.mic, key: ValueKey('mic'))
      : const Icon(Icons.add, key: ValueKey('add')),
)
```

### 6.4 FAB Pulse on Threshold

```dart
void _triggerRecordAnimation() {
  _animationController.forward().then((_) {
    _animationController.reverse();
  });
}

// In build:
ScaleTransition(
  scale: Tween(begin: 1.0, end: 1.15).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ),
  ),
  child: _fabChild,
)
```

### 6.5 Subtitle Label

```dart
// Show label above FAB for first 10 sessions
if (sessionCount <= 10 && !_isDialOpen)
  Positioned(
    bottom: 80, // above FAB
    right: 16,
    child: AnimatedOpacity(
      opacity: _isDialOpen ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Text(
        '↑ swipe to record',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white54,
        ),
      ),
    ),
  ),
```

### 6.6 UserSettings Fields (New)

Add to `UserSettings` Hive model:

```dart
@HiveField(X) int fabSwipeHintShownCount; // default: 0, max: 2
@HiveField(X) int sessionCount;           // increment on each app launch
```

---

## 7. SpeedDial Items (Unchanged)

The SpeedDial that opens on tap retains all existing items. No changes to the dial actions, ordering, or behaviour:

| Item | Action | Icon |
|---|---|---|
| New Text Note | Open template picker sheet | `description` |
| New Folder | Open new folder dialog | `folder` |
| Record Note | Navigate to recording screen | `mic` |

> **Note:** "Record Note" is intentionally kept in the SpeedDial even though swipe-up also records. It acts as a visible fallback for users who have not discovered the gesture, and maintains consistency for users who prefer tap-based navigation.

---

## 8. Edge Cases

| Scenario | Handling |
|---|---|
| User swipes up while SpeedDial is already open | Collapse the dial first, do not navigate to record |
| Very fast swipe (fling) | Treat as swipe-up if predominantly vertical; same threshold applies |
| User swipes up during multi-select mode | Ignore gesture; FAB is hidden during multi-select |
| Low-end device with slow animation | Animation is skipped if `MediaQuery.disableAnimations` is true; navigation still fires |
| Accessibility (TalkBack / VoiceOver) | FAB labelled "Record voice note. Double-tap to open actions menu." Swipe gesture not available in accessibility mode — tap opens SpeedDial with all options |

---

## 9. Accessibility

- **Semantic label:** `"Record voice note. Double-tap to open more options."`
- In TalkBack/VoiceOver mode: gesture is disabled; single tap opens SpeedDial instead
- All SpeedDial items retain their existing semantic labels
- Subtitle label (`"↑ swipe to record"`) has `excludeFromSemantics: true` — not read aloud

---

## 10. Files Affected

| File | Change |
|---|---|
| `lib/widgets/gesture_fab.dart` | **New file** — GestureFab widget |
| `lib/pages/home_page.dart` | Replace `SpeedDialFab` with `GestureFab` |
| `lib/models/user_settings.dart` | Add `fabSwipeHintShownCount`, `sessionCount` fields |
| `lib/services/haptic_service.dart` | No change — existing service used as-is |

---

## 11. Effort Estimate

| Task | Estimate |
|---|---|
| `GestureFab` widget + gesture detection | 2 days |
| Icon transition + pulse animation | 1 day |
| Subtitle label + session count logic | 0.5 days |
| Onboarding overlay integration | 0.5 days |
| Idle hint animation (6th session) | 0.5 days |
| Accessibility handling | 0.5 days |
| Testing (Android + iOS) | 1 day |
| **Total** | **~6 days** |

---

## 12. Success Criteria

- Swipe-up gesture navigates to recording screen in < 300ms from gesture completion
- Gesture does not false-trigger during normal vertical scrolling of the notes feed
- Existing SpeedDial tap behaviour unchanged
- Subtitle label disappears after session 10
- Idle hint shown no more than twice across app lifetime
- No regressions on existing FAB actions (New Text Note, New Folder, Record Note via dial)

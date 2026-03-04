# Vaanix — Feature Spec: Home Screen Widget

**Version:** 1.0
**Date:** 2026-03-04
**Status:** Ready for Implementation
**Phase:** Phase 1 (Pre-Play Store Release)
**App Name:** Vaanix (package: `com.vaanix.app` — update if different)
**Stack:** Flutter · Riverpod · Hive · `home_widget` package
**Reference:** `FEATURE_PHASE1_VALUE_GAPS.md` § Feature 4 · `IMPLEMENTATION_PLAN.md`

---

## 1. Overview

The Vaanix home screen widget gives users one-tap access to start recording directly from their Android (and iOS) home screen, eliminating the friction of opening the app, waiting for splash, and navigating to the record screen. A secondary dashboard variant also surfaces note count, open task count, and a latest note preview at a glance.

**Design principle:** The widget is the user's utility space, not a branding surface. No app name appears in the widget. Identity is communicated by a small app icon badge only. All remaining space is given to the action and data.

---

## 2. Widget Variants

### Variant A — Quick Record (2×1, small)

**Purpose:** Single-tap recording. Minimum footprint.

```
┌─────────────────────────────────────────┐
│ [🎙 icon badge]          [● REC pill]   │
│              [mic illustration]          │
└─────────────────────────────────────────┘
```

- Full widget tap → launches app directly into Recording Screen
- Contains no text content, no note data → **unaffected by App Lock or Widget Privacy setting**
- Identity: small mic icon badge, top-left corner

### Variant B — Dashboard (4×2, medium)

**Purpose:** Glanceable stats + record action.

```
┌──────────────────────────────────────────────────────────┐
│ [🎙 icon badge]                          [● REC] →──────►│
│                    [mic + sound waves]                    │
│  42          7                                            │
│  Notes    Open Tasks  │  Kitchen renovation ideas...      │
│                       │  Today · 2:30 PM                  │
└──────────────────────────────────────────────────────────┘
```

- REC pill → launches Recording Screen
- Note count (tappable → opens Notes tab)
- Open task count (tappable → opens Tasks tab)
- Latest note preview (tappable → opens Note Detail)
- Refreshes every 30 minutes via WorkManager (Android) / WidgetKit timeline (iOS)

---

## 3. User Stories

1. **As a user**, I want to start recording a voice note from my home screen without opening the app first.
2. **As a user**, I want to see how many notes and open tasks I have at a glance.
3. **As a user**, I want to tap my latest note preview to open it directly.
4. **As a user with App Lock enabled**, I want to control what the widget shows so my note content stays private on my home screen.
5. **As a user with App Lock enabled**, I still want to record quickly from the widget without unlocking the app first (recording is a write operation — it adds new data, it doesn't expose existing data).

---

## 4. Design Specification

### 4.1 Visual Style

Matches the Vaanix app illustration style:

| Element | Dark variant | Light variant |
|---|---|---|
| Background | Navy gradient `#16264A` → `#243C64` | Light blue gradient `#E4ECFC` → `#D0DCEC` |
| Mic body | White rounded rectangle with navy dot grille | Same |
| Mic stand / base | Gold `#C38C23` | Gold `#AC7312` |
| Glow circle | Gold ring `rgba(195,140,35,0.24)` | Same |
| Sound waves (B only) | Gold sinusoidal `rgba(195,140,35,0.50)` | Same |
| Sparkles | White + gold 4-point stars | Same |
| REC pill | White fill, navy `● REC` text | Same |
| App icon badge | Frosted navy square, white mic silhouette | Frosted navy, white mic |
| Stats numbers | Gold (notes), white (tasks) — dark | Gold (notes), navy (tasks) — light |
| Subtext | `rgba(205,215,232)` | `rgba(72,98,145)` |

### 4.2 Sizing — Android

Design at **xxxhdpi** (4×), let Android density system pick the right file.

| Density | Scale | Variant A (px) | Variant B (px) |
|---|---|---|---|
| mdpi | 1× | 110 × 40 | 220 × 90 |
| hdpi | 1.5× | 165 × 60 | 330 × 135 |
| xhdpi | 2× | 220 × 80 | 440 × 180 |
| xxhdpi | 3× | 330 × 120 | 660 × 270 |
| **xxxhdpi** | **4×** | **440 × 160** | **880 × 360** |

Android widget grid cell ≈ **74dp wide × 30dp tall**. Usable area:
- Variant A (2×1): ~148 × 74dp (8dp inner padding applied)
- Variant B (4×2): ~296 × 148dp (8dp inner padding applied)

### 4.3 Sizing — iOS

| Size family | Variant A | Variant B |
|---|---|---|
| Small widget | 155 × 155pt (@2× = 310×310px) | — |
| Medium widget | 329 × 155pt (@2× = 658×310px) | 329 × 155pt |
| Large widget | — | 329 × 345pt |

> iOS widget shapes are square/rectangle with rounded corners handled by the OS. Design to the safe area excluding system-applied corner radius (~22pt).

### 4.4 Asset Files

Place PNG assets in the correct Android drawable density folders:

```
android/app/src/main/res/
├── drawable-mdpi/
│   ├── vaanix_widget_a_dark.png      (110×40)
│   ├── vaanix_widget_a_light.png
│   ├── vaanix_widget_b_dark.png      (220×90)
│   └── vaanix_widget_b_light.png
├── drawable-hdpi/    (165×60 / 330×135)
├── drawable-xhdpi/   (220×80 / 440×180)
├── drawable-xxhdpi/  (330×120 / 660×270)
└── drawable-xxxhdpi/ (440×160 / 880×360)  ← master source
```

Scale the four master PNGs (provided) down to each density folder:
- xxxhdpi → xxhdpi: 75%
- xxxhdpi → xhdpi: 50%
- xxxhdpi → hdpi: 37.5%
- xxxhdpi → mdpi: 25%

For iOS: add PNG assets to the `VaanixWidget` extension target under `Assets.xcassets`.

---

## 5. Architecture — PNG Background + XML Tap Targets

**Do not build the visual layout in XML.** Android RemoteViews XML cannot reliably handle rounded corners, gradients, font rendering, or complex icon layouts — this is the root cause of the text wrapping and sizing issues.

**The correct pattern:**

```
Widget layout (XML)
├── ImageView                  ← PNG background (full widget size)
│   └── src: @drawable/vaanix_widget_a_dark (or light)
├── View (transparent)         ← Tap target: full widget (Variant A)
│   └── setOnClickPendingIntent → record deep link
└── [Variant B only:]
    ├── View (transparent)     ← Tap target: notes count zone
    ├── View (transparent)     ← Tap target: tasks count zone
    └── View (transparent)     ← Tap target: latest note zone
```

For **dynamic text** in Variant B (note count, task count, note preview), overlay these as invisible `TextView` elements positioned precisely over the PNG's visual text zones. The PNG provides the visual chrome; XML TextViews provide the live data.

---

## 6. Android Implementation

### 6.1 Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  home_widget: ^0.4.1        # Cross-platform home screen widget
  workmanager: ^0.5.2        # Background data refresh
```

Add to `android/app/build.gradle`:

```gradle
// No additional native deps needed — home_widget handles it
```

### 6.2 AppWidgetProvider

Create `android/app/src/main/kotlin/.../VaanixWidgetProvider.kt`:

```kotlin
class VaanixWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = HomeWidgetPlugin.getData(context)

            val noteCount   = prefs.getInt("widget_note_count", 0)
            val taskCount   = prefs.getInt("widget_open_task_count", 0)
            val latestTitle = prefs.getString("widget_latest_note", "")
            val latestTime  = prefs.getString("widget_latest_time", "")
            val isDark      = prefs.getBoolean("widget_is_dark_theme", true)

            // Choose correct PNG background based on theme
            val bgDrawable = if (isDark) R.drawable.vaanix_widget_b_dark
                             else        R.drawable.vaanix_widget_b_light

            val views = RemoteViews(context.packageName, R.layout.widget_b_layout)
            views.setImageViewResource(R.id.widget_bg, bgDrawable)

            // Dynamic text overlay
            views.setTextViewText(R.id.tv_note_count, noteCount.toString())
            views.setTextViewText(R.id.tv_task_count, taskCount.toString())
            views.setTextViewText(R.id.tv_latest_note, latestTitle ?: "")
            views.setTextViewText(R.id.tv_latest_time, latestTime ?: "")

            // Deep-link intents
            views.setOnClickPendingIntent(R.id.tap_record,
                deepLinkIntent(context, "vaanix://record"))
            views.setOnClickPendingIntent(R.id.tap_notes,
                deepLinkIntent(context, "vaanix://home?tab=notes"))
            views.setOnClickPendingIntent(R.id.tap_tasks,
                deepLinkIntent(context, "vaanix://home?tab=tasks"))
            views.setOnClickPendingIntent(R.id.tap_latest,
                deepLinkIntent(context, "vaanix://note/${prefs.getString("widget_latest_note_id", "")}"))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun deepLinkIntent(context: Context, uri: String): PendingIntent {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(context, uri.hashCode(), intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
    }
}
```

For **Variant A**, repeat with `R.layout.widget_a_layout` and only the `tap_record` intent (no text overlays).

### 6.3 Widget Layouts (XML)

**`res/layout/widget_a_layout.xml`** — Quick Record:

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <!-- PNG background: handles all visual design -->
    <ImageView
        android:id="@+id/widget_bg"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="fitXY"
        android:src="@drawable/vaanix_widget_a_dark" />

    <!-- Full-widget transparent tap target -->
    <View
        android:id="@+id/tap_record"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:background="@android:color/transparent" />

</FrameLayout>
```

**`res/layout/widget_b_layout.xml`** — Dashboard:

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <!-- PNG background -->
    <ImageView
        android:id="@+id/widget_bg"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="fitXY"
        android:src="@drawable/vaanix_widget_b_dark" />

    <!-- Dynamic text overlays (positioned to match PNG layout) -->
    <!-- Note count: approximately left 9%, top 39% of widget height -->
    <TextView
        android:id="@+id/tv_note_count"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="48dp"
        android:layout_marginTop="56dp"
        android:textSize="36sp"
        android:textColor="#F0B637"
        android:fontFamily="sans-serif-medium"
        android:text="0" />

    <!-- Task count: approximately left 27%, top 39% -->
    <TextView
        android:id="@+id/tv_task_count"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="136dp"
        android:layout_marginTop="56dp"
        android:textSize="36sp"
        android:textColor="#FFFFFF"
        android:fontFamily="sans-serif-medium"
        android:text="0" />

    <!-- Latest note title: positioned over preview card area -->
    <TextView
        android:id="@+id/tv_latest_note"
        android:layout_width="140dp"
        android:layout_height="wrap_content"
        android:layout_marginStart="48dp"
        android:layout_marginTop="116dp"
        android:textSize="10sp"
        android:textColor="#CDD7E8"
        android:maxLines="1"
        android:ellipsize="end"
        android:text="" />

    <!-- Latest note time -->
    <TextView
        android:id="@+id/tv_latest_time"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginStart="48dp"
        android:layout_marginTop="130dp"
        android:textSize="9sp"
        android:textColor="#8892A0"
        android:text="" />

    <!-- Tap targets (transparent, positioned over interactive zones) -->
    <!-- REC button zone: right ~15% of widget -->
    <View
        android:id="@+id/tap_record"
        android:layout_width="70dp"
        android:layout_height="26dp"
        android:layout_gravity="end|center_vertical"
        android:layout_marginEnd="8dp"
        android:background="@android:color/transparent" />

    <!-- Notes count zone -->
    <View
        android:id="@+id/tap_notes"
        android:layout_width="80dp"
        android:layout_height="50dp"
        android:layout_marginStart="40dp"
        android:layout_marginTop="50dp"
        android:background="@android:color/transparent" />

    <!-- Tasks count zone -->
    <View
        android:id="@+id/tap_tasks"
        android:layout_width="80dp"
        android:layout_height="50dp"
        android:layout_marginStart="124dp"
        android:layout_marginTop="50dp"
        android:background="@android:color/transparent" />

    <!-- Latest note zone -->
    <View
        android:id="@+id/tap_latest"
        android:layout_width="160dp"
        android:layout_height="36dp"
        android:layout_marginStart="40dp"
        android:layout_marginTop="108dp"
        android:background="@android:color/transparent" />

</FrameLayout>
```

> **Note:** Margin values above are approximate for a 296dp wide widget. Adjust after visual testing on a real device.

### 6.4 AndroidManifest.xml

Add inside `<application>`:

```xml
<!-- Variant A: Quick Record Widget -->
<receiver
    android:name=".VaanixWidgetProviderA"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_a_info" />
</receiver>

<!-- Variant B: Dashboard Widget -->
<receiver
    android:name=".VaanixWidgetProviderB"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_b_info" />
</receiver>
```

### 6.5 Widget Info XML

**`res/xml/widget_a_info.xml`:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="40dp"
    android:targetCellWidth="2"
    android:targetCellHeight="1"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/widget_a_layout"
    android:widgetCategory="home_screen"
    android:description="@string/widget_a_description"
    android:previewImage="@drawable/vaanix_widget_a_dark" />
```

**`res/xml/widget_b_info.xml`:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="220dp"
    android:minHeight="90dp"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/widget_b_layout"
    android:widgetCategory="home_screen"
    android:description="@string/widget_b_description"
    android:previewImage="@drawable/vaanix_widget_b_dark" />
```

> `updatePeriodMillis="0"` — disable Android's built-in polling (minimum is 30 min anyway). Use WorkManager instead for control.

---

## 7. Flutter Side — Data Push to Widget

### 7.1 Widget Data Service

Create `lib/services/widget_service.dart`:

```dart
import 'package:home_widget/home_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WidgetService {
  static const _appGroupId = 'group.com.vaanix.app'; // iOS App Group ID

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  /// Push fresh data to the widget. Call this whenever:
  /// - App comes to foreground
  /// - A note is created, edited, or deleted
  /// - A task is completed
  static Future<void> updateWidgetData({
    required int noteCount,
    required int openTaskCount,
    required String latestNoteTitle,
    required String latestNoteTime,
    required String latestNoteId,
    required bool isDarkTheme,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData<int>('widget_note_count', noteCount),
      HomeWidget.saveWidgetData<int>('widget_open_task_count', openTaskCount),
      HomeWidget.saveWidgetData<String>('widget_latest_note', latestNoteTitle),
      HomeWidget.saveWidgetData<String>('widget_latest_time', latestNoteTime),
      HomeWidget.saveWidgetData<String>('widget_latest_note_id', latestNoteId),
      HomeWidget.saveWidgetData<bool>('widget_is_dark_theme', isDarkTheme),
    ]);
    await HomeWidget.updateWidget(
      androidName: 'VaanixWidgetProviderA',
    );
    await HomeWidget.updateWidget(
      androidName: 'VaanixWidgetProviderB',
    );
  }

  /// Handle deep link taps from the widget
  static Future<void> handleWidgetLaunch(Uri? uri) async {
    if (uri == null) return;
    // Route handling is done in go_router — just log here
    // The URI is: vaanix://record, vaanix://home?tab=notes, vaanix://note/{id}
  }
}

/// Background callback for WorkManager-triggered updates
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'updatewidget') {
    // Lightweight refresh — read from Hive, push to widget
    // Must be minimal: no full app init, just Hive read + HomeWidget.saveWidgetData
  }
}
```

### 7.2 Widget Privacy Filter

Before calling `updateWidgetData`, apply the Widget Privacy setting (only relevant when App Lock is enabled):

```dart
Future<void> refreshWidget(WidgetRef ref) async {
  final settings  = ref.read(settingsProvider);
  final notes     = ref.read(notesProvider);
  final tasks     = ref.read(tasksProvider);

  final appLockEnabled   = settings.appLockEnabled;
  final privacyLevel     = settings.widgetPrivacy; // 'full' | 'record_only' | 'minimal'

  final noteCount     = notes.where((n) => !n.isDeleted).length;
  final openTaskCount = tasks.where((t) => !t.isCompleted && !t.note.isDeleted).length;

  String latestTitle = '';
  String latestTime  = '';
  String latestId    = '';

  // Only show content if privacy allows
  if (!appLockEnabled || privacyLevel == 'full') {
    final latest = notes
        .where((n) => !n.isDeleted)
        .sortedBy((n) => n.createdAt)
        .lastOrNull;
    latestTitle = latest?.title ?? '';
    latestTime  = latest != null ? _formatTime(latest.createdAt) : '';
    latestId    = latest?.id ?? '';
  }

  // Minimal mode: push no data at all — widget shows static PNG only
  if (appLockEnabled && privacyLevel == 'minimal') {
    await WidgetService.updateWidgetData(
      noteCount: 0, openTaskCount: 0,
      latestNoteTitle: '', latestNoteTime: '', latestNoteId: '',
      isDarkTheme: settings.isDarkTheme,
    );
    return;
  }

  await WidgetService.updateWidgetData(
    noteCount: noteCount,
    openTaskCount: openTaskCount,
    latestNoteTitle: latestTitle,
    latestNoteTime: latestTime,
    latestNoteId: latestId,
    isDarkTheme: settings.isDarkTheme,
  );
}
```

### 7.3 Trigger Points — When to Call `refreshWidget`

Add `refreshWidget(ref)` calls at:

| Event | Location |
|---|---|
| App foreground (resume) | `AppLifecycleListener.onResume` in `main.dart` |
| Note created | `NotesNotifier.addNote()` — after Hive write |
| Note edited | `NotesNotifier.updateNote()` — after Hive write |
| Note deleted (to Trash) | `NotesNotifier.softDelete()` — after Hive write |
| Task completed | `TasksNotifier.toggleTask()` — after Hive write |
| Theme changed | `SettingsNotifier.setTheme()` — after Hive write |
| App Lock setting changed | `SettingsNotifier.setAppLock()` — after Hive write |
| Widget Privacy changed | `SettingsNotifier.setWidgetPrivacy()` — after Hive write |

### 7.4 Deep Link Handling (go_router)

Ensure these routes exist in `lib/router/app_router.dart`:

```dart
GoRoute(
  path: '/record',
  name: 'record',
  builder: (context, state) => const RecordingScreen(),
),
GoRoute(
  path: '/home',
  name: 'home',
  builder: (context, state) {
    final tab = state.uri.queryParameters['tab'] ?? 'notes';
    return HomeScreen(initialTab: tab);
  },
),
GoRoute(
  path: '/note/:id',
  name: 'noteDetail',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return NoteDetailScreen(noteId: id);
  },
),
```

Handle widget launch URI in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetService.initialize();

  // Check if app was launched from widget
  final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  if (launchUri != null) {
    // Pass to router after initialization completes
    WidgetService.handleWidgetLaunch(launchUri);
  }

  runApp(ProviderScope(child: VaanixApp(initialUri: launchUri)));
}
```

---

## 8. WorkManager — Background Refresh (Android)

Add to `pubspec.yaml`:

```yaml
dependencies:
  workmanager: ^0.5.2
```

Register periodic refresh in `main.dart` (after app init):

```dart
Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
Workmanager().registerPeriodicTask(
  'vaanix.widget.refresh',
  'updateWidgetTask',
  frequency: const Duration(minutes: 30),
  constraints: Constraints(networkType: NetworkType.not_required),
);
```

```dart
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'updateWidgetTask') {
      // Minimal Hive read (no full app boot)
      // Push updated counts to HomeWidget
    }
    return Future.value(true);
  });
}
```

> WorkManager background tasks run without the full Flutter engine. Keep the task minimal — read note/task counts from Hive, write to HomeWidget shared prefs, trigger widget update.

---

## 9. iOS Implementation

### 9.1 Setup

1. In Xcode: File → New → Target → Widget Extension → Name: `VaanixWidget`
2. Enable App Group: both main target and widget extension → `group.com.vaanix.app`
3. Add PNG assets to `VaanixWidget/Assets.xcassets`

### 9.2 SwiftUI Widget

**`VaanixWidget/VaanixWidget.swift`:**

```swift
import WidgetKit
import SwiftUI

struct VaanixEntry: TimelineEntry {
    let date: Date
    let noteCount: Int
    let taskCount: Int
    let latestNote: String
    let latestTime: String
    let latestNoteId: String
    let isDark: Bool
}

struct VaanixProvider: TimelineProvider {
    func placeholder(in context: Context) -> VaanixEntry {
        VaanixEntry(date: Date(), noteCount: 0, taskCount: 0,
                    latestNote: "", latestTime: "", latestNoteId: "", isDark: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (VaanixEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VaanixEntry>) -> Void) {
        let entry = readEntry()
        // Refresh every 30 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> VaanixEntry {
        let defaults = UserDefaults(suiteName: "group.com.vaanix.app")
        return VaanixEntry(
            date: Date(),
            noteCount:   defaults?.integer(forKey: "widget_note_count") ?? 0,
            taskCount:   defaults?.integer(forKey: "widget_open_task_count") ?? 0,
            latestNote:  defaults?.string(forKey: "widget_latest_note") ?? "",
            latestTime:  defaults?.string(forKey: "widget_latest_time") ?? "",
            latestNoteId: defaults?.string(forKey: "widget_latest_note_id") ?? "",
            isDark:      defaults?.bool(forKey: "widget_is_dark_theme") ?? true
        )
    }
}

// Variant A: Small quick-record widget
struct VaanixWidgetSmallView: View {
    var entry: VaanixEntry

    var body: some View {
        ZStack {
            Image(entry.isDark ? "vaanix_widget_a_dark" : "vaanix_widget_a_light")
                .resizable()
                .scaledToFill()
        }
        .widgetURL(URL(string: "vaanix://record"))
    }
}

// Variant B: Medium dashboard widget
struct VaanixWidgetMediumView: View {
    var entry: VaanixEntry

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(entry.isDark ? "vaanix_widget_b_dark" : "vaanix_widget_b_light")
                .resizable()
                .scaledToFill()

            // Dynamic text overlays
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 56)
                HStack(spacing: 20) {
                    Text("\(entry.noteCount)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "#F0B637"))
                    Text("\(entry.taskCount)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.leading, 48)

                Spacer().frame(height: 30)

                if !entry.latestNote.isEmpty {
                    Text(entry.latestNote)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#CDD7E8"))
                        .lineLimit(1)
                        .padding(.leading, 48)
                    Text(entry.latestTime)
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#8892A0"))
                        .padding(.leading, 48)
                }
                Spacer()
            }
        }
        .widgetURL(URL(string: "vaanix://record")) // fallback
    }
}

@main
struct VaanixWidgetBundle: WidgetBundle {
    var body: some Widget {
        VaanixWidgetSmall()
        VaanixWidgetMedium()
    }
}

struct VaanixWidgetSmall: Widget {
    let kind = "VaanixWidgetSmall"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaanixProvider()) { entry in
            VaanixWidgetSmallView(entry: entry)
        }
        .configurationDisplayName("Quick Record")
        .description("Tap to instantly start recording.")
        .supportedFamilies([.systemSmall])
    }
}

struct VaanixWidgetMedium: Widget {
    let kind = "VaanixWidgetMedium"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VaanixProvider()) { entry in
            VaanixWidgetMediumView(entry: entry)
        }
        .configurationDisplayName("Vaanix Dashboard")
        .description("Notes, tasks, and quick recording at a glance.")
        .supportedFamilies([.systemMedium])
    }
}
```

---

## 10. App Lock Integration

Behaviour matrix when App Lock is enabled (cross-reference: `FEATURE_PHASE1_VALUE_GAPS.md` § Feature 8 — App Lock):

| Widget Privacy Setting | Widget Shows | Record Tap | Content Tap |
|---|---|---|---|
| **Full** | Counts + latest note preview | → Recording Screen (no auth) | → App Lock → content |
| **Record-Only** *(default)* | Counts only (no note text) | → Recording Screen (no auth) | → App Lock → content |
| **Minimal** | Static PNG only (no data) | → App Lock → Recording Screen | → App Lock → content |

Widget Privacy setting appears in **Settings → Security → Widget Privacy** only when both App Lock and a home screen widget are active.

Recording via widget is always a **write operation** (adds new encrypted data). It never exposes existing data. Skipping auth for recording in Full and Record-Only modes is by design.

---

## 11. Strings

Add to `res/values/strings.xml`:

```xml
<string name="widget_a_description">Tap to instantly start a voice recording in Vaanix.</string>
<string name="widget_b_description">See your notes and tasks at a glance, and record instantly.</string>
```

---

## 12. Testing Checklist

### Functional
- [ ] Variant A tap → opens app in Recording Screen
- [ ] Variant B REC tap → opens app in Recording Screen
- [ ] Variant B note count tap → opens Notes tab
- [ ] Variant B task count tap → opens Tasks tab
- [ ] Variant B latest note tap → opens Note Detail
- [ ] Widget data updates after new note is created
- [ ] Widget data updates after task is completed
- [ ] Widget data updates when theme changes (dark ↔ light PNG swaps)
- [ ] Widget updates via WorkManager refresh (test by fast-forwarding time or manual trigger)
- [ ] App launched from widget correctly deep-links to target screen
- [ ] App launched cold (killed) from widget tap works correctly

### App Lock
- [ ] With App Lock OFF → widget shows full data regardless of Privacy setting
- [ ] With App Lock ON, Privacy = Full → all data shown; record bypasses lock
- [ ] With App Lock ON, Privacy = Record-Only (default) → counts shown, no note preview; record bypasses lock
- [ ] With App Lock ON, Privacy = Minimal → no data shown; record tap requires auth
- [ ] Content tap with App Lock ON always shows lock screen before navigating

### Display
- [ ] Dark PNG renders correctly on dark home screen
- [ ] Light PNG renders correctly on light home screen
- [ ] PNG scales correctly at all density buckets (test on mdpi, xhdpi, xxhdpi, xxxhdpi device)
- [ ] No text overflow or clipping in dynamic text overlay zones (Variant B)
- [ ] Widget preview image shows correctly in Android widget picker
- [ ] Rounded corners of PNG are not clipped by OS widget container

### Edge Cases
- [ ] Widget with 0 notes → count shows `0`, no latest note text, no crash
- [ ] Very long note title → truncated with ellipsis in Variant B overlay
- [ ] Widget installed before first note → graceful empty state
- [ ] Widget survives app update without crashing
- [ ] Widget updates correctly after app is restored from backup

---

## 13. New Files

| File | Purpose |
|---|---|
| `lib/services/widget_service.dart` | Data push, deep link handling, WorkManager setup |
| `android/app/src/main/kotlin/.../VaanixWidgetProviderA.kt` | Variant A AppWidgetProvider |
| `android/app/src/main/kotlin/.../VaanixWidgetProviderB.kt` | Variant B AppWidgetProvider |
| `android/app/src/main/res/layout/widget_a_layout.xml` | Variant A widget layout |
| `android/app/src/main/res/layout/widget_b_layout.xml` | Variant B widget layout |
| `android/app/src/main/res/xml/widget_a_info.xml` | Variant A AppWidgetProviderInfo |
| `android/app/src/main/res/xml/widget_b_info.xml` | Variant B AppWidgetProviderInfo |
| `android/app/src/main/res/drawable-*/vaanix_widget_*.png` | PNG assets at all densities (8 files) |
| `ios/VaanixWidget/VaanixWidget.swift` | SwiftUI widget definition |
| `ios/VaanixWidget/Assets.xcassets/vaanix_widget_*.png` | iOS PNG assets |

## 14. Modified Files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `home_widget`, `workmanager` |
| `lib/main.dart` | `WidgetService.initialize()`, WorkManager init, widget launch URI handling |
| `lib/router/app_router.dart` | Ensure `vaanix://record`, `vaanix://home`, `vaanix://note/:id` routes exist |
| `lib/providers/notes_provider.dart` | Call `refreshWidget()` after add/update/delete |
| `lib/providers/tasks_provider.dart` | Call `refreshWidget()` after `toggleTask()` |
| `lib/providers/settings_provider.dart` | Call `refreshWidget()` after theme/App Lock/Widget Privacy changes |
| `android/app/src/main/AndroidManifest.xml` | Register both widget receivers |
| `ios/Runner/Info.plist` | Add widget extension entitlements, App Group |

---

## 15. Estimated Effort

**Medium** — PNG assets already provided. Main work is:
- Android: 2 Kotlin providers, 2 XML layouts, 2 info XMLs, manifest entries (~4–6 hrs)
- Flutter: WidgetService, refresh trigger points, deep link routing (~3–4 hrs)
- iOS: Xcode target setup, SwiftUI widget, App Group config (~3–4 hrs)
- WorkManager background refresh (~2 hrs)
- Testing across densities and App Lock states (~2–3 hrs)

**Total estimate: 14–19 hours**

---

## 16. PNG Assets

The following master PNG files (xxxhdpi) are provided and ready to use:

| File | Dimensions | Use |
|---|---|---|
| `vaanix_widget_a_dark_v3.png` | 440 × 160 px | Variant A, dark theme |
| `vaanix_widget_a_light_v3.png` | 440 × 160 px | Variant A, light theme |
| `vaanix_widget_b_dark_v3.png` | 880 × 360 px | Variant B, dark theme |
| `vaanix_widget_b_light_v3.png` | 880 × 360 px | Variant B, light theme |

Scale these down to all other density folders as per § 4.4. Rename files by removing the `_v3` suffix when placing in drawable folders.

---

*End of Feature Specification — Home Screen Widget*

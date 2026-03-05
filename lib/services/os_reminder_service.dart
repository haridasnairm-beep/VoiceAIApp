import 'package:add_2_calendar/add_2_calendar.dart';

/// Service for creating OS calendar events from in-app reminders.
class OsReminderService {
  OsReminderService._();
  static final OsReminderService instance = OsReminderService._();

  /// Launch the OS calendar with a pre-filled event for the given reminder.
  /// Returns true if the event was successfully created/launched.
  Future<bool> addToOsCalendar({
    required String reminderText,
    required DateTime reminderTime,
    required String noteTitle,
  }) async {
    final event = Event(
      title: reminderText,
      description: 'From Vaanix: $noteTitle',
      startDate: reminderTime,
      endDate: reminderTime.add(const Duration(minutes: 15)),
      allDay: false,
    );

    return Add2Calendar.addEvent2Cal(event);
  }
}

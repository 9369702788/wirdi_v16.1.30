import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/generated/app_localizations.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class DailyReminderScheduler {
  DailyReminderScheduler._();

  static const _idFriday = 900000000;
  static const _idMorningAzkar = 900000001;
  static const _idEveningAzkar = 900000002;
  static const _idDailyWird = 900000003;
  static const _idSleepAzkar = 900000004;

  static const _offsetKey = 'daily_reminders_utc_offset_minutes_v1';

  /// Recurring reminders repeat at a fixed clock time in the zone they were
  /// scheduled with, so after a daylight-saving change (Egypt, Germany, ...) or
  /// a change of time zone they would keep firing at the OLD local hour until
  /// rescheduled. Called on app start: reschedules only when the device's UTC
  /// offset differs from the one used the last time.
  static Future<void> rescheduleIfTimeZoneChanged(AppLocalizations l10n) async {
    final prefs = await SharedPreferences.getInstance();
    final current = DateTime.now().timeZoneOffset.inMinutes;
    if (prefs.getInt(_offsetKey) == current) return;
    await rescheduleAll(l10n);
  }

  static Future<String> rescheduleAll(AppLocalizations l10n) async {
    final offsetPrefs = await SharedPreferences.getInstance();
    await offsetPrefs.setInt(_offsetKey, DateTime.now().timeZoneOffset.inMinutes);
    final reminders = <RecurringReminder>[];

    final friday = appSettings.dailyReminder('friday');
    if (friday.enabled) {
      reminders.add(RecurringReminder(
        id: _idFriday,
        hour: friday.hour,
        minute: friday.minute,
        title: l10n.appTitle,
        body: l10n.reminderFridayBody,
        recurrence: RecurrenceType.weeklyFriday,
      ));
    }

    final morning = appSettings.dailyReminder('morningAzkar');
    if (morning.enabled) {
      reminders.add(RecurringReminder(
        id: _idMorningAzkar,
        hour: morning.hour,
        minute: morning.minute,
        title: l10n.appTitle,
        body: l10n.reminderMorningAzkarBody,
        recurrence: RecurrenceType.daily,
      ));
    }

    final evening = appSettings.dailyReminder('eveningAzkar');
    if (evening.enabled) {
      reminders.add(RecurringReminder(
        id: _idEveningAzkar,
        hour: evening.hour,
        minute: evening.minute,
        title: l10n.appTitle,
        body: l10n.reminderEveningAzkarBody,
        recurrence: RecurrenceType.daily,
      ));
    }

    final wird = appSettings.dailyReminder('dailyWird');
    if (wird.enabled) {
      reminders.add(RecurringReminder(
        id: _idDailyWird,
        hour: wird.hour,
        minute: wird.minute,
        title: l10n.appTitle,
        body: l10n.reminderDailyWirdBody,
        recurrence: RecurrenceType.daily,
      ));
    }

    final sleep = appSettings.dailyReminder('sleepAzkar');
    if (sleep.enabled) {
      reminders.add(RecurringReminder(
        id: _idSleepAzkar,
        hour: sleep.hour,
        minute: sleep.minute,
        title: l10n.appTitle,
        body: l10n.reminderSleepAzkarBody,
        recurrence: RecurrenceType.daily,
      ));
    }

    final sadaqah = appSettings.dailyReminder('sadaqah');
    if (sadaqah.enabled) {
      reminders.add(RecurringReminder(
        id: 900000005,
        hour: sadaqah.hour,
        minute: sadaqah.minute,
        title: l10n.appTitle,
        body: 'تذكير: هل تصدّقت اليوم؟',
        recurrence: RecurrenceType.daily,
      ));
    }
    
    if (appSettings.customAzkarReminders.isNotEmpty) {
      reminders.add(RecurringReminder(
        id: 900000006,
        hour: 9,
        minute: 0,
        title: l10n.appTitle,
        body: 'You have custom azkar waiting for you today',
        recurrence: RecurrenceType.daily,
      ));
    }

    final tahajjud = appSettings.dailyReminder('tahajjud');
    if (tahajjud.enabled) {
      reminders.add(RecurringReminder(
        id: 900000007,
        hour: tahajjud.hour,
        minute: tahajjud.minute,
        title: l10n.appTitle,
        body: 'حان وقت قيام الليل \u2014 اغتنم هذه الساعة المباركة',
        recurrence: RecurrenceType.daily,
      ));
    }

    final weeklySummary = appSettings.dailyReminder('weeklySummary');
    if (weeklySummary.enabled) {
      reminders.add(RecurringReminder(
        id: 900000008,
        hour: weeklySummary.hour,
        minute: weeklySummary.minute,
        title: l10n.appTitle,
        body: 'راجع ملخص أسبوعك في شاشة الإحصائيات',
        recurrence: RecurrenceType.weeklyFriday,
      ));
    }

    final backupReminder = appSettings.dailyReminder('backupReminder');
    if (backupReminder.enabled) {
      reminders.add(RecurringReminder(
        id: 900000009,
        hour: backupReminder.hour,
        minute: backupReminder.minute,
        title: l10n.appTitle,
        body: 'تذكير: هل صدّرت نسخة احتياطية من بياناتك مؤخرًا؟',
        recurrence: RecurrenceType.weeklyFriday,
      ));
    }

    final dailyQuote = appSettings.dailyReminder('dailyQuote');
    if (dailyQuote.enabled) {
      reminders.add(RecurringReminder(
        id: 900000010,
        hour: dailyQuote.hour,
        minute: dailyQuote.minute,
        title: l10n.appTitle,
        body: 'آية أو حديث اليوم بانتظارك في التطبيق',
        recurrence: RecurrenceType.daily,
      ));
    }

    if (reminders.isEmpty) {
      await NotificationService.cancelAllRecurring();
      return 'All reminders disabled';
    }

    return NotificationService.scheduleRecurring(reminders);
  }
}

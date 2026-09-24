import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../models/prayer_models.dart';
import 'notification_service.dart';
import 'prayer_display.dart';
import 'prayer_service.dart';
import 'settings_service.dart';

class PrayerNotificationScheduler {
  PrayerNotificationScheduler._();

  static int _idFor(DateTime date, int prayerIndex, int kind) {
    final epoch = DateTime(2020, 1, 1);
    final days = DateTime(date.year, date.month, date.day).difference(epoch).inDays;
    return days * 30 + prayerIndex * 3 + kind;
  }

  static Future<void> _queue = Future.value();

  static Future<void> rescheduleFromResult(BuildContext context, PrayerTimesResult result) {
    final l10n = AppLocalizations.of(context);
    final future = _queue.then((_) => _rescheduleFromResultLocked(l10n, result));
    _queue = future.catchError((_) {});
    return future;
  }

  static Future<void> _rescheduleFromResultLocked(AppLocalizations l10n, PrayerTimesResult result) async {
    if (!appSettings.prayerReminderEnabled) {
      await NotificationService.cancelAllScheduled();
      await NotificationService.cancelOngoingNextPrayer();
      return;
    }

    final minutesBefore = appSettings.prayerReminderMinutesBefore;
    final notifications = <ScheduledPrayerNotification>[];

    void addFor(List<PrayerItem> prayers, DateTime date) {
      for (var i = 0; i < prayers.length; i++) {
        final prayer = prayers[i];
        if (!appSettings.isPrayerReminderEnabledFor(prayer.name)) continue;

        final modeForThis = appSettings.effectiveModeFor(prayer.name);
        final silentForThis = modeForThis == 'banner';

        final displayName = prayerDisplayName(l10n, prayer.name);

        if (minutesBefore > 0) {
          notifications.add(ScheduledPrayerNotification(
            id: _idFor(date, i, 0),
            fireAt: prayer.dateTime.subtract(Duration(minutes: minutesBefore)),
            title: l10n.appTitle,
            body: l10n.prayerReminderApproaching(displayName, minutesBefore),
            silent: silentForThis,
          ));
        }

        if (appSettings.notifyAtPrayerTime) {
          notifications.add(ScheduledPrayerNotification(
            id: _idFor(date, i, 1),
            fireAt: prayer.dateTime,
            title: l10n.appTitle,
            body: l10n.prayerTimeNowBody(displayName),
            silent: silentForThis,
            useAdhanSound: modeForThis == 'adhan',
          ));
        }

        if (appSettings.postPrayerReminderEnabled) {
          notifications.add(ScheduledPrayerNotification(
            id: _idFor(date, i, 2),
            fireAt: prayer.dateTime.add(Duration(minutes: appSettings.postPrayerReminderMinutesAfter)),
            title: l10n.appTitle,
            body: l10n.postPrayerReminderBody(displayName),
            silent: silentForThis,
          ));
        }
      }
    }

    final today = DateTime.now();
    addFor(result.prayers, today);

    // v1.55: schedule the next 14 days ahead (was: today + tomorrow only, so
    // the adhan stopped after ~2 days without opening the app). One calendar
    // request per month covers the whole window.
    final upcomingDays = await PrayerService.fetchUpcomingPrayers(days: 14);
    final orderedDays = upcomingDays.keys.toList()..sort();
    for (final day in orderedDays) {
      addFor(upcomingDays[day]!, day);
    }

    // If the calendar couldn't be fetched (offline), keep the notifications that
    // are already scheduled for later days instead of wiping them.
    await NotificationService.scheduleAll(notifications, keepFuture: upcomingDays.isEmpty);

    if (appSettings.ongoingPrayerNotificationEnabled) {
      final now = DateTime.now();
      final upcoming = <PrayerItem>[
        ...result.prayers,
        for (final day in orderedDays) ...upcomingDays[day]!,
      ]
          .where((p) => p.dateTime.isAfter(now))
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      if (upcoming.isNotEmpty) {
        final next = upcoming.first;
        final displayName = prayerDisplayName(l10n, next.name);
        final timeStr = '${next.dateTime.hour.toString().padLeft(2, '0')}:${next.dateTime.minute.toString().padLeft(2, '0')}';
        await NotificationService.showOngoingNextPrayer(title: l10n.appTitle, body: '$displayName \u2022 $timeStr');
      }
    } else {
      await NotificationService.cancelOngoingNextPrayer();
    }
  }
}

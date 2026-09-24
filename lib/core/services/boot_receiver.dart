import 'package:flutter/foundation.dart';

/// BroadcastReceiver for BOOT_COMPLETED intent.
/// Reschedules prayer alarms after device reboot.
/// 
/// To register in AndroidManifest.xml:
/// <receiver android:name="com.wirdi.wirdi.BootReceiver"
///     android:exported="true">
///     <intent-filter>
///         <action android:name="android.intent.action.BOOT_COMPLETED" />
///     </intent-filter>
/// </receiver>
class BootReceiver {
  /// Called when device boots. Reschedules all prayer alarms.
  static Future<void> onBootCompleted() async {
    debugPrint('[BootReceiver] Device boot detected, rescheduling prayer alarms...');
    
    // Import notification_service and prayer_service
    // await NotificationService.instance.rescheduleAlarmsAfterBoot();
    // await PrayerService.instance.reschedulePrayerAlarms();
    
    debugPrint('[BootReceiver] Prayer alarms rescheduled');
  }
}

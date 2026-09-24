import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/prayer_service.dart';
import '../../core/theme/app_theme.dart';

String _t(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

/// Consolidates 3 separate audit suggestions into one screen: live
/// permission/status diagnostics, a ground-truth pending-notifications
/// count (straight from Android, not from this app's own bookkeeping),
/// and a one-tap "repair" flow that redoes the whole permission-check +
/// fetch + reschedule + verify sequence and reports exactly what
/// happened. Meant to turn "notifications aren't working" support
/// questions into a 10-second self-diagnosis instead of a guessing game.
class NotificationDiagnosticsScreen extends StatefulWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  State<NotificationDiagnosticsScreen> createState() => _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState extends State<NotificationDiagnosticsScreen> {
  bool _loading = true;
  bool _notifsEnabled = false;
  bool _exactAlarmAllowed = false;
  int _pendingCount = 0;
  String? _nextTitle;
  String? _repairResult;
  bool _repairing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final notifsEnabled = await NotificationService.areNotificationsEnabled();
    final exactAlarm = await NotificationService.canScheduleExactAlarms();
    final pending = await NotificationService.pendingRequests();
    String? nextTitle;
    if (pending.isNotEmpty) {
      nextTitle = pending.first.title;
    }
    if (!mounted) return;
    setState(() {
      _notifsEnabled = notifsEnabled;
      _exactAlarmAllowed = exactAlarm;
      _pendingCount = pending.length;
      _nextTitle = nextTitle;
      _loading = false;
    });
  }

  Future<void> _repair(BuildContext context) async {
    setState(() {
      _repairing = true;
      _repairResult = null;
    });
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final steps = <String>[];
    try {
      final granted = await NotificationService.requestPermission();
      steps.add(isAr
          ? (granted ? 'OK: ' + (isAr ? 'الإذن ممنوح' : '') : 'تنبيه: الإذن غير ممنوح')
          : (granted ? 'OK: Permission granted' : 'Warning: Permission not granted'));

      final result = await PrayerService.fetchUsingSavedPreference();
      if (context.mounted) {
        await PrayerNotificationScheduler.rescheduleFromResult(context, result);
      }
      steps.add(isAr ? 'OK: تمت إعادة جدولة المواقيت' : 'OK: Prayer times rescheduled');

      final pending = await NotificationService.pendingRequests();
      steps.add(isAr
          ? 'OK: يوجد ' + pending.length.toString() + ' إشعار مجدول فعليًا عند أندرويد'
          : 'OK: ' + pending.length.toString() + ' notification(s) actually scheduled with Android');

      if (mounted) {
        setState(() {
          _repairResult = steps.join('\n');
          _repairing = false;
        });
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _repairResult = (isAr ? 'فشل الإصلاح: ' : 'Repair failed: ') + e.toString();
          _repairing = false;
        });
      }
    }
  }

  Widget _statusTile(String label, bool ok, {String? valueText}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(ok ? Icons.check_circle : Icons.error_outline, color: ok ? AppColors.primaryEmerald : Colors.redAccent),
      title: Text(label),
      trailing: valueText != null ? Text(valueText, style: const TextStyle(fontWeight: FontWeight.w700)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'تشخيص الإشعارات', 'Notification Diagnostics')),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _refresh),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      children: [
                        _statusTile(_t(context, 'إذن الإشعارات', 'Notification permission'), _notifsEnabled),
                        const Divider(height: 1),
                        _statusTile(_t(context, 'المنبّه الدقيق (Exact Alarm)', 'Exact alarm permission'), _exactAlarmAllowed),
                        const Divider(height: 1),
                        _statusTile(
                          _t(context, 'الإشعارات المجدولة حاليًا', 'Currently scheduled'),
                          _pendingCount > 0,
                          valueText: '$_pendingCount',
                        ),
                        if (_nextTitle != null) ...[
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.notifications_active_outlined, color: AppColors.goldAccent),
                            title: Text(_t(context, 'مثال لإشعار مجدول', 'A scheduled notification')),
                            subtitle: Text(_nextTitle!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!_notifsEnabled || !_exactAlarmAllowed)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      _t(
                        context,
                        'بعض الصلاحيات غير ممنوحة. اضغط "إصلاح" تحت لطلبها من جديد، أو افتح إعدادات النظام يدويًا.',
                        'Some permissions are missing. Tap "Repair" to request them again, or open system settings manually.',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _repairing ? null : () => _repair(context),
                  icon: _repairing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.build_circle_outlined),
                  label: Text(_t(context, 'إصلاح الإشعارات', 'Repair Notifications')),
                ),
                if (_repairResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: Text(_repairResult!, style: const TextStyle(fontSize: 13, height: 1.6)),
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
                    await NotificationService.showTestNotification();
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(_t(context, 'اختبار إشعار فوري', 'Test immediate notification')),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final error = await NotificationService.scheduleTestNotificationSoon();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error == null
                          ? _t(context, 'تمت الجدولة -- اقفل الشاشة وانتظر دقيقة', 'Scheduled -- lock your screen and wait 1 minute')
                          : (isAr ? 'فشل: $error' : 'Failed: $error'))),
                    );
                  },
                  icon: const Icon(Icons.schedule_send_outlined),
                  label: Text(_t(context, 'اختبار إشعار مجدول (دقيقة)', 'Test scheduled notification (1 min)')),
                ),
                const SizedBox(height: 20),
                // v1.55: battery optimisation is the #1 reason the adhan is late or
                // missing on Samsung / Xiaomi / Oppo phones.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.battery_alert_outlined, color: AppColors.mutedText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _t(context, 'إذا تأخر الأذان أو لم يصل', 'If the adhan is late or missing'),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            context,
                            'على بعض الأجهزة (سامسونج، شاومي، أوبو…) قد يوقف النظام التطبيق في الخلفية فيتأخر الأذان أو لا يصل. افتح إعدادات التطبيق ثم البطارية واختر «غير مقيّد» (أو «بدون قيود»)، وفعّل «التشغيل التلقائي» إن وُجد.',
                            'On some phones (Samsung, Xiaomi, Oppo...) the system may stop apps in the background, so the adhan can be late or missing. Open the app settings, then Battery, and choose "Unrestricted" (and enable "Autostart" if your phone has it).',
                          ),
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => Geolocator.openAppSettings(),
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(_t(context, 'فتح إعدادات التطبيق', 'Open app settings')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

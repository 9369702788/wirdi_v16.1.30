

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../quran/tajweed_legend.dart';
import '../../core/services/islamic_occasions_service.dart';
import '../auth/account_screen.dart';
import 'theme_selection_screen.dart';
import 'about_screen.dart';
import 'privacy_center_screen.dart';
import 'sources_licenses_screen.dart';
import '../../core/services/auth_service.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/data/adhan_option.dart';
import '../../core/services/audio_download_service.dart';
import '../../core/services/adhan_audio_cache.dart';
import '../../core/services/notification_service.dart';
import 'notification_diagnostics_screen.dart';
import '../../core/services/daily_reminder_scheduler.dart';
import '../../core/services/quran_repository.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/prayer_notification_scheduler.dart';
import '../../core/services/mathhab_service.dart';
import '../../core/data/app_sources.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _wirdTarget = 5;
  final AudioPlayer _previewPlayer = AudioPlayer();
  StreamSubscription<void>? _previewCompleteSub;
  String? _previewingAdhanId;
  DateTime? _quranCachedAt;
  int _downloadedAudioBytes = 0;
  String _selectedMathhab = 'Shafi\'i'; // matches MathhabService's default; _loadMathhab() overwrites this from storage anyway
  String? _realAppVersion;

  @override
  void initState() {
    super.initState();
    _loadWirdTarget();
    _loadCacheInfo();
    _loadDownloadedAudioSize();
    _loadMathhab();
    _loadRealAppVersion();
    _previewCompleteSub = _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _previewingAdhanId = null);
    });
  }

  Future<void> _loadRealAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _realAppVersion = '${info.version}+${info.buildNumber}');
    } catch (_) {}
  }

  Future<void> _loadDownloadedAudioSize() async {
    final bytes = await AudioDownloadService.totalStorageUsedBytes();
    if (mounted) setState(() => _downloadedAudioBytes = bytes);
  }

  Future<void> _loadMathhab() async {
    final m = await MathhabService.getMathhab();
    if (mounted) setState(() => _selectedMathhab = m);
  }

  String _downloadedAudioSize(AppLocalizations l10n) {
    if (_downloadedAudioBytes == 0) return l10n.settingsNoDownloadedAudio;
    final mb = _downloadedAudioBytes / (1024 * 1024);
    return l10n.settingsMbDownloaded(mb.toStringAsFixed(1));
  }

  Future<void> _confirmDeleteAllDownloads() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAllDownloadsTitle),
        content: Text(l10n.settingsDeleteAllDownloadsBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await AudioDownloadService.deleteAllDownloads();
      _loadDownloadedAudioSize();
    }
  }

  @override
  void dispose() {
_previewCompleteSub?.cancel();
        _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreviewAdhan(AdhanOption option) async {
    if (_previewingAdhanId == option.id) {
      try {
        await _previewPlayer.stop();
      } catch (_) {
        // Nothing loaded — fine.
      }
      setState(() => _previewingAdhanId = null);
      return;
    }

    setState(() => _previewingAdhanId = option.id);
    try {
      try {
        await _previewPlayer.stop();
      } catch (_) {
        // Nothing loaded yet — expected on first preview, safe to ignore.
      }
      await _previewPlayer.play(UrlSource(option.url));
    } catch (e) {
      if (mounted) {
        setState(() => _previewingAdhanId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).settingsPreviewFailed)),
        );
      }
    }
  }

  Future<void> _loadCacheInfo() async {
    final quranAt = await QuranRepository.cachedAt();
    if (mounted) {
      setState(() {
        _quranCachedAt = quranAt;
      });
    }
  }

  String _formatCacheDate(DateTime? date, String languageCode, AppLocalizations l10n) {
    if (date == null) return l10n.settingsNotDownloadedYet;
    // Falls back to 'en' formatting for locales without an intl date
    // pattern registered (all four we ship are registered in main.dart).
    return DateFormat('d MMMM y, h:mm a', languageCode).format(date);
  }

  Future<void> _rescheduleAllPrayerReminders() async {
    try {
      final result = await PrayerService.fetchUsingSavedPreference();
      if (mounted) {
        await PrayerNotificationScheduler.rescheduleFromResult(context, result);
      }
    } catch (_) {
      // No saved location / offline yet -- reminders will reschedule next
      // time the Prayer Times screen successfully fetches.
    }
  }

  Future<void> _loadWirdTarget() async {
    final target = await UserProgressService.dailyWirdTarget();
    if (mounted) setState(() => _wirdTarget = target);
  }

  Future<void> _setWirdTarget(int value) async {
    if (value < 1) return;
    await UserProgressService.setDailyWirdTarget(value);
    setState(() => _wirdTarget = value);
  }

  Future<void> _confirmClearData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteLocalData),
        content: Text(l10n.settingsDeleteLocalDataBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await UserProgressService.clearAllLocalData();
      await appSettings.load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsLocalDataDeleted)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: true),
      body: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) {
          return ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                // Internal build-diagnostic text -- only ever useful to us
                // during development, confusing/unprofessional for a real
                // end user to see in Settings. Debug builds only now.
                child: kDebugMode
                    ? Text(
                        'Build: ${_realAppVersion ?? '...'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      )
                    : const SizedBox.shrink(),
              ),
                        ExpansionTile(
                title: Text(l10n.settingsAppearance, style: const TextStyle(fontWeight: FontWeight.w700)),
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [

            // ── Account / Cloud Sync ──────────────────────────────────────
            ListenableBuilder(
              listenable: AuthService.instance,
              builder: (context, _) {
                final user = AuthService.instance.currentUser;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryEmerald,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null
                          ? Text(
                              user != null
                                  ? (user.displayName ?? user.email ?? 'U')[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white,
                                  fontWeight: FontWeight.bold))
                          : null,
                    ),
                    title: Text(
                      user != null
                          ? (user.displayName ?? user.email ?? 'Account')
                          : 'Sign in to sync progress',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      user != null ? 'Cloud sync enabled ✓' : 'Data stays on this device',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(Icons.chevron_left, color: Colors.grey.shade400, size: 20),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AccountScreen())),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
                        Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.settingsMode, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          style: const ButtonStyle(visualDensity: VisualDensity.compact),
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l10n.settingsModeLight, overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l10n.settingsModeDark, overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l10n.settingsModeAuto, overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                          ],
                          // Icons removed -- with 3 segments + icon + label side by side, longer
                          // translated labels (e.g. Arabic "تلقائي") didn't fit the available
                          // width and wrapped to a 2nd line, growing the button's height beyond
                          // what the parent Column expected -- causing a real RenderFlex
                          // "bottom overflowed by 109 pixels" render error. Text-only segments
                          // fit reliably across all supported languages.
                          selected: {appSettings.themeMode},
                          onSelectionChanged: (set) => appSettings.setThemeMode(set.first),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: appSettings.amoledDarkMode,
                        title: Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? 'الوضع الداكن الخالص (AMOLED)' : 'Pure black (AMOLED) dark mode',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'خلفية سوداء خالصة توفّر البطارية في شاشات AMOLED عند تفعيل الوضع الداكن'
                              : 'True-black background that saves battery on AMOLED screens when dark mode is on',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onChanged: (value) async {
                          await appSettings.setAmoledDarkMode(value);
                        },
                      ),
                      const SizedBox(height: 20),
                      // Color theme picker: a row of tappable swatches, one per
                      // AppColorTheme, each showing that theme's primary+accent
                      // colors. The selected one gets a check mark and a ring
                      // border. Works independently of light/dark/auto above --
                      // e.g. "Ocean + Dark" and "Ruby + Light" are both valid
                      // combinations.
                      Builder(builder: (context) {
                        const labelByLocale = {
                          'ar': 'لون التطبيق', 'en': 'App color', 'de': 'App-Farbe', 'tr': 'Uygulama rengi',
                          'fr': 'Couleur de l\'application', 'es': 'Color de la app', 'id': 'Warna aplikasi',
                        };
                        final lang = Localizations.localeOf(context).languageCode;
                        return Text(labelByLocale[lang] ?? labelByLocale['en']!, style: const TextStyle(fontWeight: FontWeight.w700));
                      }),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 76,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: AppColorTheme.values.map((t) {
                            final def = AppTheme.definitions[t]!;
                            final isSelected = appSettings.colorTheme == t;
                            return Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: GestureDetector(
                                onTap: () => appSettings.setColorTheme(t),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [def.primary, def.accent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        border: Border.all(
                                          color: isSelected ? def.primary : Colors.transparent,
                                          width: 3,
                                        ),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: def.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                                            : null,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(def.displayNameFor(Localizations.localeOf(context).languageCode), style: const TextStyle(fontSize: 10)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSelectionScreen())),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: Text({
                            'ar': 'معاينة كاملة لكل الثيمات', 'en': 'See full theme previews', 'de': 'Alle Themenvorschauen ansehen',
                            'tr': 'Tum tema onizlemelerini gor', 'fr': 'Voir tous les apercus de themes', 'es': 'Ver todas las vistas previas',
                            'id': 'Lihat semua pratinjau tema',
                          }[Localizations.localeOf(context).languageCode] ?? 'See full theme previews'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.settingsFontSize, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Slider(
                        value: appSettings.fontScale,
                        min: 0.85,
                        max: 1.4,
                        divisions: 11,
                        label: '${(appSettings.fontScale * 100).round()}%',
                        onChanged: (value) => appSettings.setFontScale(value),
                      ),
                      Text(
                        l10n.settingsFontPreview,
                        style: TextStyle(fontSize: 16 * appSettings.fontScale),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.settingsShowTransliteration),
                        subtitle: Text(l10n.settingsShowTransliterationSubtitle),
                        value: appSettings.showTransliteration,
                        activeTrackColor: AppColors.primaryEmerald,
                        onChanged: (value) => appSettings.setShowTransliteration(value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.settingsTajweedColoring),
                        subtitle: Text(l10n.settingsTajweedColoringSubtitle),
                        value: appSettings.showTajweedColoring,
                        activeTrackColor: AppColors.primaryEmerald,
                        onChanged: (value) => appSettings.setShowTajweedColoring(value),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.palette_outlined, color: AppColors.mutedText),
                        title: Text(l10n.tajweedLegendTitle),
                        onTap: () => showTajweedLegend(context),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language_outlined, color: AppColors.mutedText),
                        title: Text(l10n.settingsLanguage),
                        subtitle: Text(l10n.settingsLanguageSubtitle),
                        trailing: Text(
                          appSettings.explicitLocale == null
                              ? l10n.settingsLanguageSystem
                              : {
                                  'ar': l10n.languageName_ar,
                                  'en': l10n.languageName_en,
                                  'de': l10n.languageName_de,
                                  'tr': l10n.languageName_tr,
                                }[appSettings.explicitLocale!.languageCode] ?? '',
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                        onTap: () => _showLanguageSheet(context, l10n),
                    ),
                  ],
                ),
            ]))),
                  ],
                ),
              const SizedBox(height: 20),
              ExpansionTile(
                title: Text(l10n.settingsPrayerReminder, style: const TextStyle(fontWeight: FontWeight.w700)),
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.settingsPrayerReminderEnable),
                      subtitle: Text(l10n.settingsPrayerReminderSubtitle),
                      value: appSettings.prayerReminderEnabled,
                      activeTrackColor: AppColors.primaryEmerald,
                      onChanged: (value) async {
                        for (final key in AppSettings.remindablePrayerKeys) {
                          await appSettings.setPrayerReminderEnabledFor(key, value);
                        }
                        if (value) {
                          await NotificationService.requestPermission();
                        }
                        unawaited(_rescheduleAllPrayerReminders());
                      },
                    ),
                    if (appSettings.prayerReminderEnabled) ...[
                      const SizedBox(height: 8),
                      Text(l10n.settingsRemindMeFor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        for (final key in AppSettings.remindablePrayerKeys)
                          FilterChip(
                            label: Text(_prayerKeyLabel(l10n, key)),
                            selected: appSettings.isPrayerReminderEnabledFor(key),
                            onSelected: (sel) async {
                              await appSettings.setPrayerReminderEnabledFor(key, sel);
                              unawaited(_rescheduleAllPrayerReminders());
                            },
                          ),
                      ]),
                      const SizedBox(height: 16),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? '\u0637\u0631\u064a\u0642\u0629 \u062d\u0633\u0627\u0628 \u0627\u0644\u0645\u0648\u0627\u0642\u064a\u062a' : 'Calculation method',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<int>(
                        isExpanded: true,
                        value: appSettings.prayerCalcMethod,
                        items: [
                          for (final m in AppSources.prayerCalculationMethods)
                            DropdownMenuItem(
                              value: m.$1,
                              child: Text(Localizations.localeOf(context).languageCode == 'ar' ? m.$2 : m.$3),
                            ),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          await appSettings.setPrayerCalcMethod(value);
                          await PrayerService.clearCache();
                          unawaited(_rescheduleAllPrayerReminders());
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Localizations.localeOf(context).languageCode == 'ar'
                                  ? 'تعديل التاريخ الهجري (بالأيام)'
                                  : 'Hijri date adjustment (days)',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: appSettings.hijriDayOffset <= -2
                                ? null
                                : () async {
                                    await appSettings.setHijriDayOffset(appSettings.hijriDayOffset - 1);
                                    unawaited(IslamicOccasionsService.scheduleReminders());
                                  },
                          ),
                          Text(
                            '${appSettings.hijriDayOffset > 0 ? '+' : ''}${appSettings.hijriDayOffset}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: appSettings.hijriDayOffset >= 2
                                ? null
                                : () async {
                                    await appSettings.setHijriDayOffset(appSettings.hijriDayOffset + 1);
                                    unawaited(IslamicOccasionsService.scheduleReminders());
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'المذهب الفقهي' : 'Madhhab (school of thought)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedMathhab,
                        items: [
                          for (final m in MathhabService.mathhabs)
                            DropdownMenuItem(value: m, child: Text(m)),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          setState(() => _selectedMathhab = value);
                          await MathhabService.setMathhab(value);
                          await PrayerService.clearCache();
                          unawaited(_rescheduleAllPrayerReminders());
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'معايرة مواقيت الصلاة (بالدقائق)' : 'Prayer time calibration (minutes)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      for (final prayerKey in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(child: Text(prayerKey)),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () => appSettings.setPrayerOffset(prayerKey, (appSettings.prayerOffsets[prayerKey] ?? 0) - 1),
                              ),
                              SizedBox(width: 30, child: Text('${appSettings.prayerOffsets[prayerKey] ?? 0}', textAlign: TextAlign.center)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => appSettings.setPrayerOffset(prayerKey, (appSettings.prayerOffsets[prayerKey] ?? 0) + 1),
                              ),
                            ],
                          ),
                        ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: appSettings.highContrastEnabled,
                        title: Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? 'وضع التباين العالي' : 'High-contrast mode',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onChanged: (value) async {
                          await appSettings.setHighContrastEnabled(value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: appSettings.widgetLocked,
                        title: Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? 'قفل الويدجت' : 'Lock home-screen widget',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'امنع تحديث محتوى الويدجت تلقائيًا وثبّته على آخر ما ظهر'
                              : 'Stop the widget from auto-refreshing; keep it frozen on its last content',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onChanged: (value) async {
                          await appSettings.setWidgetLocked(value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: appSettings.autoDarkModeAtMaghrib,
                        title: Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? 'الوضع الداكن التلقائي مع المغرب' : 'Auto dark mode at Maghrib',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'يتحول التطبيق للوضع الداكن تلقائيًا بعد أذان المغرب، وللوضع الفاتح بعد الفجر'
                              : 'Automatically switch to dark mode after Maghrib, and back to light mode after Fajr',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onChanged: (value) async {
                          await appSettings.setAutoDarkModeAtMaghrib(value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: appSettings.ongoingPrayerNotificationEnabled,
                        title: Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? '\u0625\u0634\u0639\u0627\u0631 \u062f\u0627\u0626\u0645 \u0644\u0644\u0635\u0644\u0627\u0629 \u0627\u0644\u0642\u0627\u062f\u0645\u0629' : 'Ongoing next-prayer notification',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onChanged: (value) async {
                          await appSettings.setOngoingPrayerNotificationEnabled(value);
                          unawaited(_rescheduleAllPrayerReminders());
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.settingsPrayerReminderMinutesBefore, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Slider(
                        value: appSettings.prayerReminderMinutesBefore.toDouble(),
                        min: 0, max: 30, divisions: 30,
                        label: l10n.settingsPrayerReminderMinutesLabel(appSettings.prayerReminderMinutesBefore),
                        onChanged: (v) => setState(() {}),
                        onChangeEnd: (v) async {
                          await appSettings.setPrayerReminderMinutesBefore(v.round());
                          unawaited(_rescheduleAllPrayerReminders());
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.settingsPrayerReminderMethod, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'adhan', label: Text(l10n.settingsReminderAdhan)),
                          ButtonSegment(value: 'beep', label: Text(l10n.settingsReminderBeep)),
                          ButtonSegment(value: 'banner', label: Text(l10n.settingsReminderBanner)),
                        ],
                        selected: {appSettings.prayerReminderMode == 'off' ? 'banner' : appSettings.prayerReminderMode},
                        onSelectionChanged: (set) async {
                          await appSettings.setPrayerReminderMode(set.first);
                          unawaited(_rescheduleAllPrayerReminders());
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? '\u062a\u062e\u0635\u064a\u0635 \u0635\u0648\u062a \u0643\u0644 \u0635\u0644\u0627\u0629 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)'
                            : 'Per-prayer sound override (optional)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      for (final key in AppSettings.remindablePrayerKeys)
                        if (appSettings.isPrayerReminderEnabledFor(key))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(child: Text(_prayerKeyLabel(l10n, key))),
                                DropdownButton<String>(
                                  value: appSettings.prayerSoundOverrideFor(key),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'default',
                                      child: Text(Localizations.localeOf(context).languageCode == 'ar' ? '\u0627\u0641\u062a\u0631\u0627\u0636\u064a' : 'Default'),
                                    ),
                                    DropdownMenuItem(value: 'adhan', child: Text(l10n.settingsReminderAdhan)),
                                    DropdownMenuItem(value: 'beep', child: Text(l10n.settingsReminderBeep)),
                                    DropdownMenuItem(value: 'banner', child: Text(l10n.settingsReminderBanner)),
                                  ],
                                  onChanged: (value) async {
                                    if (value == null) return;
                                    await appSettings.setPrayerSoundOverrideFor(key, value);
                                    unawaited(_rescheduleAllPrayerReminders());
                                  },
                                ),
                              ],
                            ),
                          ),
                      if (appSettings.prayerReminderMode == 'adhan') ...[
                        const SizedBox(height: 16),
                        Text(l10n.settingsAdhanSound, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        for (final option in AppSources.adhanOptions)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(option.displayNameFor(languageCode)),
                            leading: Radio<String>(
                              value: option.id,
                              groupValue: appSettings.adhanId,
                              onChanged: (id) async {
                                if (id == null) return;
                                await appSettings.setAdhanId(id);
                                // AUDIT FIX: pre-download the newly-selected
                                // reciter's Adhan audio now, in the background,
                                // so it's already cached locally by the time a
                                // real Adhan notification needs to play it
                                // (Android notification sounds can't stream a
                                // remote URL -- they need a local file).
                                unawaited(AdhanAudioCache.ensureDownloaded(id));
                                unawaited(_rescheduleAllPrayerReminders());
                              },
                            ),
                            trailing: IconButton(
                              icon: Icon(_previewingAdhanId == option.id ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                              tooltip: _previewingAdhanId == option.id ? l10n.settingsStopPreview : l10n.settingsListen,
                              onPressed: () => _togglePreviewAdhan(option),
                            ),
                            onTap: () async {
                              await appSettings.setAdhanId(option.id);
                              unawaited(AdhanAudioCache.ensureDownloaded(option.id));
                              unawaited(_rescheduleAllPrayerReminders());
                            },
                          ),
                      ],
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.settingsNotifyAtPrayerTime),
                        subtitle: Text(l10n.settingsNotifyAtPrayerTimeSubtitle),
                        value: appSettings.notifyAtPrayerTime,
                        activeTrackColor: AppColors.primaryEmerald,
                        onChanged: (value) async {
                          await appSettings.setNotifyAtPrayerTime(value);
                          unawaited(_rescheduleAllPrayerReminders());
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.settingsPostPrayerReminder),
                        subtitle: Text(appSettings.postPrayerReminderEnabled
                            ? l10n.settingsPostPrayerReminderMinutesLabel(appSettings.postPrayerReminderMinutesAfter)
                            : l10n.settingsPostPrayerReminderSubtitle),
                        value: appSettings.postPrayerReminderEnabled,
                        activeTrackColor: AppColors.primaryEmerald,
                        onChanged: (value) async {
                          await appSettings.setPostPrayerReminderEnabled(value);
                          unawaited(_rescheduleAllPrayerReminders());
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.settingsReminderNote, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_active_outlined, color: AppColors.primaryEmerald),
                  title: const Text('Send test notification now'),
                  subtitle: const Text('Diagnostic: checks if notifications can show on this device at all'),
                  onTap: () async {
                    await NotificationService.requestPermission();
                    final error = await NotificationService.showTestNotification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error == null
                          ? 'Test notification sent -- check your notification shade now.'
                          : 'Failed: ' + error)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.health_and_safety_outlined, color: AppColors.primaryEmerald),
                  title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تشخيص وإصلاح الإشعارات' : 'Notification Diagnostics & Repair'),
                  subtitle: Text(Localizations.localeOf(context).languageCode == 'ar'
                      ? 'اطمئن إن الإشعارات شغالة فعليًا، أو أصلحها بضغطة واحدة'
                      : 'Check permissions, verify what is actually scheduled, or repair with one tap'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationDiagnosticsScreen())),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(Icons.schedule_send_outlined, color: AppColors.primaryEmerald),
                  title: const Text('Schedule test notification in 1 minute'),
                  subtitle: const Text('Diagnostic: proves whether SCHEDULED notifications (like Adhan/reminders) can actually fire on this device -- lock your screen and wait 1 minute after tapping'),
                  onTap: () async {
                    await NotificationService.requestPermission();
                    final error = await NotificationService.scheduleTestNotificationSoon();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error == null
                          ? 'Scheduled -- lock your screen now and wait about 1 minute.'
                          : 'Failed: ' + error)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(Icons.volume_up_rounded, color: AppColors.primaryEmerald),
                  title: const Text('Test Adhan notification now'),
                  subtitle: const Text('Fires the REAL Adhan sound through the REAL notification channel immediately -- no need to wait for an actual prayer time'),
                  onTap: () async {
                    await NotificationService.requestPermission();
                    final error = await NotificationService.showTestAdhanNotification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error == null
                          ? 'Test Adhan sent -- you should hear the Adhan sound now.'
                          : 'Failed: ' + error)),
                    );
                  },
                ),
              ),
                  ],
                ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: Text(l10n.settingsMoreReminders, style: const TextStyle(fontWeight: FontWeight.w700)),
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    _DailyReminderTile(reminderKey: 'friday', title: l10n.settingsFridayReminder, subtitle: l10n.settingsFridayReminderSubtitle),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'سنن يوم الجمعة' : 'Friday (Jummah) Sunnahs'),
                              content: SingleChildScrollView(
                                child: Text(
                                  Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'الاغتسال يوم الجمعة\nالتبكير للمسجد\nالاستماع للخطبة بإنصات\nالإكثار من الصلاة على النبي صلى الله عليه وسلم\nقراءة سورة الكهف\nالدعاء في ساعة الإجابة (آخر ساعة قبل المغرب)'
                                      : 'Taking a bath (Ghusl) before going\nGoing early to the mosque\nListening attentively to the khutbah\nSending abundant blessings upon the Prophet\nReading Surah Al-Kahf\nMaking dua in the hour of acceptance (the last hour before Maghrib)',
                                ),
                              ),
                              actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'إغلاق' : 'Close'))],
                            ),
                          ),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'سنن الجمعة' : 'Jummah Sunnahs'),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _DailyReminderTile(reminderKey: 'morningAzkar', title: l10n.settingsMorningAzkarReminder, subtitle: l10n.settingsMorningAzkarReminderSubtitle),
                    const Divider(height: 1),
                    _DailyReminderTile(
                      reminderKey: 'tahajjud',
                      title: Localizations.localeOf(context).languageCode == 'ar' ? 'تذكير قيام الليل' : 'Tahajjud reminder',
                      subtitle: Localizations.localeOf(context).languageCode == 'ar' ? 'تذكير في آخر الليل لصلاة التهجّد' : 'Late-night reminder for the Tahajjud prayer',
                    ),
                    const Divider(height: 1),
                    _DailyReminderTile(
                      reminderKey: 'weeklySummary',
                      title: Localizations.localeOf(context).languageCode == 'ar' ? 'الملخص الأسبوعي' : 'Weekly summary',
                      subtitle: Localizations.localeOf(context).languageCode == 'ar' ? 'تذكير أسبوعي (كل جمعة) لمراجعة إحصائياتك' : 'Weekly reminder (every Friday) to review your stats',
                    ),
                    const Divider(height: 1),
                    _DailyReminderTile(
                      reminderKey: 'backupReminder',
                      title: Localizations.localeOf(context).languageCode == 'ar' ? 'تذكير النسخ الاحتياطي' : 'Backup reminder',
                      subtitle: Localizations.localeOf(context).languageCode == 'ar' ? 'تذكير دوري (كل جمعة) لتصدير نسخة احتياطية من بياناتك' : 'Periodic reminder (every Friday) to export a backup of your data',
                    ),
                    const Divider(height: 1),
                    _DailyReminderTile(reminderKey: 'eveningAzkar', title: l10n.settingsEveningAzkarReminder, subtitle: l10n.settingsEveningAzkarReminderSubtitle),
                    const Divider(height: 1),
                    _DailyReminderTile(reminderKey: 'sleepAzkar', title: l10n.settingsSleepAzkarReminder, subtitle: l10n.settingsSleepAzkarReminderSubtitle),
                    const Divider(height: 1),
                    _DailyReminderTile(reminderKey: 'dailyWird', title: l10n.settingsDailyWirdReminder, subtitle: l10n.settingsDailyWirdReminderSubtitle),
                    const Divider(height: 1),
                    _DailyReminderTile(
                      reminderKey: 'dailyQuote',
                      title: Localizations.localeOf(context).languageCode == 'ar' ? 'آية أو حديث اليوم' : 'Ayah or Hadith of the day',
                      subtitle: Localizations.localeOf(context).languageCode == 'ar'
                          ? 'إشعار يومي بآية أو حديث مختلف (يتحدّث في المرة الجاية اللي تفتحي فيها التطبيق)'
                          : 'A daily notification with a different verse or hadith (refreshes next time you open the app)',
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.settingsDailyWirdTarget),
                      subtitle: Text(l10n.settingsDailyWirdPerDay(_wirdTarget)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _setWirdTarget(_wirdTarget - 1)),
                        Text('$_wirdTarget', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _setWirdTarget(_wirdTarget + 1)),
                      ]),
                    ),
                  ]),
                ),
              ),
                  ],
                ),
              const SizedBox(height: 20),
              _SectionLabel(l10n.settingsDataManagement),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.menu_book_outlined, color: AppColors.mutedText),
                      title: Text(l10n.settingsQuranLastUpdate),
                      subtitle: Text(_formatCacheDate(_quranCachedAt, languageCode, l10n)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.refresh, color: AppColors.primaryEmerald),
                      title: Text(l10n.settingsUpdateNow),
                      subtitle: Text(l10n.settingsRequiresInternet),
                      onTap: () async {
                        await QuranRepository.load(forceRefresh: true);
                        await _loadCacheInfo();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.settingsDataUpdated)),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_outlined, color: AppColors.mutedText),
                      title: Text(l10n.settingsDownloadedAudio),
                      subtitle: Text(_downloadedAudioSize(l10n)),
                      trailing: _downloadedAudioBytes > 0
                          ? TextButton(
                              onPressed: _confirmDeleteAllDownloads,
                              child: Text(l10n.settingsDeleteAll, style: const TextStyle(color: Colors.red)),
                            )
                          : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.upload_file_outlined, color: AppColors.mutedText),
                      title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'تصدير نسخة احتياطية من بياناتي' : 'Export a backup of my data'),
                      onTap: () async {
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        try {
                          final json = await appSettings.exportDataAsJson();
                          final tempDir = await getTemporaryDirectory();
                          final file = File('${tempDir.path}/wirdi_backup_${DateTime.now().millisecondsSinceEpoch}.json');
                          await file.writeAsString(json);
                          if (!mounted) return;
                          await Share.shareXFiles([XFile(file.path)], subject: 'Wirdi Data Backup');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isAr ? 'تعذّر تصدير النسخة الاحتياطية. حاول مرة أخرى.' : 'Could not export backup. Please try again.')),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download_outlined, color: AppColors.mutedText),
                      title: Text(Localizations.localeOf(context).languageCode == 'ar' ? '\u0627\u0633\u062a\u064a\u0631\u0627\u062f\u0020\u0646\u0633\u062e\u0629\u0020\u0627\u062d\u062a\u064a\u0627\u0637\u064a\u0629' : 'Import a backup'),
                      onTap: () async {
                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                        String? jsonContent;
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['json'],
                            withData: true,
                          );
                          if (result == null || result.files.isEmpty) return;
                          final picked = result.files.single;
                          if (picked.bytes != null) {
                            jsonContent = utf8.decode(picked.bytes!);
                          } else if (picked.path != null) {
                            jsonContent = await File(picked.path!).readAsString();
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isAr ? 'تعذّر فتح الملف المختار.' : 'Could not open the selected file.')),
                          );
                          return;
                        }
                        if (jsonContent == null || jsonContent.trim().isEmpty) return;
                        final ok = await appSettings.importDataFromJson(jsonContent.trim());
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isAr
                              ? (ok ? 'تم استعادة البيانات بنجاح' : 'تعذّرت الاستعادة: تأكد من اختيار ملف نسخة احتياطية صحيح (JSON)')
                              : (ok ? 'Data restored successfully' : 'Restore failed: make sure you selected a valid backup (JSON) file'))),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.restart_alt, color: Colors.orange),
                      title: Text(l10n.settingsResetKhatma),
                      subtitle: Text(l10n.settingsResetKhatmaSubtitle),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.settingsResetKhatma),
                            content: Text(l10n.settingsResetKhatmaBody),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.settingsResetKhatmaConfirm)),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await UserProgressService.resetKhatmaProgress();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.settingsKhatmaResetDone)),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(l10n.settingsDeleteLocalData, style: const TextStyle(color: Colors.red)),
                      onTap: _confirmClearData,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: AppColors.mutedText),
                      title: Text(l10n.aboutTitle),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.mutedText),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'الخصوصية وبياناتي' : 'Privacy & my data',
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyCenterScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.mutedText),
                      title: Text(l10n.sourcesLicensesTitle),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SourcesLicensesScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.replay_outlined, color: AppColors.mutedText),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'إعادة عرض الجولة التعريفية' : 'Replay the intro tour',
                      ),
                      onTap: () => Navigator.pushNamed(context, '/onboarding'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.star_outline, color: AppColors.mutedText),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'قيّم التطبيق' : 'Rate the app',
                      ),
                      onTap: () async {
                        final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.wirdi.wirdi');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows the language picker sheet and applies the choice. Uses a
  /// dedicated "was it dismissed or was System default tapped" signal
  /// (a sentinel Locale) since both map to `null` from Navigator.pop
  /// otherwise.
  Future<void> _showLanguageSheet(BuildContext context, AppLocalizations l10n) async {
    // kLanguageNames already carries the correct native display name for
    // ALL 7 supported locales (it's a plain data map, not tied to l10n
    // getters). The previous version used a switch over l10n.languageName_*
    // getters that only existed for ar/de/tr and silently fell back to
    // "English" for fr/es/id -- which is exactly why "English" showed up
    // multiple times in the sheet for languages that aren't English at all.
    String nameFor(Locale locale) => kLanguageNames[locale.languageCode] ?? locale.languageCode;

    final choice = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.8),
            child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(l10n.settingsLanguage, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              RadioListTile<bool>(
                value: true,
                groupValue: appSettings.explicitLocale == null,
                activeColor: AppColors.primaryEmerald,
                title: Text(l10n.settingsLanguageSystem),
                onChanged: (_) => Navigator.pop(sheetContext, const Locale('system')),
              ),
              for (final locale in AppSettings.supportedLocales)
                RadioListTile<bool>(
                  value: true,
                  groupValue: appSettings.explicitLocale?.languageCode == locale.languageCode,
                  activeColor: AppColors.primaryEmerald,
                  title: Text(nameFor(locale)),
                  onChanged: (_) => Navigator.pop(sheetContext, locale),
                ),
              const SizedBox(height: 8),
            ],
              ),
            ),
          ),
        );
      },
    );

    if (choice == null) return; // sheet dismissed without a tap
    if (choice.languageCode == 'system') {
      await appSettings.setLocale(null); // "System default"
    } else {
      await appSettings.setLocale(choice);
    }
  }
}

String _prayerKeyLabel(AppLocalizations l10n, String key) => switch (key) {
  'Fajr' => l10n.prayerFajr,
  'Dhuhr' => l10n.prayerDhuhr,
  'Asr' => l10n.prayerAsr,
  'Maghrib' => l10n.prayerMaghrib,
  'Isha' => l10n.prayerIsha,
  _ => key,
};

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mutedText, fontSize: 13),
      ),
    );
  }
}


class _DailyReminderTile extends StatelessWidget {
  final String reminderKey;
  final String title;
  final String subtitle;
  const _DailyReminderTile({required this.reminderKey, required this.title, required this.subtitle});

  String _formatTime(BuildContext context, int hour, int minute) {
    return TimeOfDay(hour: hour, minute: minute).format(context);
  }

  @override
  Widget build(BuildContext context) {
    final setting = appSettings.dailyReminder(reminderKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: Text(subtitle),
          value: setting.enabled,
          activeTrackColor: AppColors.primaryEmerald,
          onChanged: (value) async {
            final l10n = AppLocalizations.of(context);
            await appSettings.setDailyReminder(reminderKey, setting.copyWith(enabled: value));
            if (value) {
              await NotificationService.requestPermission();
            }
            final result = await DailyReminderScheduler.rescheduleAll(l10n);
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
        ),
        if (setting.enabled)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: setting.hour, minute: setting.minute),
                );
                if (picked == null) return;
                if (!context.mounted) return;
                final l10n = AppLocalizations.of(context);
                await appSettings.setDailyReminder(
                  reminderKey,
                  setting.copyWith(hour: picked.hour, minute: picked.minute),
                );
                unawaited(DailyReminderScheduler.rescheduleAll(l10n));
              },
              icon: const Icon(Icons.access_time_outlined),
              label: Text(_formatTime(context, setting.hour, setting.minute)),
            ),
          ),
      ],
    );
  }
}

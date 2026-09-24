import 'package:flutter/material.dart';

import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

const Map<String, String> _kThemePickerTitle = {
  'ar': 'معاينة الثيمات', 'en': 'Theme Previews', 'de': 'Themenvorschau', 'tr': 'Tema Onizlemeleri',
  'fr': 'Apercus des themes', 'es': 'Vistas previas de temas', 'id': 'Pratinjau Tema',
};
const Map<String, String> _kLight = {'ar': 'فاتح', 'en': 'Light', 'de': 'Hell', 'tr': 'Acik', 'fr': 'Clair', 'es': 'Claro', 'id': 'Terang'};
const Map<String, String> _kDark = {'ar': 'داكن', 'en': 'Dark', 'de': 'Dunkel', 'tr': 'Koyu', 'fr': 'Sombre', 'es': 'Oscuro', 'id': 'Gelap'};
const Map<String, String> _kSystem = {'ar': 'النظام', 'en': 'System', 'de': 'System', 'tr': 'Sistem', 'fr': 'Systeme', 'es': 'Sistema', 'id': 'Sistem'};

String _tp(BuildContext context, Map<String, String> m) {
  final lang = Localizations.localeOf(context).languageCode;
  return m[lang] ?? m['en']!;
}

/// A real, honest preview of each [AppColorTheme] -- a small mock screen
/// (header bar, background, a sample Quran-script line in the theme's
/// own font, and an accent-colored chip) rather than just a name and a
/// tiny color swatch (which is all the existing mini-picker in
/// settings_screen.dart shows). Added as a second, more detailed way to
/// reach the same [AppSettings.setColorTheme] the mini-picker already
/// calls -- both stay in sync automatically since AppSettings is a
/// ChangeNotifier.
class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final isDarkPreview = switch (appSettings.themeMode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        };
        final languageCode = Localizations.localeOf(context).languageCode;
        return Scaffold(
          appBar: AppBar(title: Text(_tp(context, _kThemePickerTitle))),
          body: SafeArea(bottom: true, top: false, child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                  child: _ModeChip(
                    label: _tp(context, _kLight),
                    selected: appSettings.themeMode == ThemeMode.light,
                    onTap: () => appSettings.setThemeMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    label: _tp(context, _kDark),
                    selected: appSettings.themeMode == ThemeMode.dark,
                    onTap: () => appSettings.setThemeMode(ThemeMode.dark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    label: _tp(context, _kSystem),
                    selected: appSettings.themeMode == ThemeMode.system,
                    onTap: () => appSettings.setThemeMode(ThemeMode.system),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              for (final t in AppColorTheme.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ThemePreviewCard(
                    theme: t,
                    isDarkPreview: isDarkPreview,
                    isSelected: appSettings.colorTheme == t,
                    languageCode: languageCode,
                    onTap: () => appSettings.setColorTheme(t),
                  ),
                ),
            ],
          )),
        );
      },
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final AppColorTheme theme;
  final bool isDarkPreview;
  final bool isSelected;
  final String languageCode;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.theme,
    required this.isDarkPreview,
    required this.isSelected,
    required this.languageCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final def = AppTheme.definitions[theme]!;
    final bg = isDarkPreview ? def.darkBackground : def.lightBackground;
    final textColor = isDarkPreview ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? def.primary : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: def.primary.withValues(alpha: 0.25), blurRadius: 10, spreadRadius: 1)]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 40,
            color: def.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              const Text('Wirdi | \u0648\u0631\u062f\u064a', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 18),
            ]),
          ),
          Container(
            color: bg,
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u0647\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0670\u0646\u0650 \u0627\u0644\u0631\u0651\u064e\u062d\u0650\u064a\u0645\u0650',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: def.fontFamily ?? 'AmiriQuran',
                  fontSize: 17,
                  color: textColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: def.accent,
                    borderRadius: BorderRadius.circular(def.cardRadius > 16 ? 16 : def.cardRadius),
                  ),
                  child: const Text('Wird', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ]),
            ]),
          ),
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              def.displayNameFor(languageCode),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryEmerald : Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}

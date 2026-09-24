import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wirdi design tokens, aligned with the current emerald / gold / ivory
/// visual identity reference.
///
/// IMPORTANT: these remain stable theme tokens so existing screens can
/// continue using AppColors directly while the global Material chrome
/// adopts the same visual language.
/// ~240 call sites across ~38 other screens reference
/// AppColors.primaryEmerald / AppColors.goldAccent directly (not via
/// Theme.of(context)) -- changing these into theme-aware values would
/// either require touching every one of those call sites (a large,
/// separate refactor outside this session's scope, right before a
/// release) or silently break every `const Widget(color:
/// AppColors.xyz)` usage among them (Dart requires const values in
/// const contexts). Those specific screens will keep their original
/// emerald/gold accents regardless of the selected [AppColorTheme]
/// until a dedicated follow-up pass updates them to read from
/// Theme.of(context).colorScheme instead. The core app chrome (AppBar,
/// Scaffold background, default Card shape/color, buttons, bottom nav,
/// and any Material3 widget that reads ColorScheme automatically) DOES
/// already fully respond to the selected theme, since MaterialApp's
/// `theme`/`darkTheme` are now built from [AppColorTheme] below.
class AppColors {
  AppColors._();

  static AppColorTheme _currentTheme = AppColorTheme.emerald;

  static void updateCurrentTheme(AppColorTheme theme) {
    _currentTheme = theme;
  }

  static Color get primaryEmerald => AppTheme.definitions[_currentTheme]!.primary;
  static Color get goldAccent => AppTheme.definitions[_currentTheme]!.accent;
  static const lightBackground = Color(0xFFF8F9F6);
  static const darkBackground = Color(0xFF071A17);
  static const darkCard = Color(0xFF102925);
  static const mutedText = Color(0xFF536763);
  static const tajweedQalqalah = Color(0xFFD2691E);
  static const tajweedGhunnah = Color(0xFFE91E8C);
  static const tajweedIkhfa = Color(0xFF5C6BC0);
  static const tajweedIdghamGhunnah = Color(0xFF2E7D32);
  static const tajweedIdghamNoGhunnah = Color(0xFF00897B);
  static const tajweedIqlab = Color(0xFF8E24AA);
}

/// The set of selectable app-wide color themes. `emerald` is the
/// app's primary Wirdi identity: deep emerald, muted teal, gold, and
/// warm ivory, matching the supplied visual identity reference.
enum AppColorTheme { emerald, ocean, ruby, amethyst, manuscript, classicQuran, sageCalm, warmSand, softBlue, pureMinimal }

/// One theme's full visual identity: colors, card shape, and
/// (optionally) a distinct font family. [fontFamily] is null for most
/// themes (falls back to the platform default font, exactly like the
/// app's original 'Cairo' reference already did -- no 'Cairo' font
/// asset is actually bundled in pubspec.yaml, so that name was already
/// a no-op). `manuscript` deliberately reuses the already-bundled
/// 'AmiriQuran' font asset (declared in pubspec.yaml for Quran text)
/// for a distinct classic/calligraphic feel -- no new font asset is
/// introduced, avoiding any packaging/licensing risk right before a
/// release build.
class AppThemeDefinition {
  /// Per-locale display name (keys: ar/en/de/tr/fr/es/id, matching this
  /// app's supported languages). FIX (v105): this used to be a single
  /// hardcoded Arabic string, so the theme picker always showed Arabic
  /// names even when the app's language was set to English/German/etc.
  /// [displayNameFor] falls back to 'en' and finally to the first
  /// available value if a locale is missing.
  final Map<String, String> displayNameByLocale;
  final Color primary;
  final Color accent;
  final Color lightBackground;
  final Color darkBackground;
  final Color darkCard;
  final double cardRadius;
  final String? fontFamily;
  const AppThemeDefinition({
    required this.displayNameByLocale,
    required this.primary,
    required this.accent,
    required this.lightBackground,
    required this.darkBackground,
    required this.darkCard,
    required this.cardRadius,
    this.fontFamily,
  });

  String displayNameFor(String languageCode) =>
      displayNameByLocale[languageCode] ?? displayNameByLocale['en'] ?? displayNameByLocale.values.first;
}

class AppTheme {
  AppTheme._();

  static const Map<AppColorTheme, AppThemeDefinition> definitions = {
    AppColorTheme.emerald: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'زمردي', 'en': 'Emerald', 'de': 'Smaragd', 'tr': 'Zümrüt',
        'fr': 'Émeraude', 'es': 'Esmeralda', 'id': 'Zamrud',
      },
      primary: Color(0xFF0F766E),
      accent: Color(0xFFD4AF37),
      lightBackground: Color(0xFFF8F9F6),
      darkBackground: Color(0xFF071A17),
      darkCard: Color(0xFF102925),
      cardRadius: 20,
    ),
    AppColorTheme.ocean: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'محيطي', 'en': 'Ocean', 'de': 'Ozean', 'tr': 'Okyanus',
        'fr': 'Océan', 'es': 'Océano', 'id': 'Samudra',
      },
      primary: Color(0xFF0369A1),
      accent: Color(0xFF06B6D4),
      lightBackground: Color(0xFFF4FAFD),
      darkBackground: Color(0xFF071A24),
      darkCard: Color(0xFF0E293A),
      cardRadius: 16,
    ),
    AppColorTheme.ruby: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'ياقوتي', 'en': 'Ruby', 'de': 'Rubin', 'tr': 'Yakut',
        'fr': 'Rubis', 'es': 'Rubí', 'id': 'Delima',
      },
      primary: Color(0xFF9F1239),
      accent: Color(0xFFF59E0B),
      lightBackground: Color(0xFFFDF6F6),
      darkBackground: Color(0xFF240A11),
      darkCard: Color(0xFF3A121B),
      cardRadius: 24,
    ),
    AppColorTheme.amethyst: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'بنفسجي', 'en': 'Amethyst', 'de': 'Amethyst', 'tr': 'Ametist',
        'fr': 'Améthyste', 'es': 'Amatista', 'id': 'Kecubung',
      },
      primary: Color(0xFF6D28D9),
      accent: Color(0xFFF472B6),
      lightBackground: Color(0xFFF9F7FD),
      darkBackground: Color(0xFF1A1330),
      darkCard: Color(0xFF271C42),
      cardRadius: 20,
    ),
    AppColorTheme.manuscript: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'مخطوطة كلاسيكية', 'en': 'Manuscript', 'de': 'Manuskript', 'tr': 'El Yazması',
        'fr': 'Manuscrit', 'es': 'Manuscrito', 'id': 'Manuskrip',
      },
      primary: Color(0xFF92400E),
      accent: Color(0xFFD4AF37),
      lightBackground: Color(0xFFFBF6EC),
      darkBackground: Color(0xFF1C140B),
      darkCard: Color(0xFF2B2013),
      cardRadius: 8,
      fontFamily: 'AmiriQuran',
    ),
    // NEW (v126): a full "calm design system" per an explicit design
    // brief -- five deliberately low-saturation, non-neon themes
    // (replacing the earlier ad-hoc v125 "Sage" entry with a more
    // precisely-specified "Sage Calm"), each restricted to the
    // requested palette family (off-white/ivory/cream/warm-gray/sage/
    // muted-green/soft-teal/charcoal/soft-brown) and each with a
    // coordinated dark variant that avoids pure black. Purely
    // additive to the existing theme system -- same
    // AppThemeDefinition shape, same light()/dark() builders below,
    // zero change to any existing theme or to app functionality.
    AppColorTheme.classicQuran: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'القرآن الكلاسيكي', 'en': 'Classic Quran', 'de': 'Klassischer Koran', 'tr': 'Klasik Kuran',
        'fr': 'Coran classique', 'es': 'Corán clásico', 'id': 'Quran Klasik',
      },
      primary: Color(0xFF5F7A61),
      accent: Color(0xFFC9B896),
      lightBackground: Color(0xFFFBF9F4),
      darkBackground: Color(0xFF1E2420),
      darkCard: Color(0xFF2A322C),
      cardRadius: 16,
    ),
    AppColorTheme.sageCalm: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'نعناعي هادئ', 'en': 'Sage Calm', 'de': 'Ruhiger Salbei', 'tr': 'Sakin Adaçayı',
        'fr': 'Sauge apaisante', 'es': 'Salvia tranquila', 'id': 'Sage Tenang',
      },
      primary: Color(0xFF7C9473),
      accent: Color(0xFFB7C4A8),
      lightBackground: Color(0xFFF6F8F4),
      darkBackground: Color(0xFF1B231C),
      darkCard: Color(0xFF232D24),
      cardRadius: 20,
    ),
    AppColorTheme.warmSand: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'رملي دافئ', 'en': 'Warm Sand', 'de': 'Warmer Sand', 'tr': 'Sıcak Kum',
        'fr': 'Sable chaud', 'es': 'Arena cálida', 'id': 'Pasir Hangat',
      },
      primary: Color(0xFFA67C52),
      accent: Color(0xFFD9C7A3),
      lightBackground: Color(0xFFF7F0E3),
      darkBackground: Color(0xFF241C14),
      darkCard: Color(0xFF32271B),
      cardRadius: 14,
    ),
    AppColorTheme.softBlue: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'أزرق هادئ', 'en': 'Soft Blue', 'de': 'Sanftes Blau', 'tr': 'Yumuşak Mavi',
        'fr': 'Bleu doux', 'es': 'Azul suave', 'id': 'Biru Lembut',
      },
      primary: Color(0xFF5B8A93),
      accent: Color(0xFFAFC7CC),
      lightBackground: Color(0xFFF1F5F6),
      darkBackground: Color(0xFF16232A),
      darkCard: Color(0xFF1F2F37),
      cardRadius: 18,
    ),
    AppColorTheme.pureMinimal: AppThemeDefinition(
      displayNameByLocale: {
        'ar': 'بسيط تماماً', 'en': 'Pure Minimal', 'de': 'Rein Minimal', 'tr': 'Saf Minimal',
        'fr': 'Pur minimal', 'es': 'Minimalismo puro', 'id': 'Minimal Murni',
      },
      primary: Color(0xFF6B8F71),
      accent: Color(0xFFDADAD6),
      lightBackground: Color(0xFFFCFCFB),
      darkBackground: Color(0xFF17191A),
      darkCard: Color(0xFF212425),
      cardRadius: 12,
    ),
  };

  static ThemeData light(AppColorTheme theme) {
    final def = definitions[theme]!;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: def.primary,
        brightness: Brightness.light,
        primary: def.primary,
        secondary: def.accent,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: def.lightBackground,
      fontFamily: def.fontFamily ?? GoogleFonts.tajawal().fontFamily,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: def.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(def.cardRadius),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF102925),
        displayColor: const Color(0xFF102925),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: def.primary,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: def.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  static ThemeData dark(AppColorTheme theme) {
    final def = definitions[theme]!;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: def.primary,
        brightness: Brightness.dark,
        primary: def.accent,
        secondary: def.primary,
        surface: def.darkCard,
      ),
      scaffoldBackgroundColor: def.darkBackground,
      fontFamily: def.fontFamily ?? GoogleFonts.tajawal().fontFamily,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: def.darkBackground,
        foregroundColor: def.accent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: def.darkCard,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(def.cardRadius),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: def.darkCard,
        selectedItemColor: def.accent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: def.accent,
          foregroundColor: def.darkBackground,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

# Wirdi v16.1.26 - UI fixes batch 25

Implemented from the user's 11-point list:

1. Global Search: Quran result text now uses the configured Quran font (AmiriQuran by default), RTL direction, larger line height, and theme-aware text color.
2. Home: Islamic tools section is explicitly labeled "الأدوات الإسلامية" in Arabic.
3. Home: dashboard cards use one consistent translucent/elevated visual treatment.
4. Home: Verse of the Day opens Quran at the exact surah and ayah.
5. Quran: Surah and Favorites Quran text uses theme-aware on-surface color for dark mode while retaining the Quran font.
6. Mushaf pages: page-flip mode is SafeArea-aware and the page card fills the available viewport height on phone/tablet without the previous vertical margins.
7. Prayer: moon is larger responsively, with "طور القمر اليوم" and the phase beside it, while constraining the layout to avoid overflow.
8. Azkar & Duas: background image area is taller and the overlay is tuned so the title/content remains readable.
9. Settings: notification sections remain collapsible and are labeled as Notifications / Other notifications for simpler grouping.
10. Moon page: taller background, larger main moon, larger phase thumbnails, and bottom safe-area padding to avoid navigation-bar overlap.
11. Prayer: each prayer now has its own notification switch and per-prayer mode selector: Adhan / Beep / Notification. Changes are persisted through the existing AppSettings and rescheduled through the existing notification scheduler.

Also added `assets/images/generated/` to `pubspec.yaml` because the latest source references the generated mosque asset from that directory.

Note: Flutter SDK is not installed in this execution environment, so a local `flutter analyze` / APK build could not be run here. The changes were kept limited to the relevant UI/settings files and existing services.

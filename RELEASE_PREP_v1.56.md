# Wirdi v1.56.0 (build 22) -- visual identity + Islamic Tools reorganization

Builds on v1.55 (RELEASE_PREP_v1.55.md). As with every previous pass, nothing here
was compiled or run (no Flutter SDK available): run `flutter analyze` and look at
these screens on a device/emulator before shipping.

## Visual identity (design-brief alignment)
- **Colors and fonts already matched the brief exactly** before this pass -- the
  default "Emerald" theme is `#0F766E` / `#D4AF37` / `#F8F9F6` / `#071A17` / `#102925`,
  and the app already uses Tajawal (bundled, no runtime download since v1.54)
  everywhere. No color/font changes were needed or made.
- **New: `WirdiIdentityBackground`** (`lib/shared/widgets/wirdi_identity_background.dart`)
  -- a reusable mosque-skyline-and-crescent illustration (dome, two minarets, stars,
  crescent moon) painted with `CustomPaint` in the app's own brand colors. This is
  the visual-identity asset requested alongside the palette (matching the mood board's
  photographic mosque backgrounds); it's drawn as vector art rather than a photo
  because no image-generation tool was available in this environment -- which also
  means zero licensing/attribution risk, a tiny footprint (no image bytes at all),
  and it renders correctly in both the light and dark theme since it's painted with
  `AppColors`, not baked into a fixed image. Two entry points: default (compact, for
  an AppBar `flexibleSpace`) and `.hero` (taller, for a full-screen banner). The
  proportions were verified by rendering the same geometry at header height, hero
  height, and a very short strip before wiring it into any screen, so it doesn't
  distort at different aspect ratios.
- **Applied to the Home screen's AppBar** (`home_dashboard_screen.dart`): replaced
  the flat 2-color gradient in `flexibleSpace` with `WirdiIdentityBackground`. This
  was an isolated, same-slot swap -- nothing else on the screen (the list below, its
  logic, its data) was touched.
- **Not yet applied to the other ~93 screens.** Rolling this out everywhere in one
  pass was judged too large and too risky to do blind (no compiler available) in a
  single change set. The component is ready to reuse: wrap a screen's `AppBar`
  `flexibleSpace` (compact) or wrap a hero `Stack` at the top of a body (`.hero`) with
  it. Natural next candidates, matching the mood board's own example screens: Qibla,
  Radio "now playing", the Moon-phase screen, and Prayer Times.

## Islamic Tools screen -- reorganized into 8 groups
The 62 tools were one flat scrolling list. They're now grouped by how closely related
they are to a user's daily worship flow, in this display order:

1. القرآن والحفظ / Quran & Memorization (12)
2. الصلاة والقبلة / Prayer & Qibla (11 -- includes Mosque Finder)
3. الصيام ورمضان / Fasting & Ramadan (3)
4. الزكاة والصدقة / Zakat & Charity (6)
5. الأذكار والدعاء / Azkar & Dua (5)
6. المعرفة والحديث / Knowledge & Hadith (10 -- hadith, quizzes, fatwa, articles, etiquette, will)
7. السيرة والتاريخ / Seerah & History (7 -- prophets, history, Hajj/Umrah, Hijri converter, moon phase, Islamic events)
8. التقدم والمزيد / Progress & More (8 -- insights, achievements, bookmarks, My Wirdi, search, radio)

**How it was done safely:** none of the 62 existing `_ToolEntry(...)` blocks (icon,
title, subtitle, and -- critically -- the `builder` that opens the actual screen) were
touched. The category for each tool is a separate, purely-additive list
(`_categoryByIndex`) matched to the existing tools by position, cross-checked
programmatically against an independently-built expected mapping (0 mismatches, 0
missing, all 62 accounted for) before being wired in. A debug-mode assertion in
`_groupedTools()` will fail loudly if a future edit adds or removes a tool without
updating `_categoryByIndex`, instead of silently mis-grouping it. Only the `build()`
method's layout changed, from a flat `ListView.separated` to grouped sections with a
header (icon + bilingual label) per category; the individual tool row's appearance and
`onTap` behavior are byte-for-byte the same widget code as before.

## What was verified vs. not
Verified: every changed and new file parses with zero syntax errors (183 lib files
checked); the 62-tool category mapping was cross-checked against an independent
expected table; the skyline illustration's proportions were checked at three very
different aspect ratios before use. **Not verified:** actual rendering on a device or
in `flutter analyze` -- check that the Home AppBar's title/actions stay legible over
the new background at your test device's text scale, and that the tools screen scrolls
and looks right with real fonts/locale (especially Arabic RTL section headers).


import '../models/radio_station.dart';

/// 10 curated Islamic radio stations embedded directly in the
/// app as an OFFLINE fallback (trimmed down from a previous list of
/// 29 -- 19 entries used human-readable vanity URL
/// slugs like 'kuwait-quran' or 'sunnah' on services (radiojar.com,
/// zeno.fm) that in every VERIFIED case issue only random
/// alphanumeric stream slugs (e.g. Cairo's real one below,
/// '8s5u5tpdtwzuv') -- almost certainly fabricated/guessed rather
/// than real streams, so they were removed rather than risk shipping
/// dead links a user taps expecting audio.
///
/// This is ONLY the first-launch/offline fallback. RadioService
/// already fetches and MERGES up to 100+ more real stations live, in
/// the background, from mp3quran.net + Radio-Browser (tag=quran,
/// limit 100) + data-rosy + the Uthumany Islamic Radio API on every
/// app start with internet access -- removing fabricated entries
/// here does not reduce what users see online, it only fixes what
/// shows if the device is offline on first launch.
const List<RadioStation> kFallbackStations = [

  // ── Egypt ─────────────────────────────────────────────────────────────────
  RadioStation(
    id: 'dr_1',
    nameAr: 'إذاعة القرآن الكريم من القاهرة',
    nameEn: 'Holy Quran Radio Cairo',
    streamUrl: 'https://stream.radiojar.com/8s5u5tpdtwzuv',
    country: 'Egypt', countryCode: 'EG',
    category: 'quran', isOfficial: true,
    imageUrl: 'https://i.postimg.cc/d1kdrLkx/quran.jpg',
  ),
  // NEW (v123): a second, differently-hosted Cairo Quran Radio entry
  // as a backup in case dr_1's original radiojar.com stream slug has
  // gone dead (a common failure mode for these free CDN relay
  // services over time) -- purely additive, dr_1 is left untouched so
  // nothing that already worked can regress. If this one also turns
  // out not to work, tell Sigma and it'll be swapped for a different
  // URL; these could not be connectivity-tested from the sandbox this
  // was written in.
  RadioStation(
    id: 'dr_1b',
    nameAr: 'إذاعة القرآن الكريم من القاهرة (رابط بديل)',
    nameEn: 'Holy Quran Radio Cairo (backup link)',
    streamUrl: 'https://n0a.radiojar.com/8s5u5tpdtwzuv',
    country: 'Egypt', countryCode: 'EG',
    category: 'quran', isOfficial: true,
    imageUrl: 'https://i.postimg.cc/d1kdrLkx/quran.jpg',
  ),

  // ── Saudi Arabia ──────────────────────────────────────────────────────────
  RadioStation(
    id: 'dr_2',
    nameAr: 'إذاعة القرآن الكريم السعودية',
    nameEn: 'Saudi Holy Quran Radio',
    streamUrl: 'https://n12.radiojar.com/0tpy1h0kxtzuv',
    country: 'Saudi Arabia', countryCode: 'SA',
    category: 'quran', isOfficial: true,
    imageUrl: 'https://i.postimg.cc/ZYSprKr8/download.png',
  ),
  RadioStation(
    id: 'dr_3',
    nameAr: 'إذاعة نداء الإسلام — مكة المكرمة',
    nameEn: 'Makkah Radio (Nida Al-Islam)',
    streamUrl: 'https://n09.radiojar.com/4xzg2m50ktzuv',
    country: 'Saudi Arabia', countryCode: 'SA',
    category: 'prayers', isOfficial: true,
    imageUrl: 'https://i.postimg.cc/ZYSprKr8/download.png',
  ),

  // ── Algeria ───────────────────────────────────────────────────────────────
  RadioStation(
    id: 'dr_5',
    nameAr: 'إذاعة القرآن الكريم من الجزائر',
    nameEn: 'Algeria Holy Quran Radio',
    streamUrl: 'https://live.algerian-radio.dz/quran-128k.mp3',
    country: 'Algeria', countryCode: 'DZ',
    category: 'quran', isOfficial: true,
    imageUrl: 'https://i.postimg.cc/d1kdrLkx/quran.jpg',
  ),

  // ── Morocco ───────────────────────────────────────────────────────────────
  RadioStation(
    id: 'dr_6',
    nameAr: 'إذاعة القرآن الكريم من المغرب',
    nameEn: 'Morocco Holy Quran Radio (SNRT)',
    streamUrl: 'https://snrt-live.scdn.co/snrt-quran/index.m3u8',
    country: 'Morocco', countryCode: 'MA',
    category: 'quran', isOfficial: true,
    imageUrl: 'https://i.postimg.cc/d1kdrLkx/quran.jpg',
  ),

  // ── UAE ───────────────────────────────────────────────────────────────────

  // ── Kuwait ────────────────────────────────────────────────────────────────

  // ── Qatar ─────────────────────────────────────────────────────────────────
  RadioStation(
    id: 'dr_9',
    nameAr: 'إذاعة القرآن الكريم — قطر',
    nameEn: 'Qatar Holy Quran Radio',
    streamUrl: 'https://stream.beamstream.net/quranfm',
    country: 'Qatar', countryCode: 'QA',
    category: 'quran', isOfficial: true,
    imageUrl: 'https://i.postimg.cc/d1kdrLkx/quran.jpg',
  ),

  // ── Tunisia ───────────────────────────────────────────────────────────────
  RadioStation(
    id: 'dr_10',
    nameAr: 'إذاعة الزيتونة — تونس',
    nameEn: 'Zitouna FM Tunisia',
    streamUrl: 'https://broadcast.infomaniak.ch/zitouna-high.mp3',
    country: 'Tunisia', countryCode: 'TN',
    category: 'quran', isOfficial: false,
    imageUrl: 'https://i.postimg.cc/d1kdrLkx/quran.jpg',
  ),

  // ── International / Reciters ──────────────────────────────────────────────

  // ── Lectures & Islamic Content ─────────────────────────────────────────────
  RadioStation(
    id: 'dr_15',
    nameAr: 'راديو الإسلام — محاضرات',
    nameEn: 'Islam Radio (Lectures)',
    streamUrl: 'https://stream.zeno.fm/yn65m7h2p9zuv',
    country: 'International', countryCode: 'INT',
    category: 'lectures', isOfficial: false,
    imageUrl: 'https://i.postimg.cc/d1kdrLkx/quran.jpg',
  ),
  RadioStation(
    id: 'dr_16',
    nameAr: 'راديو نور الإسلام',
    nameEn: 'Nour Al-Islam Radio',
    streamUrl: 'https://stream.zeno.fm/hn0m6nh2p9zuv',
    country: 'International', countryCode: 'INT',
    category: 'lectures', isOfficial: false,
    imageUrl: 'https://i.postimg.cc/d1kdrLkx/quran.jpg',
  ),

  // ── Nasheed ───────────────────────────────────────────────────────────────

  // ── Jordan ──────────────────────────────────────────────────────

  // ── Sudan ───────────────────────────────────────────────────────

  // ── Bahrain ─────────────────────────────────────────────────────

  // ── Oman ────────────────────────────────────────────────────────

  // ── Palestine ───────────────────────────────────────────────────

  // ── Yemen ───────────────────────────────────────────────────────

  // ── Pakistan ────────────────────────────────────────────────────

  // ── Turkey ──────────────────────────────────────────────────────

  // ── Indonesia ───────────────────────────────────────────────────

  // ── Malaysia ────────────────────────────────────────────────────
];

/// Category labels in all 7 supported languages
const Map<String, Map<String, String>> kRadioCategories = {
  'quran':    {'ar':'القرآن الكريم','en':'Holy Quran','de':'Heiliger Quran','tr':'Kutsal Kuran','fr':'Saint Coran','es':'Sagrado Corán','id':'Al-Quran'},
  'prayers':  {'ar':'الصلوات المباشرة','en':'Live Prayers','de':'Live-Gebete','tr':'Canlı Namaz','fr':'Prières en direct','es':'Oraciones en vivo','id':'Shalat Langsung'},
  'lectures': {'ar':'محاضرات ودروس','en':'Lectures','de':'Vorlesungen','tr':'Dersler','fr':'Conférences','es':'Conferencias','id':'Ceramah'},
  'nasheed':  {'ar':'أناشيد إسلامية','en':'Nasheed','de':'Nasheed','tr':'Neşid','fr':'Nasheed','es':'Nasheed','id':'Nasyid'},
};

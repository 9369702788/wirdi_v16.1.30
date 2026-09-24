import 'package:flutter/material.dart';

import '../../core/models/bookmark_models.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/services/quran_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quran/quran_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<BookmarkEntry> _bookmarks = [];
  bool _loading = true;
  String? _filterCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final bookmarks = await BookmarkService.allBookmarks();
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _loading = false;
    });
  }

  static Color _categoryColor(String category) {
    switch (category) {
      case 'ramadan':
        return Colors.purple;
      case 'dua':
        return AppColors.primaryEmerald;
      case 'family':
        return Colors.pink;
      case 'study':
        return Colors.blue;
      case 'personal':
        return AppColors.goldAccent;
      default:
        return AppColors.mutedText;
    }
  }

  String _categoryLabel(AppLocalizations l10n, String category) {
    switch (category) {
      case 'ramadan':
        return l10n.bookmarkCategoryRamadan;
      case 'dua':
        return l10n.bookmarkCategoryDua;
      case 'family':
        return l10n.bookmarkCategoryFamily;
      case 'study':
        return l10n.bookmarkCategoryStudy;
      case 'personal':
        return l10n.bookmarkCategoryPersonal;
      default:
        return l10n.bookmarkCategoryOther;
    }
  }

  Future<void> _showContext(BookmarkEntry bookmark) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => FutureBuilder(
        future: QuranRepository.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())));
          }
          final allSurahs = snapshot.data!;
          final surah = allSurahs.where((s) => s.number == bookmark.surahNumber).toList();
          if (surah.isEmpty) {
            return AlertDialog(
              content: Text(isAr ? 'تعذر تحميل سياق الآية' : 'Could not load verse context'),
              actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(isAr ? 'إغلاق' : 'Close'))],
            );
          }
          final ayahs = surah.first.ayahs;
          final index = ayahs.indexWhere((a) => a.number == bookmark.ayahNumber);
          if (index == -1) {
            return AlertDialog(
              content: Text(isAr ? 'تعذر إيجاد الآية' : 'Could not find the verse'),
              actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(isAr ? 'إغلاق' : 'Close'))],
            );
          }
          final start = (index - 1).clamp(0, ayahs.length - 1);
          final end = (index + 1).clamp(0, ayahs.length - 1);
          return AlertDialog(
            title: Text('${bookmark.surahName} \u2022 ${bookmark.ayahNumber}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = start; i <= end; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        ayahs[i].text,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: i == index ? FontWeight.bold : FontWeight.normal,
                          color: i == index ? AppColors.primaryEmerald : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(isAr ? 'إغلاق' : 'Close'))],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BookmarkEntry bookmark) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bookmarkDeleteConfirmTitle),
        content: Text(l10n.bookmarkDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l10n.bookmarkDeleteConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    await BookmarkService.deleteBookmark(bookmark.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _searchQuery.trim().toLowerCase();
    final visible = _bookmarks.where((b) {
      final matchesCategory = _filterCategory == null || b.category == _filterCategory;
      final matchesSearch = query.isEmpty ||
          b.ayahText.toLowerCase().contains(query) ||
          b.surahName.toLowerCase().contains(query) ||
          b.note.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookmarksTitle), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_bookmarks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.commonSearch,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _searchController.clear(),
                              ),
                        isDense: true,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                if (_bookmarks.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(l10n.bookmarkCategoryOther),
                            selected: _filterCategory == null,
                            onSelected: (_) => setState(() => _filterCategory = null),
                          ),
                        ),
                        for (final category in BookmarkService.categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_categoryLabel(l10n, category)),
                              selected: _filterCategory == category,
                              onSelected: (_) => setState(() => _filterCategory = category),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bookmark_border, size: 48, color: AppColors.mutedText),
                                const SizedBox(height: 12),
                                Text(l10n.bookmarksEmptyTitle, style: const TextStyle(color: AppColors.mutedText)),
                                const SizedBox(height: 8),
                                Text(l10n.bookmarksEmptySubtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final bookmark = visible[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuranScreen(initialSurahNumber: bookmark.surahNumber, initialAyah: bookmark.ayahNumber),
                                  ),
                                ),
                                title: Text(
                                  '${bookmark.surahName} • ${bookmark.ayahNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (bookmark.note.trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(bookmark.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                    const SizedBox(height: 4),
                                    Chip(
                                      label: Text(_categoryLabel(l10n, bookmark.category), style: TextStyle(fontSize: 11, color: _categoryColor(bookmark.category))),
                                      backgroundColor: _categoryColor(bookmark.category).withValues(alpha: 0.12),
                                      side: BorderSide(color: _categoryColor(bookmark.category).withValues(alpha: 0.4)),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Context',
                                      icon: Icon(Icons.menu_book_outlined, color: AppColors.primaryEmerald),
                                      onPressed: () => _showContext(bookmark),
                                    ),
                                    IconButton(
                                      tooltip: l10n.commonDeleteTooltip,
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _confirmDelete(bookmark),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            )),
    );
  }
}

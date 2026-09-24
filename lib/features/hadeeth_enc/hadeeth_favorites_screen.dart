import 'package:flutter/material.dart';

import '../../core/models/hadeeth_enc_models.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import 'hadeeth_detail_screen.dart';

String _t(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class HadeethFavoritesScreen extends StatefulWidget {
  const HadeethFavoritesScreen({super.key});

  @override
  State<HadeethFavoritesScreen> createState() => _HadeethFavoritesScreenState();
}

class _HadeethFavoritesScreenState extends State<HadeethFavoritesScreen> {
  List<String> _favoriteIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favorites = await UserProgressService.favoriteHadiths();
    final ids = favorites
        .where((uid) => uid.startsWith('hadeethenc_'))
        .map((uid) => uid.substring('hadeethenc_'.length))
        .toList();
    if (mounted) {
      setState(() {
        _favoriteIds = ids;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'الأحاديث المفضلة', 'Favorite hadith')), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteIds.isEmpty
              ? Center(child: Text(_t(context, "لم تحفظ أي حديث بعد.", "You haven't saved any hadith yet.")))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favoriteIds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final id = _favoriteIds[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.star, color: AppColors.goldAccent),
                          title: Text(_t(context, 'حديث محفوظ رقم $id', 'Saved hadith #$id')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HadeethDetailScreen(summary: HadeethSummaryModel(id: id, title: '')),
                            ),
                          ).then((_) => _load()),
                        ),
                      );
                    },
                  ),
                )),
    );
  }
}

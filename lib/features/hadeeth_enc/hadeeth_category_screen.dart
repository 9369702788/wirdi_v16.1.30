import 'package:flutter/material.dart';

import '../../core/models/hadeeth_enc_models.dart';
import '../../core/services/hadeeth_enc_repository.dart';
import '../../core/theme/app_theme.dart';
import 'hadeeth_attribution.dart';
import 'hadeeth_detail_screen.dart';

String _t(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class HadeethCategoryScreen extends StatefulWidget {
  final HadeethCategoryModel category;
  const HadeethCategoryScreen({super.key, required this.category});

  @override
  State<HadeethCategoryScreen> createState() => _HadeethCategoryScreenState();
}

class _HadeethCategoryScreenState extends State<HadeethCategoryScreen> {
  Future<List<HadeethSummaryModel>>? _future;
  String? _loadedForLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedForLanguageCode != languageCode) {
      _loadedForLanguageCode = languageCode;
      _future = HadeethEncRepository.getHadeethsForCategory(categoryId: widget.category.id, languageCode: languageCode);
    }
  }

  Future<void> _refresh() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final future = HadeethEncRepository.getHadeethsForCategory(
      categoryId: widget.category.id,
      languageCode: languageCode,
      forceRefresh: true,
    );
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HadeethSummaryModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _t(context, "تعذّر تحميل أحاديث هذا التصنيف.", "Could not load this category's hadith."),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: _refresh, child: Text(_t(context, 'إعادة المحاولة', 'Retry'))),
                      ],
                    ),
                  ),
                ],
              );
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return Center(child: Text(_t(context, 'لا توجد أحاديث في هذا التصنيف بعد.', 'No hadith in this category yet.')));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == items.length) return const HadeethAttributionFooter();
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.format_quote, color: AppColors.primaryEmerald),
                    title: Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.4)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HadeethDetailScreen(summary: item)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      )),
    );
  }
}

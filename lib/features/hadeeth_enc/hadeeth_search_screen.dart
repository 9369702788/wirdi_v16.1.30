import 'package:flutter/material.dart';

import '../../core/models/hadeeth_enc_models.dart';
import '../../core/services/hadeeth_enc_repository.dart';
import '../../core/theme/app_theme.dart';
import 'hadeeth_detail_screen.dart';

String _t(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class HadeethSearchScreen extends StatefulWidget {
  const HadeethSearchScreen({super.key});

  @override
  State<HadeethSearchScreen> createState() => _HadeethSearchScreenState();
}

class _HadeethSearchScreenState extends State<HadeethSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<HadeethSummaryModel> _results = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    final languageCode = Localizations.localeOf(context).languageCode;
    setState(() {
      _searching = true;
      _searched = true;
    });
    final results = await HadeethEncRepository.search(query: query, languageCode: languageCode);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _runSearch(),
          decoration: InputDecoration(
            hintText: _t(context, 'ابحث في الأحاديث...', 'Search hadith...'),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _runSearch),
        ],
      ),
      body: SafeArea(bottom: true, top: false, child: _searching
          ? const Center(child: CircularProgressIndicator())
          : !_searched
              ? Center(child: Text(_t(context, 'اكتب كلمة وابحث في مكتبة الأحاديث', 'Type a word to search the hadith library')))
              : _results.isEmpty
                  ? Center(child: Text(_t(context, 'لا توجد نتائج', 'No results')))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.format_quote, color: AppColors.primaryEmerald),
                            title: Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => HadeethDetailScreen(summary: item)),
                            ),
                          ),
                        );
                      },
                    )),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/services/articles_service.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final articles = ArticlesService.articles;
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'مقالات إسلامية' : 'Islamic Articles'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = articles[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Text(isAr ? a.titleAr : a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(isAr ? a.contentAr : a.content, maxLines: 3, overflow: TextOverflow.ellipsis)),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(isAr ? a.titleAr : a.title),
                  content: SingleChildScrollView(child: Text(isAr ? a.contentAr : a.content)),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إغلاق' : 'Close'))],
                ),
              ),
            ),
          );
        },
      )),
    );
  }
}

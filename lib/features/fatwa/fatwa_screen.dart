import 'package:flutter/material.dart';
import '../../core/services/fatwa_service.dart';
import '../../core/theme/app_theme.dart';

class FatwaScreen extends StatefulWidget {
  const FatwaScreen({super.key});
  @override
  State<FatwaScreen> createState() => _FatwaScreenState();
}

class _FatwaScreenState extends State<FatwaScreen> {
  List<FatwaRuling> _rulings = [];
  String? _filterCategory;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final rulings = await FatwaService.getAll();
    if (!mounted) return;
    setState(() { _rulings = rulings; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final visible = _filterCategory == null ? _rulings : _rulings.where((r) => r.category == _filterCategory).toList();
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'الأحكام الفقهية العامة' : 'General Rulings'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.goldAccent.withValues(alpha: 0.1),
                child: Text(
                  isAr ? 'ملخصات تعليمية عامة وليست فتاوى، وقد تختلف المذاهب في بعض المسائل. لحالتك الخاصة اسأل عالمًا مؤهلًا.' : 'General educational summaries, not fatwas. The schools of thought differ on some points. For your specific situation, consult a qualified scholar.',
                  style: const TextStyle(fontSize: 12), textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(isAr ? 'الكل' : 'All'), selected: _filterCategory == null, onSelected: (_) => setState(() => _filterCategory = null))),
                    for (final cat in FatwaService.categories)
                      Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(isAr ? _rulings.firstWhere((r) => r.category == cat, orElse: () => _rulings.first).categoryAr : cat), selected: _filterCategory == cat, onSelected: (_) => setState(() => _filterCategory = cat))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = visible[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Chip(label: Text(isAr ? r.categoryAr : r.category, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                          const SizedBox(height: 8),
                          Text(isAr ? r.questionAr : r.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 8),
                          Text(isAr ? r.answerAr : r.answer, style: const TextStyle(fontSize: 13, height: 1.5)),
                          const SizedBox(height: 8),
                          Text('${r.scholar} \u2022 ${r.source}', style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ])),
    );
  }
}

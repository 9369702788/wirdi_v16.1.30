import 'package:flutter/material.dart';

import '../../core/services/hajj_umrah_guide.dart';
import '../../core/theme/app_theme.dart';

/// Shows the Hajj & Umrah guide split into two tabs -- "Umrah rituals"
/// (just the steps an Umrah actually requires: Ihram, Tawaf, Sa'i,
/// Halq/Taqsir, and the farewell Tawaf) and "Hajj rituals" (the full
/// sequence, since Hajj includes everything Umrah does plus the
/// Hajj-specific stages). Each tab renumbers its own steps starting
/// from 1, instead of showing the underlying master list's shared step
/// numbers, which would otherwise look confusingly non-sequential
/// within a single ritual (e.g. Umrah jumping straight from step 3 to
/// step 9).
class HajjUmrahGuideScreen extends StatefulWidget {
  const HajjUmrahGuideScreen({super.key});

  @override
  State<HajjUmrahGuideScreen> createState() => _HajjUmrahGuideScreenState();
}

class _HajjUmrahGuideScreenState extends State<HajjUmrahGuideScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MapEntry<String, dynamic>> _allStepsSorted() {
    final steps = HajjUmrahGuide.hajjSteps.entries.toList()
      ..sort((a, b) {
        final av = a.value as Map<String, dynamic>;
        final bv = b.value as Map<String, dynamic>;
        return (av['step'] as int).compareTo(bv['step'] as int);
      });
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final all = _allStepsSorted();
    // Umrah's own ritual sequence: only steps marked 'umrah' or 'both'.
    final umrahSteps = all.where((e) {
      final type = (e.value as Map<String, dynamic>)['type'] as String? ?? 'both';
      return type == 'umrah' || type == 'both';
    }).toList();
    // Hajj includes everything -- its own stages plus the shared
    // Umrah-style rituals performed as part of it.
    final hajjSteps = all;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'دليل الحج والعمرة' : 'Hajj & Umrah Guide'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isAr ? 'مناسك العمرة' : 'Umrah Rituals'),
            Tab(text: isAr ? 'مناسك الحج' : 'Hajj Rituals'),
          ],
        ),
      ),
      body: SafeArea(bottom: true, top: false, child: TabBarView(
        controller: _tabController,
        children: [
          _StepsList(steps: umrahSteps, isAr: isAr),
          _StepsList(steps: hajjSteps, isAr: isAr),
        ],
      )),
    );
  }
}

class _StepsList extends StatelessWidget {
  final List<MapEntry<String, dynamic>> steps;
  final bool isAr;
  const _StepsList({required this.steps, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = steps[index];
        final data = entry.value as Map<String, dynamic>;
        final duas = ((isAr ? data['duasAr'] : data['duas']) as List<dynamic>?)?.cast<String>() ?? const <String>[];
        final name = isAr ? (data['nameAr'] as String? ?? entry.key) : (entry.key.isEmpty ? entry.key : (entry.key[0].toUpperCase() + entry.key.substring(1)));
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(isAr ? (data['descriptionAr'] as String? ?? '${data['description']}') : '${data['description']}', style: const TextStyle(fontSize: 13)),
                      if (duas.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (final d in duas)
                          Text(
                            d,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.mutedText),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

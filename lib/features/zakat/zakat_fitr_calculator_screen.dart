import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ZakatFitrCalculatorScreen extends StatefulWidget {
  const ZakatFitrCalculatorScreen({super.key});

  @override
  State<ZakatFitrCalculatorScreen> createState() => _ZakatFitrCalculatorScreenState();
}

class _ZakatFitrCalculatorScreenState extends State<ZakatFitrCalculatorScreen> {
  final _membersController = TextEditingController(text: '1');
  final _pricePerPersonController = TextEditingController();
  double? _total;

  @override
  void dispose() {
    _membersController.dispose();
    _pricePerPersonController.dispose();
    super.dispose();
  }

  void _calculate() {
    final members = int.tryParse(_membersController.text.trim()) ?? 0;
    final price = double.tryParse(_pricePerPersonController.text.trim()) ?? 0;
    setState(() => _total = members * price);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'حاسبة زكاة الفطر' : 'Zakat al-Fitr Calculator'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Text(
              isAr
                  ? 'زكاة الفطر واجبة على كل مسلم قادر (عن نفسه وعن من يعول)، وتُخرج قبل صلاة العيد. المقدار الشرعي صاع من طعام (نحو 2.5-3 كجم)، ويجوز إخراج قيمتها نقدًا بسعر الطعام المحلي. أدخل السعر المحلي الحالي للفرد الواحد.'
                  : 'Zakat al-Fitr is obligatory on every capable Muslim (for themselves and their dependents), paid before the Eid prayer. The prescribed amount is one sa\' of staple food (roughly 2.5-3 kg), or its cash equivalent at local prices. Enter the current local price per person.',
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(isAr ? 'عدد أفراد الأسرة' : 'Number of household members', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _membersController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 16),
          Text(isAr ? 'السعر المحلي للفرد الواحد' : 'Local price per person', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _pricePerPersonController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate_outlined), label: Text(isAr ? 'احسب' : 'Calculate')),
          if (_total != null) ...[
            const SizedBox(height: 20),
            Card(
              color: AppColors.primaryEmerald.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(_total!.toStringAsFixed(2), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                    Text(isAr ? 'إجمالي زكاة الفطر المطلوبة' : 'Total Zakat al-Fitr due', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  ],
                ),
              ),
            ),
          ],
        ],
      )),
    );
  }
}

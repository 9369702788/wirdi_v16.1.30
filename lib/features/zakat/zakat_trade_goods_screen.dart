import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ZakatTradeGoodsScreen extends StatefulWidget {
  const ZakatTradeGoodsScreen({super.key});
  @override
  State<ZakatTradeGoodsScreen> createState() => _ZakatTradeGoodsScreenState();
}

class _ZakatTradeGoodsScreenState extends State<ZakatTradeGoodsScreen> {
  final _inventoryController = TextEditingController();
  final _cashController = TextEditingController();
  final _receivablesController = TextEditingController();
  final _debtsController = TextEditingController();
  final _nisabController = TextEditingController();
  double? _zakatDue;
  @override
  void dispose() { _inventoryController.dispose(); _cashController.dispose(); _receivablesController.dispose(); _debtsController.dispose(); _nisabController.dispose(); super.dispose(); }
  void _calculate() {
    final inventory = double.tryParse(_inventoryController.text.trim()) ?? 0;
    final cash = double.tryParse(_cashController.text.trim()) ?? 0;
    final receivables = double.tryParse(_receivablesController.text.trim()) ?? 0;
    final debts = double.tryParse(_debtsController.text.trim()) ?? 0;
    final nisab = double.tryParse(_nisabController.text.trim()) ?? 0;
    final net = inventory + cash + receivables - debts;
    setState(() => _zakatDue = net >= nisab && nisab > 0 ? net * 0.025 : 0);
  }
  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'زكاة عروض التجارة' : 'Zakat on Trade Goods'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Text(
            isAr
                ? 'تُقيَّم البضاعة المعروضة للبيع بسعر السوق الحالي وقت وجوب الزكاة، وتُضاف إليها النقد والديون المرجوة، وتُطرح الديون المستحقة عليك، ثم تُخرج 2.5% من الصافي إن بلغ النصاب.'
                : 'Trade goods are valued at market price when Zakat is due, plus cash and expected receivables, minus debts owed. 2.5% of the net is due if it reaches the nisab.',
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        const SizedBox(height: 20),
        Text(isAr ? 'قيمة البضاعة الحالية' : 'Current inventory value', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _inventoryController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 16),
        Text(isAr ? 'النقد المتوفر في التجارة' : 'Cash on hand', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _cashController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 16),
        Text(isAr ? 'ديون مرجوة لك' : 'Receivables', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _receivablesController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 16),
        Text(isAr ? 'ديون مستحقة عليك' : 'Debts you owe', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _debtsController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 16),
        Text(isAr ? 'قيمة النصاب الحالية' : 'Current nisab value', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(controller: _nisabController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate_outlined), label: Text(isAr ? 'احسب' : 'Calculate')),
        if (_zakatDue != null) ...[
          const SizedBox(height: 20),
          Card(
            color: AppColors.primaryEmerald.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text(_zakatDue!.toStringAsFixed(2), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                Text(isAr ? 'زكاة عروض التجارة المستحقة' : 'Zakat on trade goods due', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ]),
            ),
          ),
        ],
      ])),
    );
  }
}

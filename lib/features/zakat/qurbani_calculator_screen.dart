import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class QurbaniCalculatorScreen extends StatefulWidget {
  const QurbaniCalculatorScreen({super.key});

  @override
  State<QurbaniCalculatorScreen> createState() => _QurbaniCalculatorScreenState();
}

class _QurbaniCalculatorScreenState extends State<QurbaniCalculatorScreen> {
  bool _isCowOrCamel = false;
  final _sharesNeededController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  double? _result;
  int? _animalsNeeded;

  @override
  void dispose() {
    _sharesNeededController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final sharesNeeded = int.tryParse(_sharesNeededController.text.trim()) ?? 0;
    final pricePerAnimal = double.tryParse(_priceController.text.trim()) ?? 0;
    final sharesPerAnimal = _isCowOrCamel ? 7 : 1;
    final animals = (sharesNeeded / sharesPerAnimal).ceil();
    setState(() {
      _animalsNeeded = animals;
      _result = animals * pricePerAnimal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'الأضحية والعقيقة' : 'Qurbani & Aqiqah'), centerTitle: true),
      body: SafeArea(bottom: true, top: false, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'الأضحية (عيد الأضحى)' : 'Qurbani (Eid al-Adha)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'الشاة أو الماعز تجزئ عن شخص واحد. البقرة أو الجمل يجزئ عن 7 أشخاص كحد أقصى.'
                        : 'A sheep or goat counts as one share. A cow or camel can be split among up to 7 shares.',
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isAr ? 'العقيقة (عن المولود)' : 'Aqiqah (for a newborn)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'السنة شاتان عن المولود الذكر، وشاة واحدة عن المولودة الأنثى، وتُستحب في اليوم السابع من الولادة.'
                        : 'The Sunnah is two sheep/goats for a baby boy, and one for a baby girl, ideally on the 7th day after birth.',
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(isAr ? 'حاسبة الأنصبة' : 'Share calculator', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isCowOrCamel,
            title: Text(isAr ? 'بقرة أو جمل (7 أنصبة للحيوان الواحد)' : 'Cow or camel (7 shares per animal)'),
            onChanged: (v) => setState(() => _isCowOrCamel = v),
          ),
          const SizedBox(height: 8),
          Text(isAr ? 'عدد الأنصبة المطلوبة' : 'Number of shares needed', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _sharesNeededController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 16),
          Text(isAr ? 'سعر الحيوان الواحد محليًا' : 'Local price per animal', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate_outlined), label: Text(isAr ? 'احسب' : 'Calculate')),
          if (_result != null) ...[
            const SizedBox(height: 20),
            Card(
              color: AppColors.primaryEmerald.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('$_animalsNeeded', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                    Text(isAr ? 'عدد الحيوانات المطلوبة' : 'Animals needed', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                    const SizedBox(height: 10),
                    Text(_result!.toStringAsFixed(2), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                    Text(isAr ? 'التكلفة التقريبية الإجمالية' : 'Approximate total cost', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
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

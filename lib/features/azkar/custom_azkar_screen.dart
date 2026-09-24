import 'package:flutter/material.dart';
import '../../core/services/custom_azkar_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

class CustomAzkarScreen extends StatefulWidget {
  const CustomAzkarScreen({super.key});
  @override
  State<CustomAzkarScreen> createState() => _CustomAzkarScreenState();
}

class _CustomAzkarScreenState extends State<CustomAzkarScreen> {
  List<CustomAzkarItem> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await CustomAzkarService.getAll();
    if (!mounted) return;
    setState(() { _items = items; _loading = false; });
  }

  Future<void> _addItem() async {
    final result = await showDialog<_NewAzkarInput>(context: context, builder: (context) => const _AddCustomAzkarDialog());
    if (result != null) { await CustomAzkarService.add(result.text, result.target); _load(); }
  }

  Future<void> _increment(String id) async { await CustomAzkarService.increment(id); _load(); }
  Future<void> _reset(String id) async { await CustomAzkarService.resetCount(id); _load(); }
  Future<void> _delete(String id) async { await CustomAzkarService.delete(id); _load(); }

  Future<void> _toggleReminder(String id) async {
    if (appSettings.customAzkarReminders.contains(id)) {
      await appSettings.removeCustomAzkarReminder(id);
    } else {
      await appSettings.addCustomAzkarReminder(id);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? '\u0623\u0630\u0643\u0627\u0631\u064a \u0627\u0644\u062e\u0627\u0635\u0629' : 'My Custom Azkar'), centerTitle: true),
      floatingActionButton: FloatingActionButton(onPressed: _addItem, child: const Icon(Icons.add)),
      body: SafeArea(bottom: true, top: false, child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(isAr ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u0623\u0630\u0643\u0627\u0631 \u0628\u0639\u062f. \u0627\u0636\u063a\u0637 + \u0644\u0625\u0636\u0627\u0641\u0629 \u0630\u0643\u0631\u0643 \u0627\u0644\u062e\u0627\u0635' : 'No custom azkar yet. Tap + to create your own', style: const TextStyle(color: AppColors.mutedText)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final done = item.currentCount >= item.targetCount;
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _delete(item.id),
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: done ? AppColors.primaryEmerald.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.text, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Text('${item.currentCount}/${item.targetCount}', style: TextStyle(color: done ? AppColors.primaryEmerald : AppColors.mutedText, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            IconButton(icon: Icon(appSettings.customAzkarReminders.contains(item.id) ? Icons.notifications_active : Icons.notifications_none, size: 20, color: appSettings.customAzkarReminders.contains(item.id) ? AppColors.primaryEmerald : null), onPressed: () => _toggleReminder(item.id)),
                            IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => _reset(item.id)),
                            FilledButton.icon(
                              onPressed: done ? null : () => _increment(item.id),
                              icon: Icon(done ? Icons.check : Icons.add, size: 18),
                              label: Text(done ? (isAr ? '\u062a\u0645' : 'Done') : '+1'),
                            ),
                          ]),
                        ]),
                      ),
                    );
                  },
                )),
    );
  }
}

class _NewAzkarInput {
  final String text;
  final int target;
  const _NewAzkarInput(this.text, this.target);
}

class _AddCustomAzkarDialog extends StatefulWidget {
  const _AddCustomAzkarDialog();
  @override
  State<_AddCustomAzkarDialog> createState() => _AddCustomAzkarDialogState();
}

class _AddCustomAzkarDialogState extends State<_AddCustomAzkarDialog> {
  final _textController = TextEditingController();
  final _targetController = TextEditingController(text: '100');

  @override
  void dispose() { _textController.dispose(); _targetController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return AlertDialog(
      title: Text(isAr ? '\u0630\u0643\u0631 \u062c\u062f\u064a\u062f' : 'New dhikr'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _textController, textDirection: TextDirection.rtl, decoration: InputDecoration(labelText: isAr ? '\u0646\u0635 \u0627\u0644\u0630\u0643\u0631' : 'Dhikr text')),
          const SizedBox(height: 12),
          TextField(controller: _targetController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isAr ? '\u0639\u062f\u062f \u0627\u0644\u0645\u0631\u0627\u062a \u0627\u0644\u0645\u0633\u062a\u0647\u062f\u0641' : 'Target repeat count')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? '\u0625\u0644\u063a\u0627\u0621' : 'Cancel')),
        FilledButton(
          onPressed: () {
            final text = _textController.text.trim();
            if (text.isEmpty) return;
            final target = int.tryParse(_targetController.text) ?? 100;
            Navigator.pop(context, _NewAzkarInput(text, target.clamp(1, 10000)));
          },
          child: Text(isAr ? '\u062d\u0641\u0638' : 'Save'),
        ),
      ],
    );
  }
}

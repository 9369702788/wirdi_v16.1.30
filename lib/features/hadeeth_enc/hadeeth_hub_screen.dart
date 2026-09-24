import 'package:flutter/material.dart';

import '../../core/models/hadeeth_enc_models.dart';
import '../../core/services/hadeeth_enc_repository.dart';
import '../../core/theme/app_theme.dart';
import '../hadith/hadith_collection_screen.dart';
import 'hadeeth_attribution.dart';
import 'hadeeth_category_screen.dart';
import 'hadeeth_favorites_screen.dart';
import 'hadeeth_search_screen.dart';

String _t(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class HadeethHubScreen extends StatefulWidget {
  const HadeethHubScreen({super.key});

  @override
  State<HadeethHubScreen> createState() => _HadeethHubScreenState();
}

class _HadeethHubScreenState extends State<HadeethHubScreen> {
  Future<List<HadeethCategoryModel>>? _future;
  String? _loadedForLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_loadedForLanguageCode != languageCode) {
      _loadedForLanguageCode = languageCode;
      _future = HadeethEncRepository.getCategories(languageCode: languageCode);
    }
  }

  Future<void> _refresh() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final future = HadeethEncRepository.getCategories(languageCode: languageCode, forceRefresh: true);
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'الأحاديث النبوية', 'Prophetic Hadith')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: _t(context, 'بحث في الأحاديث', 'Search hadith'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadeethSearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.star_outline),
            tooltip: _t(context, 'المفضلة', 'Favorites'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadeethFavoritesScreen())),
          ),
        ],
      ),
      body: SafeArea(bottom: true, top: false, child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HadeethCategoryModel>>(
          future: _future,
          builder: (context, snapshot) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(Icons.looks_one_outlined, color: AppColors.primaryEmerald),
                    title: Text(_t(context, 'الأربعين النووية', 'The Forty Hadith of an-Nawawi')),
                    subtitle: Text(_t(context, 'المجموعة المختصرة الأصلية في وردي', "Wirdi's original compact collection")),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithCollectionScreen())),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t(context, 'موسوعة الأحاديث (HadeethEnc)', 'Hadith Encyclopedia (HadeethEnc)'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError || snapshot.data == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          _t(context, 'تعذّر تحميل التصنيفات. تحقّق من الإنترنت وحاول مرة أخرى.',
                              'Could not load categories. Check your connection and try again.'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: _refresh, child: Text(_t(context, 'إعادة المحاولة', 'Retry'))),
                      ],
                    ),
                  )
                else if (snapshot.data!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_t(context, 'لا توجد تصنيفات متاحة حاليًا.', 'No categories available right now.')),
                  )
                else
                  ...snapshot.data!.map(
                    (category) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.menu_book_outlined, color: AppColors.goldAccent),
                        title: Text(category.title),
                        subtitle: Text(_t(context, '${category.hadeethsCount} حديث', '${category.hadeethsCount} hadith')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HadeethCategoryScreen(category: category)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const HadeethAttributionFooter(),
              ],
            );
          },
        ),
      )),
    );
  }
}

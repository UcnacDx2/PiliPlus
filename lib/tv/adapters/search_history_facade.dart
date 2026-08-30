import 'package:shared_preferences/shared_preferences.dart';

abstract final class SearchHistoryFacade {
  static SharedPreferences? _prefs;
  static Future<void> init() async => _prefs ??= await SharedPreferences.getInstance();
  static List<String> getAll() => _prefs?.getStringList('tv_search_history') ?? const [];
  static Future<void> add(String value) async { await init(); final list = getAll().where((e) => e != value).toList()..insert(0, value); await _prefs!.setStringList('tv_search_history', list.take(10).toList()); }
  static Future<void> clear() async { await init(); await _prefs!.remove('tv_search_history'); }
}

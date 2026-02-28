import 'package:shared_preferences/shared_preferences.dart';

/// Thin persistence layer for favorite recipe IDs.
///
/// Uses SharedPreferences (key-value store) — lightweight and appropriate
/// for a simple Set<String>. If you later need more complex querying
/// (e.g. sort-by-date-added), migrate to Hive or SQLite.
class FavoritesRepository {
  static const _key = 'favorite_recipe_ids';

  final SharedPreferences _prefs;

  FavoritesRepository(this._prefs);

  /// Load saved favorite IDs. Returns empty set if nothing saved yet.
  Set<String> load() {
    final list = _prefs.getStringList(_key);
    return list != null ? Set<String>.from(list) : const {};
  }

  /// Persist the full set of favorite IDs.
  Future<void> save(Set<String> ids) async {
    await _prefs.setStringList(_key, ids.toList());
  }

  /// Toggle a single ID and persist. Returns the updated set.
  Future<Set<String>> toggle(Set<String> current, String id) async {
    final updated = Set<String>.from(current);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    await save(updated);
    return updated;
  }

  /// Factory — call this once in main() before runApp().
  static Future<FavoritesRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return FavoritesRepository(prefs);
  }
}

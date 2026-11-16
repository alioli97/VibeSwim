import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Workouts the user starred, stored on the device as snapshots of the
/// Supabase rows (like the history: offline and still translatable).
class Favorites extends ChangeNotifier {
  static const String keyFavorites = 'favorite_workouts';

  final SharedPreferences prefs;
  final List<Map<String, dynamic>> _items;

  Favorites(this.prefs) : _items = _load(prefs);

  /// Most recently starred first.
  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  bool isFavorite(Object? id) => id != null && _items.any((w) => w['id'] == id);

  /// Stars [workout], or unstars it if it already was. Returns whether it is
  /// a favorite afterwards. Rows without an `id` can't be starred.
  Future<bool> toggle(Map<String, dynamic> workout) async {
    final id = workout['id'];
    if (id == null) return false;
    final starred = !isFavorite(id);
    if (starred) {
      _items.insert(0, Map.of(workout));
    } else {
      _items.removeWhere((w) => w['id'] == id);
    }
    notifyListeners();
    await _save();
    return starred;
  }

  /// Puts back a favorite removed by mistake (undo), at [index].
  Future<void> restore(Map<String, dynamic> workout, int index) async {
    if (isFavorite(workout['id'])) return;
    _items.insert(index.clamp(0, _items.length), workout);
    notifyListeners();
    await _save();
  }

  Future<void> _save() => prefs.setString(keyFavorites, jsonEncode(_items));

  static List<Map<String, dynamic>> _load(SharedPreferences prefs) {
    final raw = prefs.getString(keyFavorites);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
    } on FormatException {
      return [];
    }
  }
}

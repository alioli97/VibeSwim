import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swimvibe/core/favorites.dart';

Map<String, dynamic> workout(String id) => {'id': id, 'distance_meters': 800, 'title_en': id};

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('toggle stars and unstars, newest first, and persists', () async {
    final favorites = Favorites(prefs);
    var notifications = 0;
    favorites.addListener(() => notifications++);

    expect(await favorites.toggle(workout('a')), isTrue);
    expect(await favorites.toggle(workout('b')), isTrue);
    expect(favorites.items.map((w) => w['id']), ['b', 'a']);
    expect(favorites.isFavorite('a'), isTrue);
    expect(Favorites(prefs).items.map((w) => w['id']), ['b', 'a']); // persisted

    expect(await favorites.toggle(workout('a')), isFalse);
    expect(favorites.isFavorite('a'), isFalse);
    expect(Favorites(prefs).items, hasLength(1));
    expect(notifications, 3);
  });

  test('restore puts a removed favorite back in its place', () async {
    final favorites = Favorites(prefs);
    for (final id in ['c', 'b', 'a']) {
      await favorites.toggle(workout(id));
    }
    final removed = favorites.items[1]; // b
    await favorites.toggle(removed);

    await favorites.restore(removed, 1);
    expect(favorites.items.map((w) => w['id']), ['a', 'b', 'c']);

    await favorites.restore(removed, 0); // already there: no duplicate
    expect(favorites.items, hasLength(3));
  });

  test('rows without an id cannot be starred', () async {
    final favorites = Favorites(prefs);
    expect(await favorites.toggle({'distance_meters': 400}), isFalse);
    expect(favorites.items, isEmpty);
    expect(favorites.isFavorite(null), isFalse);
  });

  test('ignores corrupt stored data', () async {
    SharedPreferences.setMockInitialValues({Favorites.keyFavorites: 'not json'});
    expect(Favorites(await SharedPreferences.getInstance()).items, isEmpty);
  });
}

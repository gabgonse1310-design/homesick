import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/letter.dart';

class LetterStorageService {
  LetterStorageService._();

  static final LetterStorageService instance = LetterStorageService._();

  static const String _lettersKey = 'homesick_letters';

  Future<List<Letter>> loadLetters() async {
    final preferences = await SharedPreferences.getInstance();
    final storedLetters = preferences.getStringList(_lettersKey) ?? const [];
    final letters = <Letter>[];

    for (final storedLetter in storedLetters) {
      try {
        final decoded = jsonDecode(storedLetter);
        if (decoded is Map<String, dynamic>) {
          letters.add(Letter.fromJson(decoded));
        } else if (decoded is Map) {
          letters.add(Letter.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {
        // Ignore damaged records.
      }
    }

    letters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return letters;
  }

  Future<List<Letter>> loadLettersForPerson(String personKey) async {
    final letters = await loadLetters();
    return letters.where((letter) => letter.personKey == personKey).toList();
  }

  Future<Letter?> findLetter(String id) async {
    final letters = await loadLetters();
    for (final letter in letters) {
      if (letter.id == id) return letter;
    }
    return null;
  }

  Future<void> saveLetter(Letter letter) async {
    final letters = await loadLetters();
    final index = letters.indexWhere((saved) => saved.id == letter.id);

    if (index == -1) {
      letters.add(letter);
    } else {
      letters[index] = letter;
    }

    await _saveAll(letters);
  }

  Future<void> deleteLetter(String id) async {
    final letters = await loadLetters()..removeWhere((letter) => letter.id == id);
    await _saveAll(letters);
  }

  Future<void> setFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    final letters = await loadLetters();
    final index = letters.indexWhere((letter) => letter.id == id);

    if (index == -1) return;

    letters[index] = letters[index].copyWith(
      isFavorite: isFavorite,
      updatedAt: DateTime.now(),
    );

    await _saveAll(letters);
  }

  Future<void> clearLetters() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lettersKey);
  }

  Future<void> _saveAll(List<Letter> letters) async {
    final preferences = await SharedPreferences.getInstance();
    letters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final encoded = letters.map((letter) => jsonEncode(letter.toJson())).toList();
    await preferences.setStringList(_lettersKey, encoded);
  }
}

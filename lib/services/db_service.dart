import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

class DbService {
  DbService._privateConstructor();
  static final DbService instance = DbService._privateConstructor();

  static Database? _db;

  /// Ленивый геттер: если база уже открыта — возвращаем, иначе инициализируем
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<void> init() async {
    await database; // просто вызывает геттер и создаёт БД
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'anki_app.db');

    // Если базы ещё нет, копируем из assets
    if (!await File(path).exists()) {
      final data = await rootBundle.load('assets/database/prepopulated.db');
      final bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }

    // Открываем существующую базу (готовый файл)
    return await openDatabase(path, version: 1);
  }

  // ---------------- Decks ----------------

  Future<int> addDeck(String name) async {
    final db = await database;
    return await db.insert('decks', {'name': name});
  }

  Future<List<Deck>> getDecks() async {
    final db = await database;
    final rows = await db.query('decks', orderBy: 'id DESC');
    return rows
        .map((r) => Deck(id: r['id'] as int, name: r['name'] as String))
        .toList();
  }

  //Future<int> deleteDeck(int id) async {
  //  final db = await database;
  //  return await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  //}

  // ---------------- Flashcards ----------------

  Future<void> addCard(
      int deckId,
      String question,
      String answer,
      DateTime nextReview,
      int interval,
      ) async {
    final db = await database;
    await db.insert('flashcards', {
      'deck_id': deckId,
      'question': question,
      'answer': answer,
      'next_review': nextReview.toIso8601String(),
      'interval': interval,
    });
  }

  Future<List<Flashcard>> getFlashcards(int deckId) async {
    final db = await database;
    final rows = await db.query(
      'flashcards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'id ASC',
    );

    return rows.map((r) {
      DateTime parsedNext;
      final rawNext = r['next_review'] as String?;
      if (rawNext != null && rawNext.isNotEmpty) {
        try {
          parsedNext = DateTime.parse(rawNext).toLocal();
        } catch (_) {
          parsedNext = DateTime.now();
        }
      } else {
        parsedNext = DateTime.now();
      }

      return Flashcard(
        id: (r['id'] as int?) ?? 0,
        deckId: (r['deck_id'] as int?) ?? 0,
        question: (r['question'] as String?) ?? '',
        answer: (r['answer'] as String?) ?? '',
        nextReview: parsedNext,
        interval: (r['interval'] as int?) ?? 1,
        ease: ((r['ease'] is num) ? (r['ease'] as num).toDouble() : 2.5),
        correctStreak: (r['correct_streak'] as int?) ?? 0,
      );
    }).toList();
  }

  Future<int> deleteFlashcard(int id) async {
    final db = await database;
    return await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateFlashcard(Flashcard card) async {
    final db = await database;
    return await db.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> updateFlashcardProgress(Flashcard card, bool correct) async {
    final db = await database;

    if (correct) {
      card.correctStreak += 1;
      card.interval = (card.interval * card.ease).round();
      card.ease += 0.1;
    } else {
      card.correctStreak = 0;
      card.interval = 1;
      card.ease = (card.ease * 0.9).clamp(1.3, 2.5);
    }

    // Сохраняем nextReview в UTC
    card.nextReview =
        DateTime.now().toUtc().add(Duration(days: card.interval));

    await db.update(
      'flashcards',
      {
        'question': card.question,
        'answer': card.answer,
        'deck_id': card.deckId,
        'next_review': card.nextReview.toIso8601String(),
        'interval': card.interval,
        'ease': card.ease,
        'correct_streak': card.correctStreak,
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<List<Flashcard>> getDueFlashcards(int deckId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'flashcards',
      where: 'deck_id = ? AND next_review <= ?',
      whereArgs: [deckId, today],
    );

    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  Future<int> updateDeck(int id, String newName) async {
    final db = await database;
    return await db.update(
      'decks',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDeck(int id) async {
    final db = await database;

    // Сначала удаляем все карточки этой колоды
    await db.delete('flashcards', where: 'deck_id = ?', whereArgs: [id]);

    // Затем удаляем саму колоду
    await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }


  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

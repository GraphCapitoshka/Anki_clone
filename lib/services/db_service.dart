// lib/services/db_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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

    // Открываем (или создаём) базу
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
  CREATE TABLE flashcards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deck_id INTEGER,
  question TEXT,
  answer TEXT,
  next_review TEXT,
  interval INTEGER,
  ease REAL DEFAULT 2.5,
  correct_streak INTEGER DEFAULT 0
)

''');

  }

  // ---------------- Decks ----------------

  Future<int> addDeck(String name) async {
    final db = await database;
    return await db.insert('decks', {'name': name});
  }

  Future<List<Deck>> getDecks() async {
    final db = await database;
    final rows = await db.query('decks', orderBy: 'id DESC');
    return rows.map((r) => Deck(id: r['id'] as int, name: r['name'] as String)).toList();
  }

  Future<int> deleteDeck(int id) async {
    final db = await database;
    return await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }

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
      return Flashcard(
        id: (r['id'] as int?) ?? 0,
        deckId: (r['deck_id'] as int?) ?? 0,
        question: (r['question'] as String?) ?? '',
        answer: (r['answer'] as String?) ?? '',
        nextReview: DateTime.tryParse((r['next_review'] as String?) ?? '') ?? DateTime.now(),
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
      card.toMap(), // <-- вот здесь ключевое изменение
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }


  // Закрыть базу (если нужно)
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
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

    card.nextReview = DateTime.now().add(Duration(days: card.interval));

    await db.update(
      'flashcards',
      card.toMap(),
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




}

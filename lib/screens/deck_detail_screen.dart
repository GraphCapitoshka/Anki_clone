import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/db_service.dart';
import 'add_card_screen.dart';
import 'review_screen.dart';
import 'edit_card_screen.dart';
import 'view_card_screen.dart';
import 'package:intl/intl.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;
  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  List<Flashcard> cards = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => loading = true);
    cards = await DbService.instance.getFlashcards(widget.deck.id);
    setState(() => loading = false);
  }

  Future<void> _deleteCard(int id) async {
    await DbService.instance.deleteFlashcard(id);
    await _loadCards();
  }

  Future<void> _addCard() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddCardScreen(deckId: widget.deck.id)),
    );

    if (added == true) await _loadCards();
  }

  Future<void> _startReview() async {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('no_cards'.tr())));
      return;
    }

    final dueCards = await DbService.instance.getDueFlashcards(widget.deck.id);

    if (dueCards.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('no_due_cards'.tr())));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(cards: dueCards)),
    );

    await _loadCards();
  }

  Future<void> _startFullReview() async {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('no_cards'.tr())));
      return;
    }

    final allCards = List<Flashcard>.from(cards);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(cards: allCards)),
    );

    await _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.deck.name),
            Chip(
              label: Text('${cards.length}'),
              backgroundColor: Colors.indigo[200],
            ),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
          ? Center(child: Text('no_cards'.tr()))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final c = cards[index];
                final isDue = c.nextReview.isBefore(DateTime.now());
                return Card(
                  color: isDue ? Colors.green[50] : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    title: Text(
                      c.question,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.answer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getNextReviewText(c),
                            style: TextStyle(
                              fontSize: 13,
                              color: c.nextReview.isBefore(DateTime.now()) ? Colors.green : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      EditCardScreen(card: c)),
                            );
                            if (updated == true) await _loadCards();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _deleteCard(c.id!),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ViewCardScreen(card: c)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async => await _startReview(),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('start_review'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async => await _startFullReview(),
                  icon: const Icon(Icons.play_circle_fill),
                  label: Text('start_full_review'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        backgroundColor: Colors.indigo,
        tooltip: 'add_card'.tr(),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getNextReviewText(Flashcard c) {
    final nowUtc = DateTime.now().toUtc();
    final nextUtc = c.nextReview.toUtc();
    final isDue = !nextUtc.isAfter(nowUtc); // true, если next <= now

    if (isDue) {
      return '🟢 ${'available_for_review'.tr()}';
    } else {
      final formattedDate =
      DateFormat('dd.MM.yyyy HH:mm').format(c.nextReview.toLocal());
      return '🕓 ${'next_review_on'.tr(args: [formattedDate])}';
    }
  }
}

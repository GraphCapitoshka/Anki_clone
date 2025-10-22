import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/db_service.dart';
import 'add_card_screen.dart';
import 'review_screen.dart';
import 'edit_card_screen.dart';
import 'package:intl/intl.dart';
import 'view_card_screen.dart';



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

    if (added == true) {
      await _loadCards();
    }
  }

  Future<void> _startReview() async {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_cards'.tr())),
      );
      return;
    }

    final dueCards = await DbService.instance.getDueFlashcards(widget.deck.id);

    if (dueCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_due_cards'.tr())),
      );
      return;
    }

    // 🔹 Ждём, пока пользователь завершит повторение
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(cards: dueCards),
      ),
    );

    // 🔹 После возврата — перезагружаем карточки
    if (result == true) {
      await _loadCards();
    } else {
      await _loadCards(); // даже если просто вернулся, обновим на всякий
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deck.name)),
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
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(c.question),
                    subtitle: Column(
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

                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCardScreen(card: c),
                              ),
                            );
                            if (updated == true) _loadCards();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteCard(c.id!),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewCardScreen(card: c),
                        ),
                      );
                    },


                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async => await _startReview(),
              icon: const Icon(Icons.play_arrow),
              label: Text('start_review'.tr()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
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
      final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(c.nextReview.toLocal());
      return '🕓 ${'next_review_on'.tr(args: [formattedDate])}';
    }
  }


}



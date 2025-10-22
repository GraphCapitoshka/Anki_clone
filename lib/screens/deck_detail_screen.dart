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
      _showSnack('no_cards'.tr());
      return;
    }

    final dueCards = await DbService.instance.getDueFlashcards(widget.deck.id);

    if (dueCards.isEmpty) {
      _showSnack('no_due_cards'.tr());
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(cards: dueCards)),
    );

    await _loadCards();
  }

  Future<void> _startFullReview() async {
    if (cards.isEmpty) {
      _showSnack('no_cards'.tr());
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(cards: List.from(cards))),
    );

    await _loadCards();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Chip(
              backgroundColor: color.withOpacity(0.15),
              label: Text(
                '${cards.length}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : cards.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.style_outlined,
                  size: 72, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'no_cards'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadCards,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final c = cards[index];
              final isDue = c.nextReview.isBefore(DateTime.now());

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ViewCardScreen(card: c)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isDue
                            ? [
                          Colors.green.withOpacity(0.1),
                          Colors.green.withOpacity(0.05),
                        ]
                            : [
                          color.withOpacity(0.08),
                          color.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.answer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getNextReviewText(c),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDue
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.indigo),
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditCardScreen(card: c),
                                  ),
                                );
                                if (updated == true) _loadCards();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteCard(c.id!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _startReview,
                icon: const Icon(Icons.play_arrow),
                label: Text('start_review'.tr()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _startFullReview,
                icon: const Icon(Icons.all_inclusive),
                label: Text('start_full_review'.tr()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCard,
        icon: const Icon(Icons.add),
        label: Text('add_card'.tr()),
      ),
    );
  }

  String _getNextReviewText(Flashcard c) {
    final nowUtc = DateTime.now().toUtc();
    final nextUtc = c.nextReview.toUtc();
    final isDue = !nextUtc.isAfter(nowUtc);

    if (isDue) {
      return '🟢 ${'available_for_review'.tr()}';
    } else {
      final formattedDate =
      DateFormat('dd.MM.yyyy HH:mm').format(c.nextReview.toLocal());
      return '🕓 ${'next_review_on'.tr(args: [formattedDate])}';
    }
  }
}

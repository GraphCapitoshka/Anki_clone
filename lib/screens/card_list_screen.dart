import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/flashcard.dart';
import '../services/db_service.dart';
import '../widgets/flip_card_widget.dart';
import '../widgets/language_switcher.dart';
import 'add_card_screen.dart';

class CardListScreen extends StatefulWidget {
  final int deckId;
  final String deckName;

  const CardListScreen({super.key, required this.deckId, required this.deckName});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  List<Flashcard> cards = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => loading = true);
    cards = await DbService.instance.getFlashcards(widget.deckId);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckName),
        actions: const [LanguageSwitcher()],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
          ? Center(child: Text('no_cards'.tr()))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: FlipCardWidget(
                front: card.question,
                back: card.answer,
                width: double.infinity,
                height: 150,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddCardScreen(deckId: widget.deckId),
            ),
          );
          await _loadCards();
        },
        label: Text('add_card'.tr()),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/flashcard.dart';
import '../services/db_service.dart';

class ReviewScreen extends StatefulWidget {
  final List<Flashcard> cards;

  const ReviewScreen({super.key, required this.cards});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int currentIndex = 0;
  bool showAnswer = false;
  bool loading = false;

  Flashcard get currentCard => widget.cards[currentIndex];

  void _nextCard() {
    if (currentIndex < widget.cards.length - 1) {
      setState(() {
        currentIndex++;
        showAnswer = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _handleAnswer(bool correct) async {
    setState(() => loading = true);

    await DbService.instance.updateFlashcardProgress(currentCard, correct);

    setState(() => loading = false);
    _nextCard();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('review_completed'.tr()),
        content: Text('all_cards_reviewed'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    ).then((_) => Navigator.pop(context, true));

  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('review'.tr())),
        body: Center(child: Text('no_cards'.tr())),
      );
    }

    final card = currentCard;

    return Scaffold(
      appBar: AppBar(
        title: Text('review'.tr()),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${currentIndex + 1} / ${widget.cards.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FlipCard(
                flipOnTouch: true,
                front: _buildCardFace(card.question, Colors.blue.shade100),
                back: _buildCardFace(card.answer, Colors.green.shade100),
              ),
            ),
            const SizedBox(height: 20),
            if (showAnswer)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handleAnswer(false),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: Text('forgot'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleAnswer(true),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: Text('remembered'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => setState(() => showAnswer = true),
                child: Text('show_answer'.tr()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFace(String text, Color color) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

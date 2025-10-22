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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('review'.tr())),
        body: Center(child: Text('no_cards'.tr())),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text('review'.tr()),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Индикатор прогресса
            LinearProgressIndicator(
              value: (currentIndex + 1) / widget.cards.length,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceVariant,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 16),
            Text(
              '${currentIndex + 1} / ${widget.cards.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: FlipCard(
                flipOnTouch: true,
                front: _buildCardFace(
                  currentCard.question,
                  colorScheme.primaryContainer,
                  Icons.help_outline,
                ),
                back: _buildCardFace(
                  currentCard.answer,
                  colorScheme.secondaryContainer,
                  Icons.check_circle_outline,
                ),
              ),
            ),
            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: showAnswer
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _handleAnswer(false),
                    icon: const Icon(Icons.close),
                    label: Text('forgot'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.redAccent.withOpacity(0.15),
                      foregroundColor: Colors.red,
                      minimumSize: const Size(130, 50),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleAnswer(true),
                    icon: const Icon(Icons.check),
                    label: Text('remembered'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.greenAccent.withOpacity(0.15),
                      foregroundColor: Colors.green,
                      minimumSize: const Size(130, 50),
                    ),
                  ),
                ],
              )
                  : ElevatedButton.icon(
                key: const ValueKey('showAnswer'),
                onPressed: () => setState(() => showAnswer = true),
                icon: const Icon(Icons.visibility),
                label: Text('show_answer'.tr()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFace(String text, Color color, IconData icon) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.black54),
              const SizedBox(height: 20),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

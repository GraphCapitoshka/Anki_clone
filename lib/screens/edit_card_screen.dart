import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/flashcard.dart';
import '../services/db_service.dart';

class EditCardScreen extends StatefulWidget {
  final Flashcard card;
  const EditCardScreen({super.key, required this.card});

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.card.question);
    _answerController = TextEditingController(text: widget.card.answer);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedCard = Flashcard(
      id: widget.card.id,
      deckId: widget.card.deckId,
      question: _questionController.text.trim(),
      answer: _answerController.text.trim(),
      nextReview: widget.card.nextReview,
      interval: widget.card.interval,
      ease: widget.card.ease,
      correctStreak: widget.card.correctStreak,
    );

    await DbService.instance.updateFlashcard(updatedCard);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_card'.tr()),
        backgroundColor: color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 3,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _questionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'front'.tr(),
                      prefixIcon: const Icon(Icons.help_outline),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'field_required'.tr() : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _answerController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'back'.tr(),
                      prefixIcon: const Icon(Icons.text_snippet_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'field_required'.tr() : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saveCard,
                    icon: const Icon(Icons.save),
                    label: Text('save'.tr()),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

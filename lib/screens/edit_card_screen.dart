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

  Future<void> _saveCard() async {
    if (_formKey.currentState!.validate()) {
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
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('edit_card'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(labelText: 'front'.tr()),
                validator: (value) =>
                value == null || value.isEmpty ? 'field_required'.tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _answerController,
                decoration: InputDecoration(labelText: 'back'.tr()),
                validator: (value) =>
                value == null || value.isEmpty ? 'field_required'.tr() : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveCard,
                icon: const Icon(Icons.save),
                label: Text('save'.tr()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

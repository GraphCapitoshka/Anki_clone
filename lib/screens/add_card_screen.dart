import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/db_service.dart';

class AddCardScreen extends StatefulWidget {
  final int deckId;
  const AddCardScreen({super.key, required this.deckId});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  bool get canSave =>
      _frontController.text.trim().isNotEmpty &&
          _backController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    try {
      await DbService.instance.addCard(
        widget.deckId,
        _frontController.text.trim(),
        _backController.text.trim(),
        DateTime.now(), // первая дата повторения — сегодня
        1, // первый интервал — 1 день
      );


      if (mounted) Navigator.pop(context, true); // возвращаем true
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении карточки: $e')),
      );
    }
  }

  void _onTextChanged() {
    setState(() {}); // обновляем состояние, чтобы кнопка активировалась/деактивировалась
  }

  @override
  void initState() {
    super.initState();
    _frontController.addListener(_onTextChanged);
    _backController.addListener(_onTextChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('add_card'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _frontController,
              decoration: InputDecoration(labelText: 'question'.tr()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _backController,
              decoration: InputDecoration(labelText: 'answer'.tr()),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: canSave ? save : null,
              icon: const Icon(Icons.save),
              label: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

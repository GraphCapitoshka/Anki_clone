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
  void initState() {
    super.initState();
    _frontController.addListener(_onTextChanged);
    _backController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  Future<void> _save() async {
    try {
      await DbService.instance.addCard(
        widget.deckId,
        _frontController.text.trim(),
        _backController.text.trim(),
        DateTime.now(),
        1,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_saving_card'.tr(args: [e.toString()]))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('add_card'.tr()),
        backgroundColor: color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _frontController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'question'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.help_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _backController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'answer'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.text_snippet_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: canSave ? _save : null,
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
    );
  }
}

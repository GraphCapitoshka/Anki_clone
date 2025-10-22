import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/db_service.dart';
import '../models/deck.dart';
import 'deck_detail_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<Deck> decks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() => loading = true);
    decks = await DbService.instance.getDecks();
    setState(() => loading = false);
  }

  Future<void> _addDeck() async {
    final TextEditingController _controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('add_deck'.tr()),
        content: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'deck_name'.tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: Text('save'.tr()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await DbService.instance.addDeck(result);
      await _loadDecks();
    }
  }

  void _switchLocale() {
    final current = context.locale;
    final next = current.languageCode == 'ru' ? const Locale('en') : const Locale('ru');
    context.setLocale(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'switch_lang'.tr(),
            onPressed: _switchLocale,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : decks.isEmpty
          ? Center(child: Text('no_decks'.tr()))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: decks.length,
        itemBuilder: (context, index) {
          final deck = decks[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(deck.name),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
                );
                await _loadDecks();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDeck,
        child: const Icon(Icons.add),
        tooltip: 'add_deck'.tr(),
      ),
    );
  }
}

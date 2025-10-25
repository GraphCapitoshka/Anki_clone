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
    final TextEditingController controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('add_deck'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'deck_name'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
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

  Future<void> _editDeck(Deck deck) async {
    final controller = TextEditingController(text: deck.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_deck'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'deck_name'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('save'.tr()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await DbService.instance.updateDeck(deck.id!, result);
      await _loadDecks();
    }
  }

  Future<void> _confirmDeleteDeck(int? id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_deck_title'.tr()),
        content: Text('delete_deck_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && id != null) {
      await DbService.instance.deleteDeck(id);
      await _loadDecks();
    }
  }

  void _switchLocale() {
    final current = context.locale;
    final next = current.languageCode == 'ru'
        ? const Locale('en')
        : const Locale('ru');
    context.setLocale(next);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'app_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'switch_lang'.tr(),
            onPressed: _switchLocale,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : decks.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.style_outlined,
                  size: 72, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'no_decks'.tr(),
                style: const TextStyle(
                    fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadDecks,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: decks.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4 / 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final deck = decks[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DeckDetailScreen(deck: deck),
                      ),
                    );
                    await _loadDecks();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.folder_rounded,
                                color: color, size: 36),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editDeck(deck);
                                } else if (value == 'delete') {
                                  _confirmDeleteDeck(deck.id);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('edit_deck'.tr()),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('delete'.tr()),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          deck.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDeck,
        icon: const Icon(Icons.add),
        label: Text('add_deck'.tr()),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import '../models/flashcard.dart';

class ViewCardScreen extends StatefulWidget {
  final Flashcard card;

  const ViewCardScreen({super.key, required this.card});

  @override
  State<ViewCardScreen> createState() => _ViewCardScreenState();
}

class _ViewCardScreenState extends State<ViewCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: const Text('Просмотр карточки'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: _flipCard,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final angle = _controller.value * pi;
              final isUnder = (angle > pi / 2);

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isUnder
                    ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: _buildCardBack(context),
                )
                    : _buildCardFront(context),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    return _buildCard(
      content: widget.card.question,
      label: 'Нажмите, чтобы увидеть ответ',
      color: color,
      icon: Icons.help_outline,
    );
  }

  Widget _buildCardBack(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondaryContainer;
    return _buildCard(
      content: widget.card.answer,
      label: 'Нажмите, чтобы вернуться',
      color: color,
      icon: Icons.check_circle_outline,
    );
  }

  Widget _buildCard({
    required String content,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(2, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.black54),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

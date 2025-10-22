import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

class FlipCardWidget extends StatelessWidget {
  final String front;
  final String back;
  final double width;
  final double height;

  const FlipCardWidget({
    Key? key,
    required this.front,
    required this.back,
    this.width = 320,
    this.height = 220,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      direction: FlipDirection.HORIZONTAL,
      front: _buildSide(context, front),
      back: _buildSide(context, back),
    );
  }

  Widget _buildSide(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Center(
        child: Text(text, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
      ),
    );
  }
}

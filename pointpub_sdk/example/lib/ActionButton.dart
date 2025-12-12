import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle style;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

class ActionItem {
  final String label;
  final VoidCallback onPressed;

  const ActionItem({
    required this.label,
    required this.onPressed,
  });
}
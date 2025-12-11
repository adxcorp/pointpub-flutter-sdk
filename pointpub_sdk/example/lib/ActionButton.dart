import 'package:flutter/material.dart';

class ActionButton {
  final String label;
  final VoidCallback onPressed;

  ActionButton({
    required this.label,
    required this.onPressed,
  });
}
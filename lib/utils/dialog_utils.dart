import 'package:flutter/material.dart';

Future<void> showAttentionDialog(
  BuildContext context,
  String message, {
  String title = 'Atencao',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

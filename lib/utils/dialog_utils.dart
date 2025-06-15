// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

// Cores
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;

Widget buildDialogButton(BuildContext passedContext, String text, VoidCallback onPressed, bool isPrimary) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: isPrimary ? accentColorPurple : Colors.grey.shade700,
      foregroundColor: textColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: isPrimary ? accentColorBlue : Colors.transparent)
      ),
    ),
    child: Text(text.toUpperCase()),
  );
}

Future<T?> showStyledDialog<T>({
  required BuildContext passedContext,
  required String titleText,
  required List<Widget> contentWidgets,
  required List<Widget> actions,
  IconData icon = Icons.info_outline,
  Color iconColor = accentColorBlue,
}) {
  return showDialog<T>(
    context: passedContext,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: primaryColor.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(color: accentColorBlue.withOpacity(0.7), width: 1.5),
        ),
        title: Container(
          padding: const EdgeInsets.only(bottom: 10.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: accentColorPurple.withOpacity(0.5), width: 1.0)
            )
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Text(
                titleText.toUpperCase(),
                style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(children: contentWidgets),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        actions: actions.length > 1
            ? List.generate(actions.length * 2 - 1, (index) {
                if (index.isEven) return actions[index ~/ 2];
                return const SizedBox(width: 8);
              })
            : actions,
      );
    },
  );
} 
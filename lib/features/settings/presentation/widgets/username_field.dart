// lib/features/settings/presentation/widgets/username_field.dart
import 'package:flutter/material.dart';

class UsernameField extends StatefulWidget {
  const UsernameField({
    required this.initialValue,
    required this.label,
    required this.saveLabel,
    required this.onSaved,
    super.key,
  });

  final String initialValue;
  final String label;
  final String saveLabel;
  final ValueChanged<String> onSaved;

  @override
  State<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends State<UsernameField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar() {
    final String valor = _controller.text.trim();
    if (valor.isEmpty) return;
    FocusScope.of(context).unfocus();
    widget.onSaved(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              onSubmitted: (_) => _guardar(),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: _guardar,
            child: Text(widget.saveLabel),
          ),
        ],
      ),
    );
  }
}

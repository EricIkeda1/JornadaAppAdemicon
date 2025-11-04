import 'package:flutter/material.dart';

class GestorHeaderRow extends StatelessWidget {
  final int total;
  final VoidCallback onAvisos;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback? onClearQuery;

  const GestorHeaderRow({
    super.key,
    required this.total,
    required this.onAvisos,
    required this.query,
    required this.onQueryChanged,
    this.onClearQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _pill(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$total total',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _pill(
                child: TextButton.icon(
                  onPressed: onAvisos,
                  icon: const Icon(Icons.notifications_none, color: Colors.black87, size: 18),
                  label: const Text('Avisos', style: TextStyle(color: Colors.black87)),
                ),
              ),
              const Spacer(),
              const Text('Meus Leads', style: TextStyle(color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 10),
          _pill(
            child: SizedBox(
              height: 44,
              child: _SearchField(
                value: query,
                onChanged: onQueryChanged,
                onClear: onClearQuery,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: child,
    );
  }
}

class _SearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const _SearchField({
    required this.value,
    required this.onChanged,
    this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      final newText = widget.value;
      _controller
        ..text = newText
        ..selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Pesquisar leads...',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDFDFDF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDFDFDF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
        ),
        suffixIcon: (_controller.text.isNotEmpty)
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  if (widget.onClear != null) {
                    widget.onClear!();
                  } else {
                    _controller.clear();
                    widget.onChanged('');
                  }
                },
              )
            : null,
      ),
    );
  }
}

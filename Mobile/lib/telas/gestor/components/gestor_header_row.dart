import 'package:flutter/material.dart';

class GestorHeaderRow extends StatelessWidget {
  final int totalGeral;
  final int totalFiltro;

  final VoidCallback onAvisos;

  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback? onClearQuery;

  const GestorHeaderRow({
    super.key,
    required this.totalGeral,
    required this.totalFiltro,
    required this.onAvisos,
    required this.query,
    required this.onQueryChanged,
    this.onClearQuery,
  });

  @override
  Widget build(BuildContext context) {
    const branco = Color(0xFFFFFFFF);
    const preto09 = Color(0xFF231F20);
    const cinzaClaro = Color(0xFFDCDDDE);
    const vermelhoClaro = Color(0xFFEA3124);

    final bool emBusca = query.trim().isNotEmpty;
    final String textoTotal = emBusca ? '$totalFiltro resultado(s)' : '$totalGeral total';

    return Container(
      color: branco,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cinzaClaro),
                  color: branco,
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: vermelhoClaro, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    textoTotal,
                    style: const TextStyle(color: branco, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cinzaClaro),
                  color: branco,
                ),
                child: TextButton.icon(
                  onPressed: onAvisos,
                  icon: const Icon(Icons.notifications_none, size: 16, color: preto09),
                  label: const Text('Avisos', style: TextStyle(color: preto09, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('Meus Leads', style: TextStyle(color: preto09, fontSize: 12.5, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SearchPill(
            query: query,
            onChanged: onQueryChanged,
            onClear: onClearQuery,
          ),
        ],
      ),
    );
  }
}

class _SearchPill extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const _SearchPill({
    required this.query,
    required this.onChanged,
    this.onClear,
  });

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  late final TextEditingController _controller = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(covariant _SearchPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller
        ..text = widget.query
        ..selection = TextSelection.fromPosition(TextPosition(offset: widget.query.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const branco = Color(0xFFFFFFFF);
    const cinzaClaro = Color(0xFFDCDDDE);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cinzaClaro),
        color: branco,                    
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.search, color: Color(0xFF6B6B6B)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Pesquisar leads...',
                isDense: true,
                filled: false,           
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF6B6B6B)),
              onPressed: () {
                if (widget.onClear != null) {
                  widget.onClear!();
                } else {
                  _controller.clear();
                  widget.onChanged('');
                }
              },
              splashRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

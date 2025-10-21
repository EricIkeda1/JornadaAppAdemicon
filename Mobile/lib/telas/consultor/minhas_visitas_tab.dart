import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MinhasVisitasTab extends StatefulWidget {
  const MinhasVisitasTab({super.key});

  @override
  State<MinhasVisitasTab> createState() => _MinhasVisitasTabState();
}

class _MinhasVisitasTabState extends State<MinhasVisitasTab> with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final SupabaseClient _client = Supabase.instance.client;

  bool _proxExpanded = false;
  bool _finExpanded  = false;

  bool _showChips = true;

  List<Map<String, dynamic>>? _cacheProximas;
  List<Map<String, dynamic>>? _cacheFinalizados;

  Widget? _cacheProximasWidget;
  Widget? _cacheFinalizadosWidget;

  List<String> _ruasDisponiveis = [];

  @override
  void initState() {
    super.initState();

    _proxExpanded = false;
    _finExpanded  = false;
    _invalidateCaches();

    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text.trim();
        _showChips = true; 
        _invalidateCaches();
      });
    });
  }

  void _invalidateCaches() {
    _cacheProximas = null;
    _cacheFinalizados = null;
    _cacheProximasWidget = null;
    _cacheFinalizadosWidget = null;
  }

  void _hideChipsOnly() {
    final scope = FocusScope.of(context);
    if (!scope.hasPrimaryFocus && scope.focusedChild != null) {
      scope.unfocus();
    }
    if (_showChips) {
      setState(() => _showChips = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> get _meusClientesStream {
    final user = _client.auth.currentSession?.user;
    if (user == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _client
        .from('clientes')
        .select('*')
        .eq('consultor_uid_t', user.id)
        .order('data_visita', ascending: false)
        .order('hora_visita', ascending: false)
        .asStream();
  }

  Future<void> _abrirNoGoogleMaps(String endereco) async {
    final encoded = Uri.encodeComponent(endereco);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Google Maps'), backgroundColor: Colors.red),
      );
    }
  }

  InputDecoration _obterDecoracaoCampo(
    String label, {
    String? hint,
    Widget? suffixIcon,
    bool isObrigatorio = false,
  }) {
    return InputDecoration(
      labelText: '$label${isObrigatorio ? ' *' : ''}',
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      suffixIcon: suffixIcon,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Minhas Visitas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gerencie seu cronograma de visitas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildSectionTitle(title), child]),
      ),
    );
  }

  Widget _buildVisitaItem(Map<String, dynamic> cliente) {
    final cs = Theme.of(context).colorScheme;

    final anyEnd = cliente['endereco'];
    final endereco = (anyEnd is String) ? anyEnd.trim() : (anyEnd?.toString() ?? '').trim();
    final anyEst = cliente['estabelecimento'];
    final estabelecimento = (anyEst is String && anyEst.trim().isNotEmpty) ? anyEst.trim() : 'Estabelecimento não informado';

    final dataVisitaStr = cliente['data_visita'] as String?;
    final horaVisitaStr = cliente['hora_visita'] as String?;
    final anyCidade = cliente['cidade'];
    final cidade = (anyCidade is String) ? anyCidade.trim() : (anyCidade?.toString() ?? '').trim();
    final anyEstado = cliente['estado'];
    final estado = (anyEstado is String) ? anyEstado.trim() : (anyEstado?.toString() ?? '').trim();

    final dataFormatada = _formatarDataVisita(dataVisitaStr, horaVisitaStr);
    final statusInfo = _determinarStatus(dataVisitaStr, horaVisitaStr: horaVisitaStr);

    final enderecoCompleto = [
      if (endereco.isNotEmpty) endereco,
      if (cidade.isNotEmpty || estado.isNotEmpty) '$cidade - $estado',
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
            child: Icon(statusInfo['icone'], size: 20, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusInfo['corFundo'], borderRadius: BorderRadius.circular(6)),
                child: Text(
                  statusInfo['texto'] as String,
                  style: TextStyle(color: statusInfo['corTexto'], fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                estabelecimento,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (enderecoCompleto.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        enderecoCompleto,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.none,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Abrir no Maps',
                      icon: const Icon(Icons.map_outlined, size: 20),
                      onPressed: enderecoCompleto.isEmpty ? null : () => _abrirNoGoogleMaps(enderecoCompleto),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                dataFormatada,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _determinarStatus(String? dataVisitaStr, {String? horaVisitaStr}) {
    final cs = Theme.of(context).colorScheme;

    if (dataVisitaStr == null || dataVisitaStr.isEmpty) {
      return {
        'icone': Icons.event_note_outlined,
        'texto': 'AGENDADO',
        'corFundo': const Color(0x3328A745),
        'corTexto': Colors.green,
      };
    }

    try {
      DateTime data = DateTime.parse(dataVisitaStr).toLocal();
      if (horaVisitaStr != null && horaVisitaStr.isNotEmpty) {
        final p = horaVisitaStr.split(':');
        final h = int.tryParse(p[0]) ?? 0;
        final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
        final s = p.length > 2 ? int.tryParse(p[2]) ?? 0 : 0;
        data = DateTime(data.year, data.month, data.day, h, m, s);
      } else {
        data = DateTime(data.year, data.month, data.day, 23, 59, 59);
      }

      final agora = DateTime.now();
      final hojeInicio = DateTime(agora.year, agora.month, agora.day, 0, 0, 0);
      final hojeFim = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);

      final ehHoje = (data.isAfter(hojeInicio) && data.isBefore(hojeFim)) || data.isAtSameMomentAs(hojeInicio) || data.isAtSameMomentAs(hojeFim);

      if (ehHoje) {
        return {'icone': Icons.flag_outlined, 'texto': 'HOJE', 'corFundo': Colors.black, 'corTexto': Colors.white};
      } else if (data.isBefore(hojeInicio)) {
        return {
          'icone': Icons.check_circle_outlined,
          'texto': 'REALIZADA',
          'corFundo': cs.primaryContainer,
          'corTexto': cs.onPrimaryContainer,
        };
      } else {
        return {'icone': Icons.event_note_outlined, 'texto': 'AGENDADO', 'corFundo': const Color(0x3328A745), 'corTexto': Colors.green};
      }
    } catch (_) {
      return {'icone': Icons.event_note_outlined, 'texto': 'AGENDADO', 'corFundo': const Color(0x3328A745), 'corTexto': Colors.green};
    }
  }

  String _formatarDataVisita(String? dataVisitaStr, String? horaVisitaStr) {
    if (dataVisitaStr == null || dataVisitaStr.isEmpty) return 'Data não informada';
    try {
      DateTime data = DateTime.parse(dataVisitaStr).toLocal();
      if (horaVisitaStr != null && horaVisitaStr.isNotEmpty) {
        final p = horaVisitaStr.split(':');
        final h = int.tryParse(p[0]) ?? 0;
        final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
        final s = p.length > 2 ? int.tryParse(p[2]) ?? 0 : 0;
        data = DateTime(data.year, data.month, data.day, h, m, s);
      }

      final hoje = DateTime.now();
      final amanha = DateTime(hoje.year, hoje.month, hoje.day + 1);
      final horaExibida = DateFormat('HH:mm').format(data);

      if (data.year == hoje.year && data.month == hoje.month && data.day == hoje.day) {
        return 'Hoje às $horaExibida';
      } else if (data.year == amanha.year && data.month == amanha.month && data.day == amanha.day) {
        return 'Amanhã às $horaExibida';
      } else {
        final format = data.year == hoje.year ? 'EEE, d MMMM' : 'EEE, d MMMM y';
        return '${_capitalize(DateFormat(format, 'pt_BR').format(data))} às $horaExibida';
      }
    } catch (_) {
      return 'Data inválida';
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _hideChipsOnly,
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverToBoxAdapter(child: _buildHeader()),

              SliverToBoxAdapter(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (!_showChips) setState(() => _showChips = true);
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pesquisar Visitas',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            decoration: _obterDecoracaoCampo(
                              'Nome da rua',
                              hint: 'Digite a rua para filtrar...',
                              suffixIcon: _query.isEmpty
                                  ? const Icon(Icons.search)
                                  : IconButton(icon: const Icon(Icons.clear), onPressed: _searchCtrl.clear, tooltip: 'Limpar'),
                            ),
                            onTap: () {
                              if (!_showChips) setState(() => _showChips = true);
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_ruasDisponiveis.isNotEmpty && _showChips)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _ruasDisponiveis.take(12).map((r) {
                                final selected = _query.isNotEmpty && r.toLowerCase() == _query.toLowerCase();
                                return FilterChip(
                                  label: Text(r, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  selected: selected,
                                  onSelected: (_) {
                                    _searchCtrl.text = r;
                                    _searchCtrl.selection = TextSelection.fromPosition(TextPosition(offset: r.length));
                                    if (!_showChips) setState(() => _showChips = true);
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _meusClientesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        children: [
                          _expansionSkeleton(title: 'Próximas Visitas'),
                          _expansionSkeleton(title: 'Finalizados'),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          _buildCard(title: 'Próximas Visitas', child: _errorBox(context, 'Erro: ${snapshot.error}')),
                          _buildCard(title: 'Finalizados', child: _errorBox(context, 'Erro: ${snapshot.error}')),
                        ],
                      );
                    }

                    final all = snapshot.data ?? [];

                    _ruasDisponiveis = _collectRuas(all);

                    final agora = DateTime.now();
                    final hojeIni = DateTime(agora.year, agora.month, agora.day, 0, 0, 0);

                    bool isPassado(Map<String, dynamic> c) {
                      final ds = c['data_visita']?.toString();
                      if (ds == null || ds.isEmpty) return false;
                      try {
                        DateTime d = DateTime.parse(ds).toLocal();
                        final hs = c['hora_visita']?.toString();
                        if (hs != null && hs.isNotEmpty) {
                          final p = hs.split(':');
                          final h = int.tryParse(p[0]) ?? 0;
                          final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
                          final s = p.length > 2 ? int.tryParse(p[2]) ?? 0 : 0;
                          d = DateTime(d.year, d.month, d.day, h, m, s);
                        } else {
                          d = DateTime(d.year, d.month, d.day, 0, 0, 0);
                        }
                        return d.isBefore(hojeIni);
                      } catch (_) {
                        return false;
                      }
                    }

                    bool matchesRua(Map<String, dynamic> c) {
                      final any = c['endereco'];
                      final rua = (any is String) ? any.toLowerCase() : (any?.toString().toLowerCase() ?? '');
                      if (_query.isEmpty) return true;
                      return rua.contains(_query.toLowerCase());
                    }

                    final base = all.where(matchesRua).toList();

                    _cacheProximas ??= base.where((c) => !isPassado(c)).toList();
                    _cacheFinalizados ??= base.where(isPassado).toList();

                    _cacheProximasWidget ??= _buildVisitasList(_cacheProximas!);
                    _cacheFinalizadosWidget ??= _buildVisitasList(_cacheFinalizados!);

                    final countProx = _cacheProximas!.length;
                    final countFin = _cacheFinalizados!.length;

                    return Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {}, 
                          child: _animatedExpansionCard(
                            title: 'Próximas Visitas ($countProx)',
                            expanded: _proxExpanded,
                            onChanged: (v) => setState(() => _proxExpanded = v),
                            child: _proxExpanded
                                ? (countProx == 0
                                    ? _emptyBox(context,
                                        icon: Icons.calendar_today_outlined,
                                        title: 'Nenhuma visita agendada',
                                        subtitle: _query.isEmpty ? 'Cadastre clientes para ver as visitas aqui' : 'Sem resultados para "${_query}"')
                                    : _cacheProximasWidget!)
                                : const SizedBox.shrink(),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {},
                          child: _animatedExpansionCard(
                            title: 'Finalizados ($countFin)',
                            expanded: _finExpanded,
                            onChanged: (v) => setState(() => _finExpanded = v),
                            child: _finExpanded
                                ? (countFin == 0
                                    ? _emptyBox(context,
                                        icon: Icons.check_circle_outline,
                                        title: 'Nenhuma visita finalizada',
                                        subtitle: _query.isEmpty ? 'As visitas concluídas aparecerão aqui' : 'Sem finalizados para "${_query}"')
                                    : _cacheFinalizadosWidget!)
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _collectRuas(List<Map<String, dynamic>> all) {
    final set = <String>{};
    for (final c in all) {
      final rawAny = c['endereco'];
      final raw = (rawAny is String) ? rawAny.trim() : (rawAny?.toString() ?? '').trim();
      if (raw.isEmpty) continue;
      final rua = _extractRua(raw);
      if (rua.isNotEmpty) set.add(rua);
    }
    final list = set.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  String _extractRua(String endereco) {
    var s = endereco;
    final comma = s.indexOf(',');
    if (comma > 0) s = s.substring(0, comma);
    s = s.replaceFirst(RegExp(r'\s+\d+.*$'), '');
    return s.trim();
  }

  Widget _buildVisitasList(List<Map<String, dynamic>> itens) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemBuilder: (_, i) => _buildVisitaItem(itens[i]),
    );
  }

  Widget _animatedExpansionCard({
    required String title,
    required bool expanded,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return _AnimatedSizeExpansionCard(
      title: title,
      expanded: expanded,
      onChanged: onChanged,
      child: child,
      vsync: this,
    );
  }

  Widget _expansionSkeleton({required String title}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _skeletonList(context),
        ]),
      ),
    );
  }

  Widget _skeletonList(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyBox(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _errorBox(BuildContext context, String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSizeExpansionCard extends StatefulWidget {
  final String title;
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final TickerProvider vsync;

  const _AnimatedSizeExpansionCard({
    required this.title,
    required this.expanded,
    required this.onChanged,
    required this.child,
    required this.vsync,
  });

  @override
  State<_AnimatedSizeExpansionCard> createState() => _AnimatedSizeExpansionCardState();
}

class _AnimatedSizeExpansionCardState extends State<_AnimatedSizeExpansionCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _turns;
  late bool _expandedLocal;

  @override
  void initState() {
    super.initState();
    _expandedLocal = widget.expanded;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _turns = Tween<double>(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (_expandedLocal) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedSizeExpansionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != _expandedLocal) {
      _toggle(explicit: widget.expanded);
    }
  }

  void _toggle({bool? explicit}) {
    setState(() {
      _expandedLocal = explicit ?? !_expandedLocal;
      if (_expandedLocal) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
      widget.onChanged(_expandedLocal);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  RotationTransition(
                    turns: _turns,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: _expandedLocal ? const BoxConstraints() : const BoxConstraints(maxHeight: 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

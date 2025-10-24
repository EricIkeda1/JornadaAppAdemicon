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

  bool _proxExpanded = true;
  bool _todosExpanded = false;
  bool _finExpanded  = false;

  bool _showChips = true;

  List<Map<String, dynamic>>? _cacheProximas;
  List<Map<String, dynamic>>? _cacheFinalizados;
  Map<String, List<Map<String, dynamic>>>? _cacheTodasAgrupado;

  final Set<String> _ruasTodas = <String>{};
  String? _ruaSelecionada; 

  @override
  void initState() {
    super.initState();
    _invalidateCaches();
    _searchCtrl.addListener(() {
      if (!mounted) return;
      setState(() {
        _query = _searchCtrl.text.trim();
        _showChips = true;
        _invalidateCaches();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _invalidateCaches() {
    _cacheProximas = null;
    _cacheFinalizados = null;
    _cacheTodasAgrupado = null;
  }

  Stream<List<Map<String, dynamic>>> get _meusClientesStream {
    final user = _client.auth.currentSession?.user;
    if (user == null) return const Stream<List<Map<String, dynamic>>>.empty();
    return _client
        .from('clientes')
        .select('*')
        .eq('consultor_uid_t', user.id)
        .order('data_visita', ascending: false)
        .order('hora_visita', ascending: false)
        .asStream();
  }

  Stream<List<Map<String, dynamic>>> get _todasVisitasStream {
    return _client
        .from('clientes')
        .select('id, estabelecimento, endereco, cidade, estado, data_visita, hora_visita, consultor_uid_t')
        .order('data_visita', ascending: false)
        .order('hora_visita', ascending: false)
        .asStream();
  }

  Future<void> _abrirNoGoogleMaps(String endereco) async {
    final q = Uri.encodeComponent(endereco.trim());
    final platform = Theme.of(context).platform;

    final androidGeo = Uri.parse('geo:0,0?q=$q');
    final androidWeb = Uri.parse('https://maps.google.com/?q=$q');
    final iosGmm = Uri.parse('comgooglemaps://?q=$q');
    final iosApple = Uri.parse('http://maps.apple.com/?q=$q');
    try {
      if (platform == TargetPlatform.android) {
        if (await canLaunchUrl(androidGeo)) { await launchUrl(androidGeo); return; }
        if (await canLaunchUrl(androidWeb)) { await launchUrl(androidWeb, mode: LaunchMode.externalApplication); return; }
      } else if (platform == TargetPlatform.iOS) {
        if (await canLaunchUrl(iosGmm)) { await launchUrl(iosGmm); return; }
        if (await canLaunchUrl(iosApple)) { await launchUrl(iosApple); return; }
      }
      final web = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
      final ok = await launchUrl(web, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o Maps')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o Maps: $e')),
        );
      }
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
        return '${_capitalize(DateFormat(format, "pt_BR").format(data))} às $horaExibida';
      }
    } catch (_) {
      return 'Data inválida';
    }
  }

  Map<String, dynamic> _determinarStatus(String? dataVisitaStr, {String? horaVisitaStr}) {
    final cs = Theme.of(context).colorScheme;
    if (dataVisitaStr == null || dataVisitaStr.isEmpty) {
      return {'icone': Icons.event_note_outlined, 'texto': 'AGENDADO', 'corFundo': const Color(0x3328A745), 'corTexto': Colors.green};
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
        return {'icone': Icons.check_circle_outlined, 'texto': 'REALIZADA', 'corFundo': cs.primaryContainer, 'corTexto': cs.onPrimaryContainer};
      } else {
        return {'icone': Icons.event_note_outlined, 'texto': 'AGENDADO', 'corFundo': const Color(0x3328A745), 'corTexto': Colors.green};
      }
    } catch (_) {
      return {'icone': Icons.event_note_outlined, 'texto': 'AGENDADO', 'corFundo': const Color(0x3328A745), 'corTexto': Colors.green};
    }
  }

  String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  InputDecoration _obterDecoracaoCampo(String label, {String? hint, Widget? suffixIcon}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 2)),
      suffixIcon: _query.isEmpty
          ? const Icon(Icons.search)
          : IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar',
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _query = '';
                  _ruaSelecionada = null;
                  _invalidateCaches();
                });
              },
            ),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
    );
  }

  Widget cleanCard({required Widget child, EdgeInsets? padding, EdgeInsets? margin}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: child,
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primaryContainer.withOpacity(0.35)),
            ),
            child: Icon(Icons.event_outlined, color: cs.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Minhas visitas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text('Agenda e status',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600, color: cs.onSurface)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCard({required String title, String? subtitle, required Widget child}) {
    return cleanCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle(title, subtitle: subtitle),
        child,
      ]),
    );
  }

  Widget _chipsDeBusca() {
    if (!_showChips) return const SizedBox.shrink();

    final termos = _ruasTodas.toList()..sort();
    final visiveis = termos.where((t) => _query.isEmpty || t.toLowerCase().contains(_query.toLowerCase())).toList();
    if (visiveis.isEmpty) return const SizedBox.shrink();

    const double alturaChips = 160;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          SizedBox(
            height: alturaChips,
            child: ScrollConfiguration(
              behavior: const _NoGlowBehavior(),
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in visiveis)
                      FilterChip(
                        label: Text(t, overflow: TextOverflow.ellipsis),
                        selected: _ruaSelecionada == t,
                        onSelected: (sel) {
                          if (!mounted) return;
                          setState(() {
                            if (sel && _ruaSelecionada != t) {
                              _ruaSelecionada = t;
                              _searchCtrl.text = t;
                              _query = t;
                              _showChips = false;   
                            } else {
                              _ruaSelecionada = null;
                              _searchCtrl.clear();
                              _query = '';
                            }
                            _invalidateCaches();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface.withOpacity(0.0),
                      Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matchChipsRua(Map<String, dynamic> c) {
    if (_ruaSelecionada == null || _ruaSelecionada!.isEmpty) return true;
    final any = c['endereco'];
    final rua = ((any is String) ? any : (any?.toString() ?? '')).toLowerCase();
    return rua.contains(_ruaSelecionada!.toLowerCase());
  }

  Widget _buildVisitaItem(Map<String, dynamic> c, {bool hideStatus = false}) {
    final cs = Theme.of(context).colorScheme;
    final endereco = ((c['endereco']?.toString()) ?? '').trim();
    final estabelecimento = ((c['estabelecimento']?.toString()) ?? '').trim().isEmpty
        ? 'Estabelecimento não informado'
        : ((c['estabelecimento']?.toString()) ?? '').trim();
    final cidade = ((c['cidade']?.toString()) ?? '').trim();
    final estado = ((c['estado']?.toString()) ?? '').trim();
    final dataStr = c['data_visita']?.toString();
    final horaStr = c['hora_visita']?.toString();

    final status = _determinarStatus(dataStr, horaVisitaStr: horaStr);
    final dataFmt = _formatarDataVisita(dataStr, horaStr);
    final enderecoCompleto = [
      if (endereco.isNotEmpty) endereco,
      if (cidade.isNotEmpty || estado.isNotEmpty) '$cidade - $estado',
    ].where((e) => e.trim().isNotEmpty).join(', ');

    return cleanCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.primaryContainer.withOpacity(0.35)),
          ),
          child: Icon(
            hideStatus ? Icons.place_outlined : (status['icone'] as IconData),
            size: 18,
            color: cs.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (!hideStatus) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status['corFundo'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status['texto'] as String,
                    style: TextStyle(color: status['corTexto'] as Color, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(
                estabelecimento,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              )),
            ]),
            if (enderecoCompleto.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                enderecoCompleto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                dataFmt,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Abrir no Maps',
                icon: const Icon(Icons.map_outlined, size: 18),
                onPressed: enderecoCompleto.trim().length > 3 ? () => _abrirNoGoogleMaps(enderecoCompleto) : null,
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildVisitasList(List<Map<String, dynamic>> itens, {bool hideStatus = false}) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemBuilder: (_, i) => _buildVisitaItem(itens[i], hideStatus: hideStatus),
    );
  }

  String _abreviarUidComoNome(String uid) {
    if (uid.isEmpty) return 'Consultor';
    return 'Consultor ${uid.substring(0, uid.length >= 6 ? 6 : uid.length)}';
  }

  Widget _buildTodasVisitasSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _todasVisitasStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _expansionSkeleton(title: 'Todas as visitas');
        }
        if (snap.hasError) {
          return _buildCard(title: 'Todas as visitas', child: _errorBox(context, 'Erro: ${snap.error}'));
        }

        final todos = snap.data ?? [];

        bool matchesTextoRua(Map<String, dynamic> c) {
          if (_query.isEmpty) return true;
          final any = c['endereco'];
          final rua = ((any is String) ? any : (any?.toString() ?? '')).toLowerCase();
          return rua.contains(_query.toLowerCase());
        }

        final filtrados = todos.where((c) => matchesTextoRua(c) && _matchChipsRua(c)).toList();

        if (_cacheTodasAgrupado == null) {
          final map = <String, List<Map<String, dynamic>>>{};
          for (final c in filtrados) {
            final uid = (c['consultor_uid_t']?.toString() ?? '');
            (map[uid] ??= []).add(c);
          }
          _cacheTodasAgrupado = map;
        }

        final grupos = _cacheTodasAgrupado!;
        return _animatedExpansionCard(
          title: 'Todas as visitas (${filtrados.length})',
          expanded: _todosExpanded,
          onChanged: (v) => setState(() => _todosExpanded = v),
          child: _todosExpanded
              ? Column(
                  children: grupos.entries.map((entry) {
                    final uid = entry.key;
                    final itens = entry.value;

                    return cleanCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(_abreviarUidComoNome(uid), subtitle: '${itens.length} visitas'),
                          _buildVisitasList(itens, hideStatus: true), 
                        ],
                      ),
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _expansionSkeleton({required String title}) {
    return cleanCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle(title),
        _skeletonList(context),
      ]),
    );
  }

  Widget _skeletonList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget block({double w = double.infinity, double h = 14}) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Column(
      children: List.generate(3, (i) => cleanCard(
        child: Row(children: [
          block(w: 36, h: 36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            block(w: 120, h: 12),
            const SizedBox(height: 8),
            block(),
          ])),
        ]),
      )),
    );
  }

  Widget _emptyBox(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _errorBox(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.error,
                  ),
            ),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final cs = baseTheme.colorScheme;

    final corporate = baseTheme.copyWith(
      chipTheme: baseTheme.chipTheme.copyWith(
        backgroundColor: cs.surfaceVariant.withOpacity(0.55),
        selectedColor: cs.primary.withOpacity(0.12),
        labelStyle: baseTheme.textTheme.bodySmall,
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return Theme(
      data: corporate,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
            if (_showChips) setState(() => _showChips = false);
          },
          child: Container(
            color: cs.background,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(child: _buildHeader()),

                SliverToBoxAdapter(
                  child: cleanCard(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pesquisar visitas', style: baseTheme.textTheme.titleSmall),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        decoration: _obterDecoracaoCampo(
                          'Nome da rua',
                          hint: 'Filtrar por rua...',
                        ),
                        onTap: () => setState(() => _showChips = true),
                        onSubmitted: (_) => setState(() => _showChips = false),
                      ),
                      _chipsDeBusca(),
                    ]),
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
                            _expansionSkeleton(title: 'Todas as visitas'),
                            _expansionSkeleton(title: 'Finalizados'),
                          ],
                        );
                      }

                      if (snapshot.hasError) {
                        return Column(
                          children: [
                            _buildCard(title: 'Próximas Visitas', child: _errorBox(context, 'Erro: ${snapshot.error}')),
                            _buildCard(title: 'Todas as visitas', child: _errorBox(context, 'Erro: ${snapshot.error}')),
                            _buildCard(title: 'Finalizados', child: _errorBox(context, 'Erro: ${snapshot.error}')),
                          ],
                        );
                      }

                      final all = snapshot.data ?? [];
                      _ruasTodas
                        ..clear()
                        ..addAll(all.map((c) => (c['endereco'] ?? '').toString()).where((s) => s.trim().isNotEmpty));

                      bool matchesTextoRua(Map<String, dynamic> c) {
                        if (_query.isEmpty) return true;
                        final any = c['endereco'];
                        final rua = ((any is String) ? any : (any?.toString() ?? '')).toLowerCase();
                        return rua.contains(_query.toLowerCase());
                      }

                      final base = all.where((c) => matchesTextoRua(c) && _matchChipsRua(c)).toList();

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

                      _cacheProximas ??= base.where((c) => !isPassado(c)).toList();
                      _cacheFinalizados ??= base.where(isPassado).toList();

                      final countProx = _cacheProximas!.length;
                      final countFin = _cacheFinalizados!.length;

                      return Column(
                        children: [
                          _animatedExpansionCard(
                            title: 'Próximas Visitas ($countProx)',
                            expanded: _proxExpanded,
                            onChanged: (v) => setState(() => _proxExpanded = v),
                            child: _proxExpanded
                                ? (countProx == 0
                                    ? _emptyBox(
                                        context,
                                        icon: Icons.calendar_today_outlined,
                                        title: 'Nenhuma visita agendada',
                                        subtitle: _query.isEmpty && (_ruaSelecionada == null || _ruaSelecionada!.isEmpty)
                                            ? 'Cadastre clientes para ver as visitas aqui'
                                            : 'Sem resultados para os filtros')
                                    : _buildVisitasList(_cacheProximas!))
                                : const SizedBox.shrink(),
                          ),
                          _buildTodasVisitasSection(),
                          _animatedExpansionCard(
                            title: 'Finalizados ($countFin)',
                            expanded: _finExpanded,
                            onChanged: (v) => setState(() => _finExpanded = v),
                            child: _finExpanded
                                ? (countFin == 0
                                    ? _emptyBox(
                                        context,
                                        icon: Icons.check_circle_outline,
                                        title: 'Nenhuma visita finalizada',
                                        subtitle: _query.isEmpty && (_ruaSelecionada == null || _ruaSelecionada!.isEmpty)
                                            ? 'As visitas concluídas aparecerão aqui'
                                            : 'Sem finalizados para os filtros')
                                    : _buildVisitasList(_cacheFinalizados!))
                                : const SizedBox.shrink(),
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
      ),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
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

class _AnimatedSizeExpansionCardState extends State<_AnimatedSizeExpansionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _turns;
  late bool _expandedLocal;

  @override
  void initState() {
    super.initState();
    _expandedLocal = widget.expanded;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _turns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
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
                  RotationTransition(turns: _turns, child: const Icon(Icons.expand_more)),
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

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
  bool _finExpanded = false;
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
    if (dataVisitaStr == null || dataVisitaStr.isEmpty) {
      return {
        'icone': Icons.schedule_outlined,
        'texto': 'AGENDADO',
        'corFundo': const Color(0xFF10B981),
        'corTexto': Colors.white
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
      final ehHoje = (data.isAfter(hojeInicio) && data.isBefore(hojeFim)) ||
          data.isAtSameMomentAs(hojeInicio) ||
          data.isAtSameMomentAs(hojeFim);
      
      if (ehHoje) {
        return {
          'icone': Icons.flag_outlined,
          'texto': 'HOJE',
          'corFundo': const Color(0xFF0EA5E9),
          'corTexto': Colors.white
        };
      } else if (data.isBefore(hojeInicio)) {
        return {
          'icone': Icons.check_circle_outline,
          'texto': 'REALIZADA',
          'corFundo': const Color(0xFF6366F1),
          'corTexto': Colors.white
        };
      } else {
        return {
          'icone': Icons.schedule_outlined,
          'texto': 'AGENDADO',
          'corFundo': const Color(0xFF10B981),
          'corTexto': Colors.white
        };
      }
    } catch (_) {
      return {
        'icone': Icons.schedule_outlined,
        'texto': 'AGENDADO',
        'corFundo': const Color(0xFF10B981),
        'corTexto': Colors.white
      };
    }
  }

  String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  InputDecoration _obterDecoracaoCampo(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: Color(0xFFFF0000),
          width: 2.5,
        ),
      ),
      suffixIcon: _query.isEmpty
          ? const Icon(Icons.search, color: Color(0xFF64748B))
          : IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _query = '';
                  _ruaSelecionada = null;
                  _invalidateCaches();
                });
              },
            ),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    );
  }

  Widget _cleanCard({required Widget child, EdgeInsets? padding, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minhas Visitas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gerencie sua agenda profissional',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsDeBusca() {
    if (!_showChips) return const SizedBox.shrink();

    final termos = _ruasTodas.toList()..sort();
    final visiveis = termos.where((t) => _query.isEmpty || t.toLowerCase().contains(_query.toLowerCase())).toList();
    if (visiveis.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 140,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in visiveis)
                Material(
                  color: _ruaSelecionada == t ? const Color(0xFF0EA5E9) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        if (_ruaSelecionada != t) {
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _ruaSelecionada == t ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: _ruaSelecionada == t ? Colors.white : const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: _ruaSelecionada == t ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchChipsRua(Map<String, dynamic> c) {
    if (_ruaSelecionada == null || _ruaSelecionada!.isEmpty) return true;
    final any = c['endereco'];
    final rua = ((any is String) ? any : (any?.toString() ?? '')).toLowerCase();
    return rua.contains(_ruaSelecionada!.toLowerCase());
  }

  Widget _buildVisitaItem(Map<String, dynamic> c) {
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

    return _cleanCard(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (status['corFundo'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              status['icone'] as IconData,
              size: 20,
              color: status['corFundo'] as Color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: status['corFundo'] as Color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status['texto'] as String,
                        style: TextStyle(
                          color: status['corTexto'] as Color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        estabelecimento,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                if (enderecoCompleto.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          enderecoCompleto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      dataFmt,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (enderecoCompleto.trim().length > 3)
                      Material(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _abrirNoGoogleMaps(enderecoCompleto),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitasList(List<Map<String, dynamic>> itens) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itens.length,
      padding: EdgeInsets.zero,
      itemBuilder: (_, i) => _buildVisitaItem(itens[i]),
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
          return _errorBox('Erro: ${snap.error}');
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
          title: 'Todas as visitas',
          subtitle: '${filtrados.length} registros',
          icon: Icons.groups_outlined,
          iconColor: const Color(0xFF0EA5E9),
          expanded: _todosExpanded,
          onChanged: (v) => setState(() => _todosExpanded = v),
          child: _todosExpanded
              ? Column(
                  children: grupos.entries.map((entry) {
                    final uid = entry.key;
                    final itens = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0EA5E9),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _abreviarUidComoNome(uid),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${itens.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildVisitasList(itens),
                      ],
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _expansionSkeleton({required String title}) {
    return _cleanCard(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            2,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedExpansionCard({
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    required bool expanded,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return _AnimatedSizeExpansionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      expanded: expanded,
      onChanged: onChanged,
      child: child,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_showChips) setState(() => _showChips = false);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: _cleanCard(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesquisar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      decoration: _obterDecoracaoCampo(
                        'Nome da rua',
                        hint: 'Digite para filtrar...',
                      ),
                      onTap: () => setState(() => _showChips = true),
                      onSubmitted: (_) => setState(() => _showChips = false),
                    ),
                    _chipsDeBusca(),
                  ],
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
                        _expansionSkeleton(title: 'Todas as visitas'),
                        _expansionSkeleton(title: 'Finalizados'),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return _errorBox('Erro: ${snapshot.error}');
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
                        title: 'Próximas Visitas',
                        subtitle: '$countProx agendadas',
                        icon: Icons.event_available_outlined,
                        iconColor: const Color(0xFF10B981),
                        expanded: _proxExpanded,
                        onChanged: (v) => setState(() => _proxExpanded = v),
                        child: _proxExpanded
                            ? (countProx == 0
                                ? _emptyBox(
                                    icon: Icons.calendar_today_outlined,
                                    title: 'Nenhuma visita agendada',
                                    subtitle: _query.isEmpty && (_ruaSelecionada == null || _ruaSelecionada!.isEmpty)
                                        ? 'Cadastre clientes para agendar visitas'
                                        : 'Nenhum resultado encontrado')
                                : _buildVisitasList(_cacheProximas!))
                            : const SizedBox.shrink(),
                      ),
                      _buildTodasVisitasSection(),
                      _animatedExpansionCard(
                        title: 'Finalizados',
                        subtitle: '$countFin concluídas',
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF6366F1),
                        expanded: _finExpanded,
                        onChanged: (v) => setState(() => _finExpanded = v),
                        child: _finExpanded
                            ? (countFin == 0
                                ? _emptyBox(
                                    icon: Icons.check_circle_outline,
                                    title: 'Nenhuma visita finalizada',
                                    subtitle: _query.isEmpty && (_ruaSelecionada == null || _ruaSelecionada!.isEmpty)
                                        ? 'Visitas concluídas aparecerão aqui'
                                        : 'Nenhum resultado encontrado')
                                : _buildVisitasList(_cacheFinalizados!))
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSizeExpansionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final TickerProvider vsync;

  const _AnimatedSizeExpansionCard({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _turns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (widget.iconColor ?? const Color(0xFF0EA5E9)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: widget.iconColor ?? const Color(0xFF0EA5E9),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _turns,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: _expandedLocal ? const BoxConstraints() : const BoxConstraints(maxHeight: 0.0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

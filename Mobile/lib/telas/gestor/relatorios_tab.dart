import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Cliente {
  final String id;
  final String nomeCliente;
  final String telefone;
  final String estabelecimento;
  final String estado;
  final String cidade;
  final String endereco;
  final String? bairro;
  final String? cep;
  final DateTime dataVisita;
  final String? horaVisita;
  final String? observacoes;
  final String? consultorResponsavel;
  final String consultorUid;

  Cliente({
    required this.id,
    required this.nomeCliente,
    required this.telefone,
    required this.estabelecimento,
    required this.estado,
    required this.cidade,
    required this.endereco,
    required this.bairro,
    required this.cep,
    required this.dataVisita,
    required this.horaVisita,
    required this.observacoes,
    required this.consultorResponsavel,
    required this.consultorUid,
  });

  static Cliente fromMap(Map<String, dynamic> m) {
    return Cliente(
      id: (m['id'] ?? '').toString(),
      nomeCliente: (m['nome'] ?? '').toString(),
      telefone: (m['telefone'] ?? '').toString(),
      estabelecimento: (m['estabelecimento'] ?? '').toString(),
      estado: (m['estado'] ?? '').toString(),
      cidade: (m['cidade'] ?? '').toString(),
      endereco: (m['endereco'] ?? '').toString(),
      bairro: (m['bairro'] as String?),
      cep: (m['cep'] as String?),
      dataVisita: DateTime.tryParse((m['data_visita'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      horaVisita: (m['hora_visita'] as String?),
      observacoes: (m['observacoes'] as String?),
      consultorResponsavel: (m['responsavel'] as String?),
      consultorUid: (m['consultor_uid_t'] ?? '').toString(),
    );
  }
}

class RelatoriosTabGestor extends StatefulWidget {
  const RelatoriosTabGestor({super.key});

  @override
  State<RelatoriosTabGestor> createState() => _RelatoriosTabGestorState();
}

class _RelatoriosTabGestorState extends State<RelatoriosTabGestor> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _loading = true;
  List<Cliente> _clientes = [];

  @override
  void initState() {
    super.initState();
    _loadClientesDoTime();
  }

  Future<void> _loadClientesDoTime() async {
    final gestorId = _client.auth.currentSession?.user.id;
    if (gestorId == null) {
      setState(() {
        _loading = false;
        _clientes = [];
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final consultores = await _client
          .from('consultores')
          .select('uid')
          .eq('gestor_id', gestorId);

      final uids = (consultores as List)
          .map((e) => (e['uid'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();

      if (uids.isEmpty) {
        setState(() {
          _clientes = [];
          _loading = false;
        });
        return;
      }

      final inList = '("${uids.map((e) => e.replaceAll('"', '\\"')).join('","')}")';

      final data = await _client
          .from('clientes')
          .select('id, nome, telefone, estabelecimento, estado, cidade, endereco, bairro, cep, data_visita, hora_visita, observacoes, responsavel, consultor_uid_t')
          .filter('consultor_uid_t', 'in', inList); 

      final parsed = <Cliente>[];
      if (data is List) {
        for (final m in data) {
          parsed.add(Cliente.fromMap(Map<String, dynamic>.from(m)));
        }
      }

      setState(() {
        _clientes = parsed;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar clientes: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            if (_loading)
              _buildLoadingCard(context)
            else ...[
              _buildExportCard(context),
              const SizedBox(height: 16),
              _buildResumoCard(context),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.import_export_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exportar Dados (Gestor)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Exporte os clientes de todo o seu time.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(width: 8),
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Carregando dados do time...')),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.table_chart_outlined, color: Theme.of(context).colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exportar para CSV',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Baixe os dados de clientes do seu time (gestor) em CSV para Excel/Sheets.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _clientes.isEmpty
                        ? null
                        : () async {
                            try {
                              final csv = _buildCsv(_clientes);
                              final path = await _saveCsvToTemp(csv);
                              await Share.shareXFiles(
                                [XFile(path, mimeType: 'text/csv', name: 'clientes_time_export.csv')],
                                text: 'Clientes do time exportados',
                              ); 
                              _showSnack(context, 'Arquivo CSV gerado e pronto para compartilhar.');
                            } catch (e) {
                              _showSnack(context, 'Falha ao exportar: $e', color: Colors.red);
                            }
                          },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Baixar CSV'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clientes.isEmpty
                        ? null
                        : () async {
                            try {
                              final csv = _buildCsv(_clientes);
                              await Clipboard.setData(ClipboardData(text: csv)); // copiar para clipboard [web:276]
                              _showSnack(context, 'CSV copiado para a área de transferência.');
                            } catch (e) {
                              _showSnack(context, 'Falha ao copiar: $e', color: Colors.red);
                            }
                          },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copiar'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
            if (_clientes.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Sem clientes para exportar. Verifique as permissões RLS e o time do gestor.',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Resumo da Exportação', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat(
                  context,
                  icon: Icons.people_alt_outlined,
                  label: 'Clientes',
                  value: _clientes.length.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildStat(
                  context,
                  icon: Icons.table_chart,
                  label: 'Formato',
                  value: 'CSV',
                  color: Colors.green,
                ),
              ],
            ),
            if (_clientes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhum cliente disponível para exportar.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }

  String _buildCsv(List<Cliente> dados) {
    final headers = [
      'id',
      'nome',
      'telefone',
      'estabelecimento',
      'estado',
      'cidade',
      'endereco',
      'bairro',
      'cep',
      'data_visita',
      'hora_visita',
      'observacoes',
      'responsavel',
      'consultor_uid_t',
    ];
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    for (final c in dados) {
      final row = [
        c.id,
        c.nomeCliente,
        c.telefone,
        c.estabelecimento,
        c.estado,
        c.cidade,
        c.endereco,
        c.bairro ?? '',
        c.cep ?? '',
        c.dataVisita.toIso8601String(),
        c.horaVisita ?? '',
        c.observacoes ?? '',
        c.consultorResponsavel ?? '',
        c.consultorUid,
      ].map(_escapeCsv).join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  String _escapeCsv(String value) {
    var v = value;
    final needsQuote = v.contains(',') || v.contains('\n') || v.contains('"');
    if (v.contains('"')) {
      v = v.replaceAll('"', '""');
    }
    return needsQuote ? '"$v"' : v;
  }

  Future<String> _saveCsvToTemp(String csv) async {
    final dir = await getTemporaryDirectory(); 
    final safeName = 'clientes_time_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$safeName');
    await file.writeAsString(csv, encoding: utf8, flush: true);
    return file.path;
  }

  void _showSnack(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
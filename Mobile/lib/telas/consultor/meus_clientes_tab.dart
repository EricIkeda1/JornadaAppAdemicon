import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MeusClientesTab extends StatefulWidget {
  final Function onClienteRemovido;

  const MeusClientesTab({super.key, required this.onClienteRemovido});

  @override
  State<MeusClientesTab> createState() => _MeusClientesTabState();
}

class _MeusClientesTabState extends State<MeusClientesTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final SupabaseClient _client = Supabase.instance.client;

  // Abreviações e tipos de logradouro
  final Map<String, String> _abbr = const {
    'Avenida': 'Av.',
    'Rua': 'R.',
    'Alameda': 'Al.',
    'Travessa': 'Tv.',
    'Rodovia': 'Rod.',
    'Estrada': 'Est.',
    'Praça': 'Pç.',
    'Largo': 'Lg.',
    'Via': 'Via',
  };
  final List<String> _tiposLogradouro = const [
    'Rua','Avenida','Alameda','Travessa','Rodovia','Estrada','Praça','Via','Largo'
  ];

  final List<Map<String, String>> _statusOptions = const [
    {'label': 'Conexão',    'value': 'conexao'},
    {'label': 'Negociação', 'value': 'negociacao'},
    {'label': 'Fechada',    'value': 'fechada'},
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim()));
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
        .order('data_visita', ascending: true)
        .asStream();
  }

  InputDecoration _decoracaoCampo(BuildContext context, String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: suffixIcon,
      isDense: true,
    );
  }

  String _statusLabel(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'conexao':
        return 'Conexão';
      case 'negociacao':
        return 'Negociação';
      case 'fechada':
        return 'Fechada';
      default:
        return '—';
    }
  }

  Color _statusColor(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'conexao':
        return Colors.blue;
      case 'negociacao':
        return Colors.orange;
      case 'fechada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: _obterDecoracaoCampo(
                  context,
                  'Buscar clientes',
                  hint: 'Digite nome, endereço, bairro, cidade ou status...',
                  suffixIcon: _query.isEmpty
                      ? const Icon(Icons.search)
                      : IconButton(icon: const Icon(Icons.clear), onPressed: _searchCtrl.clear, tooltip: 'Limpar'),
                ),
              ),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _meusClientesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text('Erro: ${snapshot.error}')));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: _buildEmptyState()));
              }

              final clientes = snapshot.data!;
              final q = _query.toLowerCase();
              final clientesFiltrados = _query.isEmpty
                  ? clientes
                  : clientes.where((c) {
                      final estabelecimento = (c['estabelecimento']?.toString().toLowerCase() ?? '');
                      final endereco = (c['endereco']?.toString().toLowerCase() ?? '');
                      final bairro = (c['bairro']?.toString().toLowerCase() ?? '');
                      final cidade = (c['cidade']?.toString().toLowerCase() ?? '');
                      final status = (c['status_negociacao']?.toString().toLowerCase() ?? '');
                      final valor = (c['valor_proposta']?.toString().toLowerCase() ?? '');
                      return estabelecimento.contains(q) ||
                          endereco.contains(q) ||
                          bairro.contains(q) ||
                          cidade.contains(q) ||
                          status.contains(q) ||
                          valor.contains(q);
                    }).toList();

              if (clientesFiltrados.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('Nenhum cliente encontrado', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildClienteItem(clientesFiltrados[index]),
                  childCount: clientesFiltrados.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  InputDecoration _obterDecoracaoCampo(BuildContext context, String label, {String? hint, Widget? suffixIcon}) =>
      _decoracaoCampo(context, label, hint: hint, suffixIcon: suffixIcon);

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
            child: Icon(Icons.people_outline_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Meus Clientes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
              const SizedBox(height: 4),
              Text('Gerencie sua lista de clientes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Nenhum cliente cadastrado', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text('Cadastre seus primeiros clientes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildClienteItem(Map<String, dynamic> c) {
    final String estabelecimento = c['estabelecimento'] ?? 'Cliente';
    final String endereco = '${c['endereco'] ?? ''}, ${c['bairro'] ?? ''}';
    final String cidade = '${c['cidade'] ?? ''} - ${c['estado'] ?? ''}';

    final String? dataVisitaStr = c['data_visita'] as String?;
    final DateTime? dataVisita = dataVisitaStr != null ? DateTime.tryParse(dataVisitaStr) : null;

    final bool visitaPassada = dataVisita != null && dataVisita.isBefore(DateTime.now());
    final bool visitaHoje = dataVisita != null &&
        dataVisita.year == DateTime.now().year &&
        dataVisita.month == DateTime.now().month &&
        dataVisita.day == DateTime.now().day;

    String dataFormatada = 'Data não informada';
    if (dataVisita != null) {
      final formatter = DateFormat('dd/MM/yyyy');
      dataFormatada = 'Próxima visita: ${formatter.format(dataVisita)}';
    }

    final String statusTec = (c['status_negociacao'] ?? '').toString();
    final String statusLabel = _statusLabel(statusTec);
    final Color statusColor = _statusColor(statusTec);
    final num? valorProposta = c['valor_proposta'] as num?;
    final String valorFmt = valorProposta != null ? NumberFormat.simpleCurrency(locale: 'pt_BR').format(valorProposta) : '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _editarCliente(c),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visitaPassada
                      ? Colors.grey.shade200
                      : visitaHoje
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  visitaPassada ? Icons.check_circle : visitaHoje ? Icons.flag : Icons.schedule,
                  color: visitaPassada ? Colors.grey : visitaHoje ? Colors.red : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(estabelecimento, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(endereco, style: Theme.of(context).textTheme.bodySmall),
                    Text(cidade, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          label: Text(statusLabel),
                          backgroundColor: statusColor.withOpacity(0.1),
                          labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Text(
                          'Proposta: $valorFmt',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dataFormatada,
                      style: TextStyle(
                        fontSize: 12,
                        color: dataVisita == null
                            ? Colors.grey
                            : visitaPassada
                                ? Colors.grey
                                : visitaHoje
                                    ? Colors.red
                                    : Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmar exclusão'),
                      content: Text('Tem certeza que deseja excluir $estabelecimento?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirmar == true) {
                    try {
                      await _client.from('clientes').delete().eq('id', c['id']);
                      widget.onClienteRemovido();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cliente excluído com sucesso'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao excluir cliente: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editarCliente(Map<String, dynamic> c) async {
    final formKey = GlobalKey<FormState>();

    // Controllers pré-preenchidos
    final statusTec = (c['status_negociacao'] ?? '').toString();
    final valorProposta = (c['valor_proposta'] as num?)?.toString() ?? '';
    final bairro = (c['bairro'] ?? '').toString();
    final cidade = (c['cidade'] ?? '').toString();
    final estado = (c['estado'] ?? '').toString();
    final numero = (c['numero'] ?? '').toString();
    final complemento = (c['complemento'] ?? '').toString();
    final observacoes = (c['observacoes'] ?? '').toString();

    final logradouroAtual = (c['logradouro'] ?? '').toString(); // ex.: "Av. Paraná"
    // Tenta separar tipo e nome a partir do logradouro salvo (abreviado)
    String? tipoInicial;
    String nomeViaInicial = logradouroAtual;
    for (final entry in _abbr.entries) {
      final ab = entry.value;
      if (logradouroAtual.startsWith('$ab ')) {
        tipoInicial = entry.key; // valor cheio para o dropdown
        nomeViaInicial = logradouroAtual.substring(ab.length).trim();
        break;
      }
    }

    String? _tipoLogradouroEd = tipoInicial;
    final nomeViaCtrl = TextEditingController(text: nomeViaInicial);
    final numeroCtrl = TextEditingController(text: numero);
    final bairroCtrl = TextEditingController(text: bairro);
    final cidadeCtrl = TextEditingController(text: cidade);
    final estadoCtrl = TextEditingController(text: estado);
    final complementoCtrl = TextEditingController(text: complemento);
    final valorCtrl = TextEditingController(text: valorProposta);
    final observacoesCtrl = TextEditingController(text: observacoes);
    String? _statusTecEd = statusTec.isEmpty ? null : statusTec;

    String montarLogradouro(String? tipoCheio, String nomeVia) {
      final ab = _abbr[tipoCheio ?? ''] ?? (tipoCheio ?? '');
      return [ab, nomeVia.trim()].where((e) => e.isNotEmpty).join(' ');
    }

    String montarEnderecoLegado(String logradouro, String numero, String complemento) {
      final partes = <String>[];
      if (logradouro.isNotEmpty) partes.add(logradouro);
      if (numero.trim().isNotEmpty) partes.add(numero.trim());
      if (complemento.trim().isNotEmpty) partes.add('(${complemento.trim()})');
      return partes.join(' ');
    }

    String? validarObrigatorio(String? v, String nome) => (v == null || v.trim().isEmpty) ? '$nome é obrigatório' : null;

    String? validarValor(String? v) {
      final raw = (v ?? '').trim();
      if (raw.isEmpty) return null;
      final norm = raw.replaceAll('.', '').replaceAll(',', '.');
      final parsed = num.tryParse(norm);
      if (parsed == null) return 'Valor inválido';
      if (parsed < 0) return 'Valor não pode ser negativo';
      return null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.edit_location_alt_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c['estabelecimento'] ?? c['nome'] ?? 'Cliente',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context), tooltip: 'Fechar')
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status e Valor
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _statusTecEd,
                            items: _statusOptions
                                .map((s) => DropdownMenuItem<String>(value: s['value']!, child: Text(s['label']!)))
                                .toList(),
                            onChanged: (v) => _statusTecEd = v,
                            decoration: _obterDecoracaoCampo(context, 'Status'),
                            validator: (v) => v == null || v.isEmpty ? 'Status é obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: valorCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _obterDecoracaoCampo(context, 'Valor da proposta', hint: 'Ex: 1500,00'),
                            validator: validarValor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Logradouro (Tipo + Nome) e Número
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _tipoLogradouroEd,
                            items: _tiposLogradouro.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            selectedItemBuilder: (context) {
                              return _tiposLogradouro.map((e) {
                                final abreviado = _abbr[e] ?? e;
                                return Align(alignment: Alignment.centerLeft, child: Text(abreviado, overflow: TextOverflow.ellipsis));
                              }).toList();
                            },
                            onChanged: (v) => _tipoLogradouroEd = v,
                            decoration: _obterDecoracaoCampo(context, 'Tipo'),
                            validator: (v) => v == null || v.isEmpty ? 'Tipo é obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: nomeViaCtrl,
                            decoration: _obterDecoracaoCampo(context, 'Nome da via', hint: 'Ex: Paraná'),
                            validator: (v) => validarObrigatorio(v, 'Nome da via'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: numeroCtrl,
                            decoration: _obterDecoracaoCampo(context, 'Número', hint: '123'),
                            validator: (v) => validarObrigatorio(v, 'Número'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Bairro e Cidade/Estado
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: bairroCtrl,
                            decoration: _obterDecoracaoCampo(context, 'Bairro', hint: 'Jardim ...'),
                            validator: (v) => validarObrigatorio(v, 'Bairro'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: cidadeCtrl,
                            decoration: _obterDecoracaoCampo(context, 'Cidade', hint: 'Londrina'),
                            validator: (v) => validarObrigatorio(v, 'Cidade'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            controller: estadoCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _obterDecoracaoCampo(context, 'UF', hint: 'PR'),
                            validator: (v) {
                              final x = v?.trim().toUpperCase() ?? '';
                              if (x.isEmpty) return 'UF é obrigatório';
                              if (x.length != 2) return 'UF deve ter 2 letras';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Complemento
                    TextFormField(
                      controller: complementoCtrl,
                      decoration: _obterDecoracaoCampo(context, 'Complemento', hint: 'Ap, bloco, casa, sala'),
                    ),
                    const SizedBox(height: 12),

                    // Observações
                    TextFormField(
                      controller: observacoesCtrl,
                      maxLines: 3,
                      decoration: _obterDecoracaoCampo(context, 'Observações', hint: 'Notas sobre a negociação'),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;

                          // normaliza valor
                          num? valor;
                          final raw = valorCtrl.text.trim();
                          if (raw.isNotEmpty) {
                            final norm = raw.replaceAll('.', '').replaceAll(',', '.');
                            valor = num.tryParse(norm);
                          }

                          final logradouroNovo = montarLogradouro(_tipoLogradouroEd, nomeViaCtrl.text);
                          final enderecoLegado = montarEnderecoLegado(logradouroNovo, numeroCtrl.text, complementoCtrl.text);

                          try {
                            await _client.from('clientes').update({
                              'status_negociacao': _statusTecEd,
                              'valor_proposta': valor,
                              'logradouro': logradouroNovo,
                              'numero': numeroCtrl.text.trim(),
                              'bairro': bairroCtrl.text.trim(),
                              'cidade': cidadeCtrl.text.trim(),
                              'estado': estadoCtrl.text.trim().toUpperCase(),
                              'complemento': complementoCtrl.text.trim().isEmpty ? null : complementoCtrl.text.trim(),
                              'endereco': enderecoLegado,
                              'observacoes': observacoesCtrl.text.trim().isEmpty ? null : observacoesCtrl.text.trim(),
                            }).eq('id', c['id']);

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cliente atualizado com sucesso'), backgroundColor: Colors.green),
                              );
                              setState(() {}); // força rebuild para refletir mudanças no Stream
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar alterações'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

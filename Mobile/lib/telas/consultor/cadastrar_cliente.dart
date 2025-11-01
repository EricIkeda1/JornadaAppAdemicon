import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:ademicon_app/models/cliente.dart';
import 'package:ademicon_app/services/cliente_service.dart';
import 'package:ademicon_app/services/notification_service.dart';

class CadastrarCliente extends StatefulWidget {
  final Function()? onClienteCadastrado;
  const CadastrarCliente({super.key, this.onClienteCadastrado});

  @override
  State<CadastrarCliente> createState() => _CadastrarClienteState();
}

class _CadastrarClienteState extends State<CadastrarCliente> {
  final _formKey = GlobalKey<FormState>();
  final _client = Supabase.instance.client;

  final _nomeClienteCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _nomeEstabelecimentoCtrl = TextEditingController();

  final _estadoCtrl = TextEditingController(); 
  final _cidadeCtrl = TextEditingController();

  final _bairroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController(); 

  String? _tipoLogradouro; 
  final _nomeViaCtrl = TextEditingController(); 
  final _numeroCtrl = TextEditingController(); 
  final _cepCtrl = TextEditingController();   

  String? _statusNegociacao;
  final _valorPropostaCtrl = TextEditingController();
  final _dataNegociacaoCtrl = TextEditingController();
  final _horaNegociacaoCtrl = TextEditingController();

  final _dataVisitaCtrl = TextEditingController();
  final _horaVisitaCtrl = TextEditingController();

  final _observacoesCtrl = TextEditingController();

  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'\d')},
    type: MaskAutoCompletionType.lazy,
  );

  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'\d')},
    type: MaskAutoCompletionType.lazy,
  );

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
    {'label': 'Conexão',   'value': 'conexao'},
    {'label': 'Negociação','value': 'negociacao'},
    {'label': 'Fechada',   'value': 'fechada'},
  ];

  bool _isLoading = false;

  String _norm(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

  @override
  void initState() {
    super.initState();
    _dataVisitaCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _horaVisitaCtrl.text = DateFormat('HH:mm').format(DateTime.now());
    _dataNegociacaoCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _horaNegociacaoCtrl.text = DateFormat('HH:mm').format(DateTime.now());
  }

  @override
  void dispose() {
    _nomeClienteCtrl.dispose();
    _telefoneCtrl.dispose();
    _nomeEstabelecimentoCtrl.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _bairroCtrl.dispose();
    _complementoCtrl.dispose();
    _nomeViaCtrl.dispose();
    _numeroCtrl.dispose();
    _cepCtrl.dispose();
    _valorPropostaCtrl.dispose();
    _dataNegociacaoCtrl.dispose();
    _horaNegociacaoCtrl.dispose();
    _dataVisitaCtrl.dispose();
    _horaVisitaCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      _dataNegociacaoCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _selecionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _horaNegociacaoCtrl.text = picked.format(context);
    }
  }

  String? _validarCampoObrigatorio(String? v, {String field = 'Campo'}) {
    if (v == null || v.trim().isEmpty) return '$field é obrigatório';
    return null;
  }

  String? _validarUF(String? v) {
    final x = v?.trim().toUpperCase() ?? '';
    if (x.isEmpty) return 'Estado é obrigatório';
    if (x.length != 2) return 'UF deve ter 2 letras';
    return null;
  }

  String? _validarCEP(String? v) {
    final raw = (v ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (raw.isEmpty) return 'CEP é obrigatório';
    if (raw.length != 8) return 'CEP deve ter 8 dígitos';
    return null;
  }

  String? _validarValorProposta(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return null;
    final norm = raw.replaceAll('.', '').replaceAll(',', '.');
    final parsed = num.tryParse(norm);
    if (parsed == null) return 'Valor inválido';
    if (parsed < 0) return 'Valor não pode ser negativo';
    return null;
  }

  InputDecoration _obterDecoracaoCampo(
    String label, {
    String? hint,
    Widget? suffixIcon,
    bool isObrigatorio = true,
  }) {
    return InputDecoration(
      labelText: '$label${isObrigatorio ? ' *' : ''}',
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _salvarCliente() async {
    if (_formKey.currentState?.validate() != true) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final dataStr = _dataVisitaCtrl.text.trim();
      final horaStr = _horaVisitaCtrl.text.trim();

      late DateTime dataHora;
      try {
        final h = DateFormat('HH:mm').parse(horaStr);
        final horaPadrao = DateFormat('HH:mm').format(h);
        dataHora = DateFormat('dd/MM/yyyy HH:mm').parse('$dataStr $horaPadrao');
      } on FormatException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data ou hora inválida. Use o formato correto.')),
        );
        return;
      }

      final session = _client.auth.currentSession;
      if (session == null || session.user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: sessão expirada. Faça login novamente.')),
        );
        return;
      }

      final userId = session.user!.id;
      final consultorNomeLocal = session.user!.email ?? 'Desconhecido';

      final tipoCheio = (_tipoLogradouro ?? '').trim();
      final tipoAbreviado = _abbr[tipoCheio] ?? tipoCheio; // "Rua" ou "R."
      final nomeVia = _norm(_nomeViaCtrl.text);

      final logradouroTipo = tipoAbreviado; // apenas o tipo
      final enderecoNome  = nomeVia;        // apenas o nome

      final numeroStr = _numeroCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
      final int? numeroInt = numeroStr.isEmpty ? null : int.tryParse(numeroStr);
      if (numeroInt == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um número válido.')),
        );
        return;
      }

      num? valorProposta;
      final rawValor = _valorPropostaCtrl.text.trim();
      if (rawValor.isNotEmpty) {
        final norm = rawValor.replaceAll('.', '').replaceAll(',', '.');
        valorProposta = num.tryParse(norm);
      }

      final cliente = Cliente(
        id: const Uuid().v4(),
        nomeCliente: _norm(_nomeClienteCtrl.text),
        telefone: _telefoneCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
        estabelecimento: _norm(_nomeEstabelecimentoCtrl.text),
        estado: _estadoCtrl.text.trim().toUpperCase(),
        cidade: _norm(_cidadeCtrl.text),
        endereco: enderecoNome,          // "Tiradentes"
        logradouro: logradouroTipo,      // "Av." ou "R."
        numero: numeroInt,               // int
        complemento: _complementoCtrl.text.trim().isEmpty ? null : _norm(_complementoCtrl.text),
        bairro: _norm(_bairroCtrl.text),
        cep: _cepCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
        dataVisita: dataHora,
        observacoes: _observacoesCtrl.text.trim().isEmpty ? null : _norm(_observacoesCtrl.text),
        consultorResponsavel: consultorNomeLocal,
        consultorUid: userId,
        horaVisita: horaStr,
        statusNegociacao: _statusNegociacao,
        valorProposta: valorProposta,
      );

      final persistedNow = await ClienteService.instance.saveCliente(cliente);

      if (!mounted) return;

      if (persistedNow) {
        await NotificationService.showSuccessNotification();
        widget.onClienteCadastrado?.call();
        _limparCampos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Endereço já cadastrado (tipo + número).')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await NotificationService.showErrorNotification('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _limparCampos() {
    _formKey.currentState?.reset();

    _nomeClienteCtrl.clear();
    _telefoneCtrl.clear();
    _nomeEstabelecimentoCtrl.clear();
    _estadoCtrl.clear();
    _cidadeCtrl.clear();
    _bairroCtrl.clear();
    _complementoCtrl.clear();
    _nomeViaCtrl.clear();
    _numeroCtrl.clear();
    _cepCtrl.clear();
    _valorPropostaCtrl.clear();
    _observacoesCtrl.clear();

    _tipoLogradouro = null;
    _statusNegociacao = null;

    _dataNegociacaoCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _horaNegociacaoCtrl.text = DateFormat('HH:mm').format(DateTime.now());
    _dataVisitaCtrl.text      = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _horaVisitaCtrl.text      = DateFormat('HH:mm').format(DateTime.now());

    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width <= 420;
    final dropItemHeight = isNarrow ? 52.0 : 40.0;
    final dropMenuMax = isNarrow ? 360.0 : 300.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _limparCampos(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
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
                      child: Icon(
                        Icons.add_business_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cadastrar Cliente',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Preencha os dados do cliente',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Dados do Cliente',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _nomeClienteCtrl,
                              decoration: _obterDecoracaoCampo('Nome do Cliente', hint: 'Nome completo'),
                              validator: (v) => _validarCampoObrigatorio(v, field: 'Nome do cliente'),
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _telefoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [_telefoneFormatter],
                              decoration: _obterDecoracaoCampo('Telefone', hint: '(00) 00000-0000'),
                              validator: (v) => _validarCampoObrigatorio(v, field: 'Telefone'),
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _nomeEstabelecimentoCtrl,
                              decoration: _obterDecoracaoCampo('Estabelecimento', hint: 'Nome do ponto de venda'),
                              validator: (v) => _validarCampoObrigatorio(v, field: 'Estabelecimento'),
                            ),
                            const SizedBox(height: 12),

                            Text(
                              'Endereço',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _estadoCtrl,
                                    textCapitalization: TextCapitalization.characters,
                                    inputFormatters: [MaskTextInputFormatter(mask: 'AA')],
                                    decoration: _obterDecoracaoCampo('Estado (UF)', hint: 'PR').copyWith(isDense: true),
                                    validator: _validarUF,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cidadeCtrl,
                                    decoration: _obterDecoracaoCampo('Cidade/Localidade', hint: 'Londrina').copyWith(isDense: true),
                                    validator: (v) => _validarCampoObrigatorio(v, field: 'Cidade'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _tipoLogradouro,
                                    items: _tiposLogradouro.map((e) {
                                      return DropdownMenuItem<String>(
                                        value: e,
                                        child: SizedBox(
                                          height: dropItemHeight,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              e,
                                              style: TextStyle(fontSize: isNarrow ? 16 : 14, fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    selectedItemBuilder: (context) {
                                      return _tiposLogradouro.map((e) {
                                        final abreviado = _abbr[e] ?? e;
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            isNarrow ? e : abreviado,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: isNarrow ? 16 : 14, fontWeight: FontWeight.w600),
                                          ),
                                        );
                                      }).toList();
                                    },
                                    onChanged: (v) => setState(() => _tipoLogradouro = v),
                                    decoration: _obterDecoracaoCampo('Tipo').copyWith(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isNarrow ? 18 : 12),
                                      isDense: !isNarrow,
                                    ),
                                    validator: (v) => v == null || v.isEmpty ? 'Tipo é obrigatório' : null,
                                    menuMaxHeight: dropMenuMax,
                                    icon: const Icon(Icons.arrow_drop_down),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: TextFormField(
                                    controller: _nomeViaCtrl,
                                    decoration: _obterDecoracaoCampo('Nome da via', hint: 'Ex: Tiradentes').copyWith(
                                      isDense: !isNarrow,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isNarrow ? 18 : 12),
                                      // Não exibir o Tipo dentro do campo
                                      prefixIcon: null,
                                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                    ),
                                    validator: (v) => _validarCampoObrigatorio(v, field: 'Nome da via'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _numeroCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _obterDecoracaoCampo('Número', hint: '123').copyWith(
                                      isDense: !isNarrow,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isNarrow ? 18 : 12),
                                    ),
                                    validator: (v) => _validarCampoObrigatorio(v, field: 'Número'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bairroCtrl,
                                    decoration: _obterDecoracaoCampo('Bairro', hint: 'Ex: Centro').copyWith(isDense: true),
                                    validator: (v) => _validarCampoObrigatorio(v, field: 'Bairro'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _complementoCtrl,
                                    decoration: _obterDecoracaoCampo('Complemento', hint: 'Ap, bloco, casa, sala', isObrigatorio: false).copyWith(isDense: true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _cepCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_cepFormatter],
                              decoration: _obterDecoracaoCampo('CEP', hint: '00000-000').copyWith(isDense: true),
                              validator: _validarCEP,
                            ),

                            const SizedBox(height: 16),

                            Text(
                              'Negociação',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _dataNegociacaoCtrl,
                                    readOnly: true,
                                    decoration: _obterDecoracaoCampo(
                                      'Data da negociação',
                                      hint: 'dd/mm/aaaa',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today_outlined),
                                        onPressed: _selecionarData,
                                      ),
                                    ).copyWith(isDense: true),
                                    onTap: _selecionarData,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _horaNegociacaoCtrl,
                                    readOnly: true,
                                    decoration: _obterDecoracaoCampo(
                                      'Hora da negociação',
                                      hint: '00:00',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.access_time),
                                        onPressed: _selecionarHora,
                                      ),
                                    ).copyWith(isDense: true),
                                    onTap: _selecionarHora,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _statusNegociacao,
                                    items: _statusOptions
                                        .map((s) => DropdownMenuItem<String>(
                                              value: s['value']!,
                                              child: Text(s['label']!),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(() => _statusNegociacao = v),
                                    decoration: _obterDecoracaoCampo('Status').copyWith(isDense: true),
                                    validator: (v) => v == null || v.isEmpty ? 'Status é obrigatório' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _valorPropostaCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: _obterDecoracaoCampo('Valor da proposta', hint: 'Ex: 1500,00', isObrigatorio: false).copyWith(isDense: true),
                                    validator: _validarValorProposta,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Text(
                              'Observações',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _observacoesCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Ex: cliente solicitou entrega no período da tarde',
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _limparCampos,
                                    child: const Text('Limpar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _isLoading ? null : _salvarCliente,
                                    child: _isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Cadastrar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

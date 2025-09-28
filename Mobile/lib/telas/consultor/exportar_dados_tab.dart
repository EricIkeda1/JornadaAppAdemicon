import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import '../../models/cliente.dart';

class ExportarDadosTab extends StatelessWidget {
  final List<Cliente> clientes;
  const ExportarDadosTab({super.key, required this.clientes});

  String _toCsv(List<Cliente> list) {
    final rows = <List<dynamic>>[
      ['Estabelecimento', 'Endereço', 'Data da Visita', 'Nome do Cliente', 'Telefone', 'Observações'],
      ...list.map((c) => [
            c.estabelecimento,
            c.endereco,
            '${c.dataVisita.day.toString().padLeft(2, '0')}/${c.dataVisita.month.toString().padLeft(2, '0')}/${c.dataVisita.year}',
            c.nomeCliente ?? '',
            c.telefone ?? '',
            (c.observacoes ?? '').replaceAll('\n', ' ').trim(),
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _onlyNotes(List<Cliente> list) {
    final buffer = StringBuffer();
    for (final c in list) {
      buffer.writeln('Estabelecimento: ${c.estabelecimento}');
      buffer.writeln('Endereço: ${c.endereco}');
      buffer.writeln(
          'Data: ${c.dataVisita.day.toString().padLeft(2, '0')}/${c.dataVisita.month.toString().padLeft(2, '0')}/${c.dataVisita.year}');
      if ((c.nomeCliente ?? '').isNotEmpty) buffer.writeln('Cliente: ${c.nomeCliente}');
      if ((c.telefone ?? '').isNotEmpty) buffer.writeln('Telefone: ${c.telefone}');
      buffer.writeln('Observações: ${c.observacoes ?? '-'}');
      buffer.writeln('---');
    }
    return buffer.toString();
  }

  Future<void> _downloadFileMobile(String content, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/$fileName');
    await file.writeAsString(content);
    print('Arquivo salvo em: ${file.path}');
  }

  Future<void> _downloadCSV(BuildContext context) async {
    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nada para exportar')));
      return;
    }

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: _toCsv(clientes)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copiado para clipboard!')));
    } else {
      await _downloadFileMobile(_toCsv(clientes), 'clientes.csv');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV salvo no dispositivo!')));
    }
  }

  Future<void> _downloadTXT(BuildContext context) async {
    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nada para exportar')));
      return;
    }

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: _onlyNotes(clientes)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TXT copiado para clipboard!')));
    } else {
      await _downloadFileMobile(_onlyNotes(clientes), 'observacoes.txt');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TXT salvo no dispositivo!')));
    }
  }

  Future<void> _copyToClipboard(BuildContext context, {bool isCSV = true}) async {
    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nada para copiar')));
      return;
    }
    final content = isCSV ? _toCsv(clientes) : _onlyNotes(clientes);
    await Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${isCSV ? 'CSV' : 'TXT'} copiado para área de transferência!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Exportar para CRM', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            _exportCard(
              context,
              title: 'Exportar CSV Completo',
              description: 'Contém todos os dados dos clientes em formato de tabela',
              onDownload: () => _downloadCSV(context),
              onCopy: () => _copyToClipboard(context, isCSV: true),
            ),
            const SizedBox(height: 12),

            _exportCard(
              context,
              title: 'Exportar Observações',
              description: 'Apenas as observações dos clientes em formato de texto',
              onDownload: () => _downloadTXT(context),
              onCopy: () => _copyToClipboard(context, isCSV: false),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clientes cadastrados: ${clientes.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportCard(BuildContext context,
      {required String title, required String description, required VoidCallback onDownload, required VoidCallback onCopy}) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: onDownload,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        child: const Text('Baixar'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: onCopy,
                        child: const Text('Copiar'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
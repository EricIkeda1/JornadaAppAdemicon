import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' as io;
import 'dart:convert' as convert; 
import 'dart:html' as html; 
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import '../../models/cliente.dart';

class ExportarDadosTab extends StatelessWidget {
  final List<Cliente> clientes;
  const ExportarDadosTab({super.key, required this.clientes});

  String _toCsvExcel(List<Cliente> list) {
    final buffer = StringBuffer();
    buffer.write('\uFEFF'); 
    buffer.writeln('sep=;');
    buffer.writeln('Estabelecimento;Estado;Cidade;Endereço;Data da Visita;Nome do Cliente;Telefone;Observações');
    
    for (final c in list) {
      final row = [
        c.estabelecimento,
        c.estado,
        c.cidade,
        c.endereco,
        '${c.dataVisita.day.toString().padLeft(2, '0')}/${c.dataVisita.month.toString().padLeft(2, '0')}/${c.dataVisita.year}', 
        c.nomeCliente ?? '',
        c.telefone ?? '',
        (c.observacoes ?? '').replaceAll('\n', ' ').trim(),
      ];
      buffer.writeln(row.map((e) => '"${e.replaceAll('"', '""')}"').join(';'));
    }
    return buffer.toString();
  }

  void _downloadWeb(String content, String fileName, String mimeType) {
    final bytes = convert.utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _saveFile(String content, String fileName, String mimeType) async {
    if (kIsWeb) {
      _downloadWeb(content, fileName, mimeType);
      return;
    }

    if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
      final typeGroup = XTypeGroup(label: 'text', extensions: [fileName.split('.').last]);
      final path = await getSavePath(suggestedName: fileName, acceptedTypeGroups: [typeGroup]);
      if (path == null) return;
      final file = io.File(path);
      await file.writeAsString(content);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = io.File('${dir.path}/$fileName');
      await file.writeAsString(content);
      print('Arquivo salvo em: ${file.path}');
    }
  }

  Future<void> _downloadCSV(BuildContext context) async {
    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nada para exportar')));
      return;
    }
    
    try {
      await _saveFile(_toCsvExcel(clientes), 'clientes.csv', 'text/csv;charset=utf-8');
      
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV baixado com sucesso!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV salvo no dispositivo!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao baixar: $e')));
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nada para copiar')));
      return;
    }
    final content = _toCsvExcel(clientes);
    await Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copiado para área de transferência!')));
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
              title: 'Exportar CSV para Excel',
              description: 'Todos os dados dos clientes em formato de planilha',
              onDownload: () => _downloadCSV(context),
              onCopy: () => _copyToClipboard(context),
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
                  Text('Clientes cadastrados: ${clientes.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                Expanded(child: ElevatedButton(onPressed: onDownload, style: ElevatedButton.styleFrom(backgroundColor: Colors.black), child: const Text('Baixar'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: onCopy, child: const Text('Copiar'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
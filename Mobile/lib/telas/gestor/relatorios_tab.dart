import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RelatoriosTab extends StatelessWidget {
  const RelatoriosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime inicioMes = DateTime(now.year, now.month, 1);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Relatórios", 
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black, 
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Visão geral das atividades da equipe",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 20),

            _cardRelatorioPorConsultor(inicioMes),

            const SizedBox(height: 16),

            _cardAtividadeRecente(),
          ],
        ),
      ),
    );
  }

  Widget _cardRelatorioPorConsultor(DateTime inicioMes) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_ind, color: Color(0xFF2F6FED), size: 20),
                SizedBox(width: 6),
                Text(
                  "Desempenho dos Consultores",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Número total e deste mês por consultor",
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('consultores')
                  .orderBy('nome')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text("Erro ao carregar dados", style: TextStyle(color: Colors.red));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum consultor cadastrado", style: TextStyle(color: Colors.black54)),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 2, color: Colors.black12),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final String consultorId = doc.id;
                    final String nome = doc.get('nome') as String? ?? 'Sem nome';

                    return _relatorioListItem(nome, consultorId, inicioMes);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _relatorioListItem(String nome, String consultorId, DateTime inicioMes) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clientes')
          .where('consultorId', isEqualTo: consultorId)
          .snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int mes = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          total = snapshot.data!.docs.length;
          mes = snapshot.data!.docs.where((doc) {
            final Timestamp? timestamp = doc.get('data_cadastro');
            final DateTime data = timestamp?.toDate() ?? DateTime(1970);
            return data.isAfter(inicioMes);
          }).length;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAEAEA),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _iniciais(nome),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$total cadastros totais",
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    backgroundColor: const Color(0xFFD03025),
                    label: Text(
                      '$mes este mês',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardAtividadeRecente() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Color(0xFF2F6FED), size: 20),
                SizedBox(width: 6),
                Text(
                  "Atividade Recente",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Últimos cadastros feitos no sistema",
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clientes')
                  .orderBy('data_cadastro', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text("Erro ao carregar atividades", style: TextStyle(color: Colors.red));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      "Nenhum cadastro ainda",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final String nomeCliente = doc.get('nome') as String? ?? 'Cliente';
                    final String bairro = doc.get('bairro') as String? ?? 'sem bairro';
                    final Timestamp? timestamp = doc.get('data_cadastro');
                    final String data = timestamp != null
                        ? DateFormat('dd/MM HH:mm').format(timestamp.toDate())
                        : 'data inválida';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        nomeCliente,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(bairro, style: const TextStyle(fontSize: 13)),
                      trailing: Text(
                        data,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _iniciais(String nome) {
  final parts = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return "??";
  final first = parts.first;
  final second = parts.length > 1 ? parts.last : "";
  return (first[0] + second[0]).toUpperCase();
}

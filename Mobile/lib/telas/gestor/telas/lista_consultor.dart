import 'package:flutter/material.dart';
import 'nova_tela_branca.dart';

class ConsultoresRoot extends StatefulWidget {
  final VoidCallback? onCadastrar; 
  const ConsultoresRoot({super.key, this.onCadastrar});

  @override
  State<ConsultoresRoot> createState() => _ConsultoresRootState();
}

class _ConsultoresRootState extends State<ConsultoresRoot> {
  final List<_ConsultorView> _consultores = [
    _ConsultorView('1', 'João Silva', 'Mat. 001', '(11) 98765-4321', 'joao.silva@ademicon.com.br'),
    _ConsultorView('2', 'Carlos Mendes', 'Mat. 002', '(11) 97654-3210', 'carlos.mendes@ademicon.com.br'),
    _ConsultorView('3', 'Ana Paula', 'Mat. 003', '(11) 96543-2109', 'ana.paula@ademicon.com.br'),
    _ConsultorView('4', 'Roberto Santos', 'Mat. 004', '(11) 99876-1234', 'roberto.santos@ademicon.com.br'),
  ];

  void _openWhiteScreen() {
    if (widget.onCadastrar != null) {
      widget.onCadastrar!.call();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NovaTelaBranca()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      floatingActionButton: null,
      floatingActionButtonLocation: null,

      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Row(
            children: const [
              Icon(Icons.group, color: Colors.red),
              SizedBox(width: 8),
              Text('Consultores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Gerencie a equipe de consultores'),
          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${_consultores.length} consultores',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openWhiteScreen,
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
              label: const Text(
                'Cadastrar Novo Consultor',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA3124),
                elevation: 3,
                shadowColor: const Color(0x33000000),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(height: 16),

          ..._consultores.map((c) => _ConsultorCard(
                c: c,
                onEditar: _openWhiteScreen,
                onApagar: () => setState(() => _consultores.removeWhere((x) => x.id == c.id)),
              )),
        ],
      ),
    );
  }
}

class _ConsultorView {
  final String id, nome, matricula, telefone, email;
  _ConsultorView(this.id, this.nome, this.matricula, this.telefone, this.email);
}

class _ConsultorCard extends StatelessWidget {
  final _ConsultorView c;
  final VoidCallback onEditar;
  final VoidCallback onApagar;
  const _ConsultorCard({super.key, required this.c, required this.onEditar, required this.onApagar});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.red, size: 35),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(4)),
                        child: Text(c.matricula, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEditar,
                      icon: const Icon(Icons.edit, size: 16, color: Colors.red),
                      label: const Text('Editar', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: onApagar,
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Apagar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(c.telefone),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(c.email),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

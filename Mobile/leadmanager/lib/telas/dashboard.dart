import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../models/lead_model.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  List<Lead> leads = [
    Lead(
      name: 'Ana Silva',
      phone: '(43) 99999-1234',
      email: 'ana.silva@email.com',
      status: 'Ativo',
    ),
    Lead(
      name: 'Carlos Oliveira',
      phone: '(43) 98888-5678',
      email: 'carlos@empresa.com.br',
      status: 'Expirado',
    ),
    Lead(
      name: 'Fernanda Costa',
      phone: '(43) 97777-8888',
      email: 'fernanda@email.com',
      status: 'Ativo',
    ),
    Lead(
      name: 'João Pereira',
      phone: '(43) 96666-9999',
      email: 'joao@email.com',
      status: 'Convertido',
    ),
  ];

  List<Lead> filteredLeads = [];

  @override
  void initState() {
    super.initState();
    filteredLeads = leads;
    _searchController.addListener(_filterLeads);
  }

  void _filterLeads() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredLeads = leads;
      } else {
        filteredLeads = leads.where((lead) {
          return lead.name.toLowerCase().contains(query) ||
              lead.phone.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);

    if (index == 6) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _abrirNovoLead(BuildContext context) {
    final ScrollController _scrollController = ScrollController();
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController telefoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController nascimentoController = TextEditingController();
    final TextEditingController classificacaoController = TextEditingController();
    final TextEditingController observacoesController = TextEditingController();

    final TextEditingController estabelecimentoController = TextEditingController();
    final TextEditingController responsavelController = TextEditingController();
    final TextEditingController enderecoController = TextEditingController();
    final TextEditingController dataVisitaController = TextEditingController();
    final TextEditingController retornoPrevistoController = TextEditingController();
    final TextEditingController valorPropostaController = TextEditingController();
    String? categoriaVenda;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Novo Lead",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const TabBar(
                    tabs: [
                      Tab(text: "Dados Básicos"),
                      Tab(text: "P.A.P."),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Informações do Lead", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: nomeController,
                                decoration: const InputDecoration(
                                  labelText: "Nome *",
                                  hintText: "Nome completo",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: telefoneController,
                                decoration: const InputDecoration(
                                  labelText: "Telefone *",
                                  hintText: "(43) 99999-9999",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: "E-mail",
                                  hintText: "email@exemplo.com",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: nascimentoController,
                                decoration: const InputDecoration(
                                  labelText: "Data de Nascimento",
                                  hintText: "dd/mm/aaaa",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: classificacaoController,
                                decoration: const InputDecoration(
                                  labelText: "Classificação",
                                  hintText: "Ex: 200k; investidor",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: observacoesController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: "Observações",
                                  hintText: "Observações gerais sobre o lead",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("P.A.P. - Plano de Ação Personalizada", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: estabelecimentoController,
                                decoration: const InputDecoration(
                                  labelText: "Nome do Estabelecimento",
                                  hintText: "Razão social ou nome fantasia",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: responsavelController,
                                decoration: const InputDecoration(
                                  labelText: "Nome do Responsável",
                                  hintText: "Pessoa responsável",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: enderecoController,
                                decoration: const InputDecoration(
                                  labelText: "Endereço",
                                  hintText: "Endereço completo",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: dataVisitaController,
                                decoration: const InputDecoration(
                                  labelText: "Data da Visita",
                                  hintText: "dd/mm/aaaa",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: retornoPrevistoController,
                                decoration: const InputDecoration(
                                  labelText: "Retorno Previsto",
                                  hintText: "dd/mm/aaaa",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: categoriaVenda,
                                items: ["Categoria 1", "Categoria 2", "Categoria 3"]
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    categoriaVenda = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: "Categoria de Venda",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: valorPropostaController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Valor da Proposta (R\$)",
                                  hintText: "0,00",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                            onPressed: () {
                            },
                            child: const Text("Criar Lead"),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Dashboard de Leads",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.circle, size: 36, color: Colors.black87),
                onPressed: () {},
              ),
              const Positioned(
                top: 6,
                right: 12,
                child: Text(
                  "J",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: NavBar(
        userName: 'João Silva',
        userRole: 'Gestor',
        leadCount: leads.length,
        onItemSelected: _onItemSelected,
        selectedIndex: _selectedIndex,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _abrirNovoLead(context),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Novo Lead',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildSummaryCard(Icons.people, "Total", leads.length, Colors.black)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildSummaryCard(Icons.check_circle, "Ativos", _countLeadsByStatus("Ativo"), Colors.green)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildSummaryCard(Icons.warning, "Expirados", _countLeadsByStatus("Expirado"), Colors.red)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildSummaryCard(Icons.trending_up, "Convertidos", _countLeadsByStatus("Convertido"), Colors.blue)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildVencendoCard("Vencendo", _countLeadsByStatus("Vencendo")),
                const SizedBox(height: 16),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por nome ou telefone...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text("Todos"),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Lista de Leads", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${filteredLeads.length} leads"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredLeads.length,
              itemBuilder: (context, index) {
                final lead = filteredLeads[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lead.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lead.status == "Ativo" ? Colors.black : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              lead.status,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(lead.phone),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(lead.email),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.person, size: 16, color: Colors.black54),
                          SizedBox(width: 6),
                          Text("João Silva"),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _countLeadsByStatus(String status) {
    return leads.where((lead) => lead.status == status).length;
  }

  Widget _buildSummaryCard(IconData icon, String title, int value, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value.toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildVencendoCard(String title, int value) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
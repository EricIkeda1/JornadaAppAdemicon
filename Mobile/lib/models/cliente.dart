class Cliente {
  final String estabelecimento;
  final String endereco;
  final DateTime dataVisita;
  final String? nomeCliente;
  final String? telefone;
  final String? observacoes;
  final String id;

  Cliente({
    required this.estabelecimento,
    required this.endereco,
    required this.dataVisita,
    this.nomeCliente,
    this.telefone,
    this.observacoes,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estabelecimento': estabelecimento,
      'endereco': endereco,
      'dataVisita': dataVisita.toIso8601String(),
      'nomeCliente': nomeCliente,
      'telefone': telefone,
      'observacoes': observacoes,
    };
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      estabelecimento: json['estabelecimento'],
      endereco: json['endereco'],
      dataVisita: DateTime.parse(json['dataVisita']),
      nomeCliente: json['nomeCliente'],
      telefone: json['telefone'],
      observacoes: json['observacoes'],
    );
  }
}
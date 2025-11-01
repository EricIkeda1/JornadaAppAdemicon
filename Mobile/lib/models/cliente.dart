import 'package:meta/meta.dart';

@immutable
class Cliente {
  final String id;
  final String nomeCliente;
  final String telefone;
  final String estabelecimento;
  final String estado;
  final String cidade;
  final String endereco;          
  final String? logradouro;     
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cep;
  final DateTime dataVisita;
  final String? observacoes;
  final String? consultorResponsavel;
  final String consultorUid;
  final String? horaVisita;
  final String? statusNegociacao;
  final num? valorProposta;

  const Cliente({
    required this.id,
    required this.nomeCliente,
    required this.telefone,
    required this.estabelecimento,
    required this.estado,
    required this.cidade,
    required this.endereco,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cep,
    required this.dataVisita,
    this.observacoes,
    this.consultorResponsavel,
    required this.consultorUid,
    this.horaVisita,
    this.statusNegociacao,
    this.valorProposta,
  });

  Cliente copyWith({
    String? id,
    String? nomeCliente,
    String? telefone,
    String? estabelecimento,
    String? estado,
    String? cidade,
    String? endereco,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cep,
    DateTime? dataVisita,
    String? observacoes,
    String? consultorResponsavel,
    String? consultorUid,
    String? horaVisita,
    String? statusNegociacao,
    num? valorProposta,
  }) {
    return Cliente(
      id: id ?? this.id,
      nomeCliente: nomeCliente ?? this.nomeCliente,
      telefone: telefone ?? this.telefone,
      estabelecimento: estabelecimento ?? this.estabelecimento,
      estado: estado ?? this.estado,
      cidade: cidade ?? this.cidade,
      endereco: endereco ?? this.endereco,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cep: cep ?? this.cep,
      dataVisita: dataVisita ?? this.dataVisita,
      observacoes: observacoes ?? this.observacoes,
      consultorResponsavel: consultorResponsavel ?? this.consultorResponsavel,
      consultorUid: consultorUid ?? this.consultorUid,
      horaVisita: horaVisita ?? this.horaVisita,
      statusNegociacao: statusNegociacao ?? this.statusNegociacao,
      valorProposta: valorProposta ?? this.valorProposta,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomeCliente': nomeCliente,
        'telefone': telefone,
        'estabelecimento': estabelecimento,
        'estado': estado,
        'cidade': cidade,
        'endereco': endereco,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cep': cep,
        'dataVisita': dataVisita.toIso8601String(),
        'observacoes': observacoes,
        'consultorResponsavel': consultorResponsavel,
        'consultorUid': consultorUid,
        'horaVisita': horaVisita,
        'statusNegociacao': statusNegociacao,
        'valorProposta': valorProposta,
      };

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'] as String,
        nomeCliente: json['nomeCliente'] as String,
        telefone: json['telefone'] as String,
        estabelecimento: json['estabelecimento'] as String,
        estado: json['estado'] as String,
        cidade: json['cidade'] as String,
        endereco: json['endereco'] as String,
        logradouro: json['logradouro'] as String?,
        numero: json['numero'] as String?,
        complemento: json['complemento'] as String?,
        bairro: json['bairro'] as String?,
        cep: json['cep'] as String?,
        dataVisita: DateTime.parse(json['dataVisita'] as String),
        observacoes: json['observacoes'] as String?,
        consultorResponsavel: json['consultorResponsavel'] as String?,
        consultorUid: json['consultorUid'] as String? ?? '',
        horaVisita: json['horaVisita'] as String?,
        statusNegociacao: json['statusNegociacao'] as String?,
        valorProposta: json['valorProposta'] as num?,
      );

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
        id: map['id'] as String,
        nomeCliente: map['nome'] as String? ?? map['nome_cliente'] as String? ?? '',
        telefone: map['telefone'] as String? ?? '',
        estabelecimento: map['estabelecimento'] as String? ?? '',
        estado: map['estado'] as String? ?? '',
        cidade: map['cidade'] as String? ?? '',
        endereco: map['endereco'] as String? ?? '',
        logradouro: map['logradouro'] as String?,
        numero: map['numero'] as String?,
        complemento: map['complemento'] as String?,
        bairro: map['bairro'] as String?,
        cep: map['cep'] as String?,
        dataVisita: DateTime.parse((map['data_visita'] ?? map['dataVisita']) as String),
        observacoes: map['observacoes'] as String?,
        consultorResponsavel: map['responsavel'] as String? ?? map['consultor_responsavel'] as String?,
        consultorUid: map['consultor_uid_t'] as String? ?? map['consultor_uid'] as String? ?? '',
        horaVisita: map['hora_visita'] as String? ?? map['horaVisita'] as String?,
        statusNegociacao: map['status_negociacao'] as String? ?? map['statusNegociacao'] as String?,
        valorProposta: (map['valor_proposta'] as num?) ?? (map['valorProposta'] as num?),
      );

  Map<String, dynamic> toSupabaseMap() => {
        'id': id,
        'nome': nomeCliente,
        'telefone': telefone,
        'estabelecimento': estabelecimento,
        'estado': estado,
        'cidade': cidade,
        'endereco': endereco,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cep': cep,
        'data_visita': dataVisita.toIso8601String(),
        'observacoes': observacoes,
        'responsavel': consultorResponsavel,
        'consultor_uid_t': consultorUid,
        'hora_visita': horaVisita,
        'status_negociacao': statusNegociacao, 
        'valor_proposta': valorProposta,
      };

  @override
  String toString() =>
      'Cliente(id=$id, nome=$nomeCliente, cidade=$cidade, logradouro=$logradouro, numero=$numero, status=$statusNegociacao, valor=$valorProposta)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Cliente &&
            other.id == id &&
            other.nomeCliente == nomeCliente &&
            other.telefone == telefone &&
            other.estabelecimento == estabelecimento &&
            other.estado == estado &&
            other.cidade == cidade &&
            other.endereco == endereco &&
            other.logradouro == logradouro &&
            other.numero == numero &&
            other.complemento == complemento &&
            other.bairro == bairro &&
            other.cep == cep &&
            other.dataVisita == dataVisita &&
            other.observacoes == observacoes &&
            other.consultorResponsavel == consultorResponsavel &&
            other.consultorUid == consultorUid &&
            other.horaVisita == horaVisita &&
            other.statusNegociacao == statusNegociacao &&
            other.valorProposta == valorProposta);
  }

  @override
  int get hashCode => Object.hash(
        id,
        nomeCliente,
        telefone,
        estabelecimento,
        estado,
        cidade,
        endereco,
        logradouro,
        numero,
        complemento,
        bairro,
        cep,
        dataVisita,
        observacoes,
        consultorResponsavel,
        consultorUid,
        horaVisita,
        statusNegociacao,
        valorProposta,
      );
}

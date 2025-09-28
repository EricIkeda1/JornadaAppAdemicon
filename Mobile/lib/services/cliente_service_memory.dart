import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/cliente.dart';

class ClienteServiceMemory {
  static final ClienteServiceMemory _instance = ClienteServiceMemory._internal();
  factory ClienteServiceMemory() => _instance;
  ClienteServiceMemory._internal();

  List<Cliente> _clientes = [];

  List<Cliente> get clientes => List.unmodifiable(_clientes);

  Future<void> loadClientes() async {
    // Para web, tenta carregar do localStorage
    try {
      final stored = _getFromLocalStorage();
      if (stored != null) {
        final List<dynamic> jsonList = json.decode(stored);
        _clientes = jsonList.map((json) => Cliente.fromJson(json)).toList();
      } else {
        _clientes = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar clientes: $e');
      }
      _clientes = [];
    }
  }

  Future<void> saveCliente(Cliente cliente) async {
    _clientes.add(cliente);
    await _saveToLocalStorage();
  }

  Future<void> removeCliente(String id) async {
    _clientes.removeWhere((cliente) => cliente.id == id);
    await _saveToLocalStorage();
  }

  Future<void> _saveToLocalStorage() async {
    try {
      final jsonList = _clientes.map((cliente) => cliente.toJson()).toList();
      final jsonString = json.encode(jsonList);
      _saveToLocalStorageWeb(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar clientes: $e');
      }
    }
  }

  void _saveToLocalStorageWeb(String data) {
    try {
      js.context.callMethod('eval', [
        'localStorage.setItem("clientes_data", "$data")'
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar no localStorage: $e');
      }
    }
  }

  String? _getFromLocalStorage() {
    try {
      return js.context.callMethod('eval', [
        'localStorage.getItem("clientes_data")'
      ]) as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao ler do localStorage: $e');
      }
      return null;
    }
  }

  int get totalClientes => _clientes.length;
  
  int get totalVisitasHoje {
    final hoje = DateTime.now();
    return _clientes.where((cliente) => 
      cliente.dataVisita.year == hoje.year &&
      cliente.dataVisita.month == hoje.month &&
      cliente.dataVisita.day == hoje.day
    ).length;
  }
}
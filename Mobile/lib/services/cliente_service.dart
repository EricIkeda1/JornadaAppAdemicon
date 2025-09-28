import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cliente.dart';

class ClienteService {
  static final ClienteService _instance = ClienteService._internal();
  factory ClienteService() => _instance;
  ClienteService._internal();

  static const String _storageKey = 'clientes_data';
  List<Cliente> _clientes = [];

  List<Cliente> get clientes => List.unmodifiable(_clientes);

  Future<void> loadClientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
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
    await _saveToStorage();
  }

  Future<void> removeCliente(String id) async {
    _clientes.removeWhere((cliente) => cliente.id == id);
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _clientes.map((cliente) => cliente.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar clientes: $e');
      }
      rethrow;
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

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _clientes.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao limpar dados: $e');
      }
    }
  }
}
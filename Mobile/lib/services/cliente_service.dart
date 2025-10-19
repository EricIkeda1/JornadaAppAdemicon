import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cliente.dart';

class ClienteService {
  // Singleton
  ClienteService._internal();
  static final ClienteService _singleton = ClienteService._internal();
  factory ClienteService() => _singleton;
  static ClienteService get instance => _singleton;

  final SupabaseClient _client = Supabase.instance.client;
  final List<Cliente> _clientes = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const String _cacheKey = 'clientes_cache';
  static const String _pendingKey = 'pending_ops';

  List<Cliente> get clientes => List.unmodifiable(_clientes);

  Future<void> initialize() async {
    await _loadFromCache();
    await syncPendingOperations(); // drena no startup
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (!hasNet) return;
      await Future.delayed(const Duration(milliseconds: 800)); // debounce
      await syncPendingOperations();
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return;
    try {
      final List list = jsonDecode(raw);
      _clientes
        ..clear()
        ..addAll(list.map((e) => Cliente.fromJson(e as Map<String, dynamic>)));
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_clientes.map((c) => c.toJson()).toList());
    await prefs.setString(_cacheKey, data);
  }

  Future<void> _enqueue(String tipo, Cliente c) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    final List ops = raw != null ? jsonDecode(raw) : [];
    ops.add({'tipo': tipo, 'cliente': c.toJson()});
    await prefs.setString(_pendingKey, jsonEncode(ops));
  }

  Future<void> saveCliente(Cliente c) async {
    // Normaliza UID para satisfazer RLS (auth.uid() = consultor_uid_t)
    final uid = _client.auth.currentSession?.user.id;
    final payload = (uid != null && uid.isNotEmpty) ? c.copyWith(consultorUid: uid) : c;

    // Cache local
    _clientes.removeWhere((x) => x.id == payload.id);
    _clientes.add(payload);
    await _saveToCache();

    // Tenta enviar agora; se falhar (rede/schema/RLS), enfileira
    try {
      await _client.from('clientes').upsert(payload.toSupabaseMap(), onConflict: 'id').select();
      // print('Upsert imediato OK: ${payload.id}');
    } catch (_) {
      // print('Upsert imediato ERRO: $e');
      await _enqueue('save', payload);
    }
  }

  Future<void> removeCliente(String id) async {
    _clientes.removeWhere((x) => x.id == id);
    await _saveToCache();
    try {
      await _client.from('clientes').delete().eq('id', id);
    } catch (_) {
      final stub = Cliente(
        id: id,
        nomeCliente: '',
        telefone: '',
        estabelecimento: '',
        estado: '',
        cidade: '',
        endereco: '',
        dataVisita: DateTime.now(),
        consultorUid: '',
      );
      await _enqueue('remove', stub);
    }
  }

  Future<void> syncPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return;

    final List ops = jsonDecode(raw);
    if (ops.isEmpty) return;

    final List remain = [];
    for (final op in ops) {
      final tipo = op['tipo'] as String;
      final c = Cliente.fromJson(op['cliente'] as Map<String, dynamic>);
      final uid = _client.auth.currentSession?.user.id;
      final payload = (uid != null && uid.isNotEmpty) ? c.copyWith(consultorUid: uid) : c;

      try {
        if (tipo == 'save') {
          await _client.from('clientes').upsert(payload.toSupabaseMap(), onConflict: 'id').select();
          // print('Sync upsert OK: ${payload.id}');
        } else if (tipo == 'remove') {
          await _client.from('clientes').delete().eq('id', payload.id);
          // print('Sync remove OK: ${payload.id}');
        }
      } catch (_) {
        // print('Sync ERRO ($tipo ${payload.id}): $e');
        remain.add(op);
      }
    }

    if (remain.isEmpty) {
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(_pendingKey, jsonEncode(remain));
    }
  }
}

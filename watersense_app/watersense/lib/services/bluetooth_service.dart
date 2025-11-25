import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show Uint8List;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_tank.dart';
import 'storage_service.dart';

class BluetoothService {
  BluetoothService._internal();
  static final BluetoothService instance = BluetoothService._internal();

  final StreamController<double> _heightController =
      StreamController.broadcast();
  Stream<double> get heightStream => _heightController.stream;

  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _isConnecting = false;

  Timer? _mockTimer;
  double _current = 1.0;
  bool _mock = false;

  bool get isConnected => _isConnected;

  /// Alterna o modo de simulação
  void toggleMockStream({bool forceOn = false}) {
    if (forceOn)
      _mock = true;
    else
      _mock = !_mock;

    _mockTimer?.cancel();

    if (_mock) {
      _mockTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        final choices = [-0.02, -0.01, 0.0, 0.01, 0.02];
        choices.shuffle();
        _current += choices.first;
        if (_current < 0) _current = 0;
        _heightController.add(_current);
      });
    }
  }

  /// Conecta ao ESP32 via Bluetooth clássico
  Future<void> connectToESP32() async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial
          .instance
          .getBondedDevices();

      if (bondedDevices.isEmpty) {
        print('⚠️ Nenhum dispositivo pareado encontrado.');
        await _loadOfflineData();
        toggleMockStream(forceOn: true);
        _isConnecting = false;
        return;
      }

      final device = bondedDevices.firstWhere(
        (d) => d.name?.contains("ESP32") ?? false,
        orElse: () => bondedDevices.first,
      );

      try {
        _connection = await BluetoothConnection.toAddress(
          device.address,
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        print('❌ Timeout ou erro ao conectar ao ESP32: $e');
        _isConnected = false;
        await _loadOfflineData();
        toggleMockStream(forceOn: true);
        _isConnecting = false;
        return;
      }

      _isConnected = true;
      print('✅ Conectado a ${device.name}');

      // Envia tipo de caixa selecionado
      final selectedTank = await StorageService.instance.getWaterTank();
      if (selectedTank != null && _connection != null) {
        _connection!.output.add(utf8.encode('${selectedTank.capacityLiter}\n'));
        await _connection!.output.allSent;
      }

      // Recebe dados
      _connection!.input
          ?.listen((Uint8List data) {
            final message = utf8.decode(data);
            final height = double.tryParse(message.trim());
            if (height != null) {
              _heightController.add(height);
              _saveOfflineData(height);
            }
          })
          .onDone(() async {
            _isConnected = false;
            print('⚠️ Conexão encerrada.');
            toggleMockStream(forceOn: true);

            // tenta reconectar automaticamente
            await Future.delayed(const Duration(seconds: 3));
            await connectToESP32();
          });
    } catch (e) {
      print('❌ Erro geral ao conectar: $e');
      _isConnected = false;
      await _loadOfflineData();
      toggleMockStream(forceOn: true);
    } finally {
      _isConnecting = false;
    }
  }

  /// Salva o último valor localmente
  Future<void> _saveOfflineData(double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_height', height);
  }

  /// Carrega o último valor salvo se desconectado
  Future<void> _loadOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getDouble('last_height') ?? 0.0;
    _heightController.add(last);
  }

  /// Desconecta do ESP32
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    _isConnected = false;
    _mockTimer?.cancel();
  }
}

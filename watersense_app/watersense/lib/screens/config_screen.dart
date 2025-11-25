import 'dart:async';

import 'package:flutter/material.dart';
import '../models/water_tank.dart';
import '../services/storage_service.dart';
import '../services/bluetooth_service.dart';

class ConfigScreen extends StatefulWidget {
  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  String? _type;
  double _capacity = 500;
  double _tariff = 0.005;
  double _topRadius = 0.0;
  double _bottomRadius = 0.0;
  double _height = 1.0;

  late TextEditingController _tariffController;
  late TextEditingController _heightController;
  late TextEditingController _topRadiusController;
  late TextEditingController _bottomRadiusController;

  bool _isConnected = false;
  StreamSubscription? _heightSubscription;

  @override
  void initState() {
    super.initState();

    // 🔧 Inicialização dos controllers (SEU ERRO ESTAVA AQUI)
    _tariffController = TextEditingController();
    _heightController = TextEditingController();
    _topRadiusController = TextEditingController();
    _bottomRadiusController = TextEditingController();

    _loadTank();

    // ► Conectando BLE
    BluetoothService.instance.connectToESP32();

    // ► Escutando leituras
    _heightSubscription = BluetoothService.instance.heightStream.listen((
      h,
    ) async {
      setState(() {}); // atualiza tela se quiser mostrar h
      await _processMeasurement(h);
    });
  }

  @override
  void dispose() {
    _tariffController.dispose();
    _heightController.dispose();
    _topRadiusController.dispose();
    _bottomRadiusController.dispose();
    _heightSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTank() async {
    final tank = await StorageService.instance.getWaterTank();
    if (tank != null) {
      setState(() {
        _type = tank.type;
        _capacity = tank.capacityLiter.toDouble();
        _tariff = tank.tariffPerLiter;
        _topRadius = tank.topRadius;
        _bottomRadius = tank.bottomRadius;
        _height = tank.tankHeight;

        _tariffController.text = _tariff.toString();
        _heightController.text = _height.toString();
        _topRadiusController.text = _topRadius.toString();
        _bottomRadiusController.text = _bottomRadius.toString();
      });
    } else {
      _tariffController.text = _tariff.toString();
      _heightController.text = _height.toString();
    }
  }

  void _save() async {
    _tariff = double.tryParse(_tariffController.text) ?? _tariff;
    _height = double.tryParse(_heightController.text) ?? _height;
    _topRadius = double.tryParse(_topRadiusController.text) ?? _topRadius;
    _bottomRadius =
        double.tryParse(_bottomRadiusController.text) ?? _bottomRadius;

    final tank = WaterTank(
      type: _type ?? 'cilindrica',
      capacityLiter: _capacity.toInt(),
      tariffPerLiter: _tariff,
      topRadius: _topRadius,
      bottomRadius: _bottomRadius,
      tankHeight: _height,
    );

    await StorageService.instance.saveWaterTank(tank);
    Navigator.pop(context);
  }

  void _toggleConnection() async {
    if (_isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Conexão BLE será mantida")));
    } else {
      await BluetoothService.instance.connectToESP32();
      setState(() => _isConnected = BluetoothService.instance.isConnected!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ESP32: ${_isConnected ? "Conectado" : "Desconectado"}'),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _toggleConnection,
              child: Text(_isConnected ? 'Manter Conexão' : 'Conectar ESP32'),
            ),

            const Divider(height: 30),

            const Text('Tipo de caixa de água:'),
            const SizedBox(height: 10),

            DropdownButton<String>(
              value: _type,
              items: const [
                DropdownMenuItem(
                  value: 'cilindrica',
                  child: Text('Cilíndrica'),
                ),
                DropdownMenuItem(
                  value: 'tronco',
                  child: Text('Tronco de cone'),
                ),
              ],
              onChanged: (v) => setState(() => _type = v),
              hint: const Text('Selecione o tipo'),
            ),

            const SizedBox(height: 20),

            const Text('Capacidade (litros):'),
            Slider(
              min: 100,
              max: 5000,
              divisions: 49,
              value: _capacity,
              label: '${_capacity.round()} L',
              onChanged: (v) => setState(() => _capacity = v),
            ),

            const SizedBox(height: 10),

            const Text('Tarifa (R\$ por litro):'),
            TextField(
              controller: _tariffController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),

            if (_type == 'tronco') ...[
              const SizedBox(height: 20),
              const Text('Altura da caixa (m):'),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 10),
              const Text('Raio superior (m):'),
              TextField(
                controller: _topRadiusController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 10),
              const Text('Raio inferior (m):'),
              TextField(
                controller: _bottomRadiusController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(onPressed: _save, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }

  Future<void> _processMeasurement(double h) async {
    // implementar depois
  }
}

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

  late TextEditingController _tariffController;
  bool _isConnected = false;

  StreamSubscription? _heightSubscription;

  @override
  void initState() {
    super.initState();

    _tariffController = TextEditingController();

    _loadTank();

    // Conexão BLE
    BluetoothService.instance.connectToESP32();

    _heightSubscription = BluetoothService.instance.heightStream.listen((
      h,
    ) async {
      setState(() {});
      // ainda não processa nada aqui
    });
  }

  @override
  void dispose() {
    _tariffController.dispose();
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
        _tariffController.text = _tariff.toString();
      });
    } else {
      _tariffController.text = _tariff.toString();
    }
  }

  void _save() async {
    _tariff = double.tryParse(_tariffController.text) ?? _tariff;

    var topRadius = null;
    var tankHeight = null;
    var bottomRadius = null;
    final tank = WaterTank(
      type: _type ?? 'cilindrica',
      capacityLiter: _capacity.toInt(),
      tariffPerLiter: _tariff,
      topRadius: topRadius,
      bottomRadius: bottomRadius,
      tankHeight: tankHeight,
      calibrationTable: {},
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

  // ================================
  //   BOTÃO DE CAPACIDADE PRÉ-PRONTA
  // ================================
  Widget _buildCapacityButton(int liters) {
    return ChoiceChip(
      label: Text("$liters L"),
      selected: _capacity == liters.toDouble(),
      onSelected: (_) {
        setState(() => _capacity = liters.toDouble());
      },
    );
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
            const Text('Capacidade (Litros):'),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildCapacityButton(310),
                _buildCapacityButton(500),
                _buildCapacityButton(1000),
                _buildCapacityButton(1500),
                _buildCapacityButton(2000),
                _buildCapacityButton(5000),
              ],
            ),

            const SizedBox(height: 20),
            const Text('Tarifa (R\$ por litro):'),
            TextField(
              controller: _tariffController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Salvar Configurações'),
            ),
          ],
        ),
      ),
    );
  }
}

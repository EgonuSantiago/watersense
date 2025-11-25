import 'package:flutter/material.dart';
import '../widgets/water_level_widget.dart';
import '../services/bluetooth_service.dart';
import '../utils/calculations.dart';
import '../models/water_tank.dart';
import '../services/storage_service.dart';
import '../models/consumption.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _currentHeight = 0.0;
  double _percentage = 0.0;
  double _liters = 0.0;
  WaterTank? _tank;
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _loadTank();

    // Conecta ao ESP32 quando a HomeScreen iniciar
    BluetoothService.instance.connectToESP32();

    // Escuta o stream de altura
    _sub = BluetoothService.instance.heightStream.listen((height) async {
      setState(() => _currentHeight = height);
      await _processMeasurement(height);
    });
  }

  @override
  void dispose() {
    // NÃO desconecta o ESP32 para manter a conexão viva
    _sub?.cancel();
    super.dispose();
  }

  void _loadTank() async {
    final t = await StorageService.instance.getWaterTank();
    setState(() => _tank = t ?? WaterTank.defaultCylinder());
  }

  Future<void> _processMeasurement(double heightMeters) async {
    final tank = _tank ?? WaterTank.defaultCylinder();
    final volume = Calculations.volumeFromHeight(tank, heightMeters);
    final percent = Calculations.percentFromHeight(tank, heightMeters);

    final prev = await StorageService.instance.getLastVolume();
    final now = DateTime.now();
    if (prev != null) {
      final vb = prev - volume;
      if (vb.abs() > 0.0001) {
        final c = Consumption(volumeChange: vb, timestamp: now);
        await StorageService.instance.saveConsumption(c);
      }
    }
    await StorageService.instance.saveLastVolume(volume);

    setState(() {
      _liters = volume;
      _percentage = percent * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WaterSense')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('WaterSense')),
            ListTile(
              title: const Text('Configurações'),
              onTap: () => Navigator.pushNamed(context, '/config'),
            ),
            ListTile(
              title: const Text('Histórico'),
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            ListTile(
              title: const Text('Consumo Detalhado'),
              onTap: () => Navigator.pushNamed(context, '/consumption'),
            ),
          ],
        ),
      ),
      body: Center(
        child: _tank == null
            ? const CircularProgressIndicator()
            : StreamBuilder<double>(
                stream: BluetoothService.instance.heightStream,
                builder: (context, snapshot) {
                  final height = snapshot.data ?? _currentHeight;
                  // Atualiza os valores de litros e porcentagem com base no height
                  if (_tank != null) {
                    _processMeasurement(height);
                  }
                  return WaterLevelWidget(
                    percentage: _percentage,
                    liters: _liters,
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.bluetooth_searching),
        onPressed: () async {
          await BluetoothService.instance.connectToESP32();
        },
      ),
    );
  }
}

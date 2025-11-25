import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/water_level_widget.dart';
import '../services/bluetooth_service.dart';
import '../utils/calculations.dart';
import '../models/water_tank.dart';
import '../services/storage_service.dart';
import '../models/consumption.dart';

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
  bool _isRealData = false; // indica se os dados vieram do sensor

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Carrega a tank
    final t = await StorageService.instance.getWaterTank();
    final tank = t ?? WaterTank.defaultCylinder();

    // Carrega último volume salvo (apenas para exibição, sem salvar consumo)
    final lastVolume = await StorageService.instance.getLastVolume();
    final initialHeight = lastVolume != null
        ? _estimateHeightFromVolume(tank, lastVolume)
        : 0.0;

    setState(() {
      _tank = tank;
      _liters = lastVolume ?? 0.0;
      _percentage = tank.capacityLiter > 0
          ? (_liters / tank.capacityLiter) * 100
          : 0.0;
      _currentHeight = initialHeight;
      _isRealData = false; // ainda não temos dados reais
    });

    // Conecta ao ESP32
    BluetoothService.instance.connectToESP32();

    // Escuta o stream de altura
    _sub = BluetoothService.instance.heightStream.listen(
      (height) => _processMeasurement(height, isReal: true),
      onError: (err) {
        print("Erro no stream do sensor: $err");
      },
    );
  }

  /// Estima a altura da água a partir do volume (para exibição inicial)
  double _estimateHeightFromVolume(WaterTank tank, double volumeLiters) {
    final volumeM3 = volumeLiters / 1000.0;
    if (tank.type == 'cilindrica') {
      final radius = sqrt((tank.capacityLiter / 1000.0) / tank.tankHeight);
      return (volumeM3 / (pi * radius * radius)).clamp(0.0, tank.tankHeight);
    } else {
      final radiusAvg = (tank.topRadius + tank.bottomRadius) / 2.0;
      return (volumeM3 / (pi * radiusAvg * radiusAvg)).clamp(
        0.0,
        tank.tankHeight,
      );
    }
  }

  /// Processa a leitura do sensor e salva consumo apenas se os dados forem reais
  Future<void> _processMeasurement(
    double heightMeters, {
    bool isReal = false,
  }) async {
    final tank = _tank ?? WaterTank.defaultCylinder();
    final volume = Calculations.volumeFromHeight(tank, heightMeters);
    final percent = Calculations.percentFromHeight(tank, heightMeters);

    if (isReal) {
      // Salva consumo apenas para dados reais
      final prev = await StorageService.instance.getLastVolume();
      if (prev != null) {
        final delta = prev - volume;
        if (delta.abs() > 0.0001) {
          final c = Consumption(volumeChange: delta, timestamp: DateTime.now());
          await StorageService.instance.saveConsumption(c);
        }
      }
      await StorageService.instance.saveLastVolume(volume);
    }

    // Atualiza UI
    setState(() {
      _currentHeight = heightMeters;
      _liters = volume;
      _percentage = percent * 100;
      if (isReal) _isRealData = true;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WaterLevelWidget(percentage: _percentage, liters: _liters),
                  const SizedBox(height: 10),
                  if (!_isRealData)
                    const Text(
                      '⚠️ Dados estimados, aguardando sensor...',
                      style: TextStyle(color: Colors.orange),
                    ),
                ],
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

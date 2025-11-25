import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/consumption_chart.dart';
import '../models/consumption.dart';

class ConsumptionScreen extends StatefulWidget {
  @override
  _ConsumptionScreenState createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumo')),
      body: FutureBuilder<List<Consumption>>(
        future: StorageService.instance.getAllConsumptions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [Expanded(child: ConsumptionChart(consumptions: data))],
            ),
          );
        },
      ),
    );
  }
}

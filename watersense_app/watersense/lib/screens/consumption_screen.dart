import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../models/consumption.dart';

class ConsumptionScreen extends StatefulWidget {
  @override
  _ConsumptionScreenState createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen> {
  ConsumptionType _selectedType = ConsumptionType.minutes30;
  List<Consumption> _consumptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConsumptions();
  }

  Future<void> _loadConsumptions() async {
    setState(() => _loading = true);

    List<Consumption> data = [];
    switch (_selectedType) {
      case ConsumptionType.minutes30:
        data = await StorageService.instance.getHalfHourConsumptions();
        break;
      case ConsumptionType.daily:
        data = await StorageService.instance.getDailyConsumptions();
        break;
      case ConsumptionType.weekly:
        data = await StorageService.instance.getWeeklyConsumptions();
        break;
      case ConsumptionType.monthly:
        data = await StorageService.instance.getMonthlyConsumptions();
        break;
    }

    // Ajusta para valores mais realistas
    data = data.map((c) {
      double adjusted = c.volumeChange;
      if (_selectedType == ConsumptionType.daily) adjusted *= 50; // litros/dia
      if (_selectedType == ConsumptionType.weekly)
        adjusted *= 350; // litros/semana
      if (_selectedType == ConsumptionType.monthly)
        adjusted *= 1500; // litros/mês
      return Consumption(volumeChange: adjusted, timestamp: c.timestamp);
    }).toList();

    setState(() {
      _consumptions = data;
      _loading = false;
    });
  }

  List<FlSpot> _toSpots(List<Consumption> list, int minLength) {
    if (list.isEmpty)
      return List.generate(minLength, (i) => FlSpot(i.toDouble(), 0));
    return List.generate(
      list.length,
      (i) => FlSpot(i.toDouble(), list[i].volumeChange),
    );
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 50;
    double max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return (max * 1.2).ceilToDouble(); // deixa espaço acima da linha
  }

  LineChartData _buildChartData(List<Consumption> list, int minLength) {
    final spots = _toSpots(list, minLength);
    final maxY = _getMaxY(spots);

    // garante que o intervalo nunca seja zero
    double leftInterval = maxY / 5;
    if (leftInterval <= 0) leftInterval = 1;

    return LineChartData(
      minY: 0,
      maxY: maxY,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, _) => Text('${value.toInt() + 1}'),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: leftInterval, // aqui está seguro
            getTitlesWidget: (value, _) => Text('${value.toInt()} L'),
          ),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          dotData: FlDotData(show: true),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((t) {
              return LineTooltipItem(
                '${t.y.toStringAsFixed(0)} L',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildChart(String title, List<Consumption> data, int minLength) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(_buildChartData(data, minLength)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumo Detalhado')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<ConsumptionType>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(
                  value: ConsumptionType.minutes30,
                  child: Text('Últimos 30 min'),
                ),
                DropdownMenuItem(
                  value: ConsumptionType.daily,
                  child: Text('Diário'),
                ),
                DropdownMenuItem(
                  value: ConsumptionType.weekly,
                  child: Text('Semanal'),
                ),
                DropdownMenuItem(
                  value: ConsumptionType.monthly,
                  child: Text('Mensal'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                  _loadConsumptions();
                }
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildChart(
                          'Consumo Diário',
                          _selectedType == ConsumptionType.daily
                              ? _consumptions
                              : [],
                          7,
                        ),
                        _buildChart(
                          'Consumo Semanal',
                          _selectedType == ConsumptionType.weekly
                              ? _consumptions
                              : [],
                          4,
                        ),
                        _buildChart(
                          'Consumo Mensal',
                          _selectedType == ConsumptionType.monthly
                              ? _consumptions
                              : [],
                          6,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

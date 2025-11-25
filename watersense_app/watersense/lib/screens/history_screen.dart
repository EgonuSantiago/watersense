import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/consumption.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Consumption> _list = [];
  String _selectedType = 'halfHour'; // tipo inicial
  final Map<String, String> _typeLabels = {
    'halfHour': '30 Minutos',
    'daily': 'Diário',
    'weekly': 'Semanal',
    'monthly': 'Mensal',
  };

  @override
  void initState() {
    super.initState();
    _loadConsumptions();
  }

  Future<void> _loadConsumptions() async {
    List<Consumption> data;

    switch (_selectedType) {
      case 'daily':
        data = await StorageService.instance.getDailyConsumptions();
        break;
      case 'weekly':
        data = await StorageService.instance.getWeeklyConsumptions();
        break;
      case 'monthly':
        data = await StorageService.instance.getMonthlyConsumptions();
        break;
      case 'halfHour':
      default:
        data = await StorageService.instance.getHalfHourConsumptions();
        break;
    }

    // Exibe os dados em ordem decrescente de timestamp
    setState(() => _list = data.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: Column(
        children: [
          // Dropdown para escolher o tipo de agregação
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedType,
              items: _typeLabels.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                  _loadConsumptions();
                }
              },
            ),
          ),
          Expanded(
            child: _list.isEmpty
                ? const Center(child: Text('Sem dados'))
                : ListView.builder(
                    itemCount: _list.length,
                    itemBuilder: (context, idx) {
                      final c = _list[idx];
                      return ListTile(
                        title: Text('${c.volumeChange.toStringAsFixed(2)} L'),
                        subtitle: Text(fmt.format(c.timestamp)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

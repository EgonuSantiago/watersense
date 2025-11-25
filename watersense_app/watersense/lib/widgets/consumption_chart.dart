import 'package:flutter/material.dart';
import '../models/consumption.dart';
import 'package:intl/intl.dart';

class ConsumptionChart extends StatelessWidget {
  final List<Consumption> consumptions;

  const ConsumptionChart({required this.consumptions, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (consumptions.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    // Agrupa os consumos de acordo com o tipo
    final Map<String, double> grouped = {};

    for (var c in consumptions) {
      String key;

      switch (c.type) {
        case ConsumptionType.minutes30:
          key = DateFormat('yyyy-MM-dd HH:mm').format(c.timestamp);
          break;
        case ConsumptionType.daily:
          key = DateFormat('yyyy-MM-dd').format(c.timestamp);
          break;
        case ConsumptionType.weekly:
          final week = _weekNumber(c.timestamp);
          key = '${c.timestamp.year}-Semana $week';
          break;
        case ConsumptionType.monthly:
          key = DateFormat('yyyy-MM').format(c.timestamp);
          break;
      }

      grouped[key] = (grouped[key] ?? 0) + c.volumeChange;
    }

    // Ordena pelo timestamp
    final items = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      children: items
          .map(
            (e) => ListTile(
              title: Text(e.key),
              trailing: Text('${e.value.toStringAsFixed(2)} L'),
            ),
          )
          .toList(),
    );
  }

  // Função para calcular número da semana do ano
  int _weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}

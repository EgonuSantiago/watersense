import 'package:flutter/material.dart';
import '../models/consumption.dart';

class ConsumptionChart extends StatelessWidget {
  final List<Consumption> consumptions;
  const ConsumptionChart({required this.consumptions, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final byDay = <String, double>{};
    for (var c in consumptions) {
      final key = '${c.timestamp.year}-${c.timestamp.month}-${c.timestamp.day}';
      byDay[key] = (byDay[key] ?? 0) + c.volumeChange;
    }

    final items = byDay.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

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
}

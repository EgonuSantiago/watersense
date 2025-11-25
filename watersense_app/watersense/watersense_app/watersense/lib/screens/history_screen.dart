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

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final l = await StorageService.instance.getAllConsumptions();
    setState(() => _list = l.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: ListView.builder(
        itemCount: _list.length,
        itemBuilder: (context, idx) {
          final c = _list[idx];
          return ListTile(
            title: Text('${c.volumeChange.toStringAsFixed(2)} L'),
            subtitle: Text(fmt.format(c.timestamp)),
          );
        },
      ),
    );
  }
}

enum ConsumptionType { minutes30, daily, weekly, monthly }

class Consumption {
  final double volumeChange;
  final DateTime timestamp;
  final ConsumptionType type;

  Consumption({
    required this.volumeChange,
    required this.timestamp,
    this.type = ConsumptionType.minutes30, // padrão para medições normais
  });

  Map<String, dynamic> toJson() => {
    'volumeChange': volumeChange,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name, // usa o nome do enum para salvar
  };

  factory Consumption.fromJson(Map<String, dynamic> j) => Consumption(
    volumeChange: (j['volumeChange'] as num).toDouble(),
    timestamp: DateTime.parse(j['timestamp']),
    type: j['type'] != null
        ? ConsumptionType.values.firstWhere(
            (e) => e.name == j['type'],
            orElse: () => ConsumptionType.minutes30,
          )
        : ConsumptionType.minutes30,
  );
}

class Consumption {
  final double volumeChange;
  final DateTime timestamp;

  Consumption({required this.volumeChange, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'volumeChange': volumeChange,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Consumption.fromJson(Map<String, dynamic> j) => Consumption(
    volumeChange: (j['volumeChange'] as num).toDouble(),
    timestamp: DateTime.parse(j['timestamp']),
  );
}

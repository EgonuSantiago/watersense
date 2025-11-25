class WaterTank {
  final String type;
  final int capacityLiter;
  final double tariffPerLiter;
  final double topRadius;
  final double bottomRadius;
  final double tankHeight;

  WaterTank({
    required this.type,
    required this.capacityLiter,
    required this.tariffPerLiter,
    required this.topRadius,
    required this.bottomRadius,
    required this.tankHeight,
  });

  factory WaterTank.defaultCylinder() => WaterTank(
    type: 'cilindrica',
    capacityLiter: 1000,
    tariffPerLiter: 0.005,
    topRadius: 0,
    bottomRadius: 0,
    tankHeight: 1.5,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'capacityLiter': capacityLiter,
    'tariffPerLiter': tariffPerLiter,
    'topRadius': topRadius,
    'bottomRadius': bottomRadius,
    'tankHeight': tankHeight,
  };

  factory WaterTank.fromJson(Map<String, dynamic> j) => WaterTank(
    type: j['type'] ?? 'cilindrica',
    capacityLiter: (j['capacityLiter'] as num).toInt(),
    tariffPerLiter: (j['tariffPerLiter'] as num).toDouble(),
    topRadius: (j['topRadius'] as num).toDouble(),
    bottomRadius: (j['bottomRadius'] as num).toDouble(),
    tankHeight: (j['tankHeight'] as num).toDouble(),
  );
}

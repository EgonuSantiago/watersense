class WaterTank {
  final String type; // "cilindrica", "retangular", etc.
  final int capacityLiter;
  final double tariffPerLiter;
  final double topRadius;
  final double bottomRadius;
  final double tankHeight;
  final Map<double, double> calibrationTable; // altura -> volume

  WaterTank({
    required this.type,
    required this.capacityLiter,
    required this.tariffPerLiter,
    required this.topRadius,
    required this.bottomRadius,
    required this.tankHeight,
    required this.calibrationTable,
  });

  // Fábricas para caixas predefinidas
  factory WaterTank.l310() => WaterTank(
    type: 'cilindrica',
    capacityLiter: 310,
    tariffPerLiter: 0.005,
    topRadius: 0.35,
    bottomRadius: 0.35,
    tankHeight: 1.0,
    calibrationTable: {0.0: 0, 0.25: 77.5, 0.5: 155, 0.75: 232.5, 1.0: 310},
  );

  factory WaterTank.l500() => WaterTank(
    type: 'cilindrica',
    capacityLiter: 500,
    tariffPerLiter: 0.005,
    topRadius: 0.45,
    bottomRadius: 0.45,
    tankHeight: 1.2,
    calibrationTable: {0.0: 0, 0.3: 125, 0.6: 250, 0.9: 375, 1.2: 500},
  );

  factory WaterTank.l1000() => WaterTank(
    type: 'cilindrica',
    capacityLiter: 1000,
    tariffPerLiter: 0.005,
    topRadius: 0.55,
    bottomRadius: 0.55,
    tankHeight: 1.5,
    calibrationTable: {0.0: 0, 0.375: 250, 0.75: 500, 1.125: 750, 1.5: 1000},
  );

  // Construtor padrão
  factory WaterTank.defaultCylinder() => WaterTank.l1000();

  // Serialização para JSON
  Map<String, dynamic> toJson() => {
    'type': type,
    'capacityLiter': capacityLiter,
    'tariffPerLiter': tariffPerLiter,
    'topRadius': topRadius,
    'bottomRadius': bottomRadius,
    'tankHeight': tankHeight,
    'calibrationTable': calibrationTable,
  };

  // Desserialização segura do JSON
  factory WaterTank.fromJson(Map<String, dynamic>? j) {
    if (j == null) return WaterTank.defaultCylinder();

    Map<double, double> calib = {};
    if (j['calibrationTable'] != null) {
      calib = Map<double, double>.from(
        (j['calibrationTable'] as Map).map(
          (k, v) => MapEntry((k as num).toDouble(), (v as num).toDouble()),
        ),
      );
    }

    return WaterTank(
      type: j['type'] ?? 'cilindrica',
      capacityLiter: (j['capacityLiter'] as num?)?.toInt() ?? 1000,
      tariffPerLiter: (j['tariffPerLiter'] as num?)?.toDouble() ?? 0.005,
      topRadius: (j['topRadius'] as num?)?.toDouble() ?? 0.55,
      bottomRadius: (j['bottomRadius'] as num?)?.toDouble() ?? 0.55,
      tankHeight: (j['tankHeight'] as num?)?.toDouble() ?? 1.5,
      calibrationTable: calib.isNotEmpty
          ? calib
          : WaterTank.defaultCylinder().calibrationTable,
    );
  }
}

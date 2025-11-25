import 'dart:math';
import '../models/water_tank.dart';

class Calculations {
  static double volumeFromHeight(WaterTank tank, double heightMeters) {
    final h = heightMeters.clamp(0.0, tank.tankHeight);
    if (tank.type == 'cilindrica') {
      final capacityM3 = tank.capacityLiter / 1000.0;
      final radius = sqrt(capacityM3 / (pi * tank.tankHeight));
      final volumeM3 = pi * radius * radius * h;
      return volumeM3 * 1000.0;
    } else {
      final R = tank.topRadius;
      final r = tank.bottomRadius;
      final H = tank.tankHeight;
      if (H <= 0) return 0.0;
      final radiusAtH = r + (R - r) * (h / H);
      final r1 = r;
      final r2 = radiusAtH;
      final volumeM3 = (pi * h / 3.0) * (r1 * r1 + r1 * r2 + r2 * r2);
      return volumeM3 * 1000.0;
    }
  }

  static double percentFromHeight(WaterTank tank, double heightMeters) {
    final clamped = heightMeters.clamp(0.0, tank.tankHeight);
    if (tank.tankHeight <= 0) return 0.0;
    return (clamped / tank.tankHeight);
  }
}

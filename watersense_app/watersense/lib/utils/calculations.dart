import 'dart:math';
import '../models/water_tank.dart';

class Calculations {
  /// Retorna o volume em litros com base na altura, usando tabela de calibração se disponível
  static double volumeFromHeight(WaterTank tank, double heightMeters) {
    final h = heightMeters.clamp(0.0, tank.tankHeight);

    // Se houver tabela de calibração, usa interpolação
    if (tank.calibrationTable.isNotEmpty) {
      final table = tank.calibrationTable;
      final sortedHeights = table.keys.toList()..sort();

      if (h <= sortedHeights.first) return 0.0;
      if (h >= sortedHeights.last) return tank.capacityLiter.toDouble();

      for (int i = 0; i < sortedHeights.length - 1; i++) {
        final h1 = sortedHeights[i];
        final h2 = sortedHeights[i + 1];
        if (h >= h1 && h <= h2) {
          final v1 = table[h1]!;
          final v2 = table[h2]!;
          final t = (h - h1) / (h2 - h1);
          return v1 + (v2 - v1) * t;
        }
      }
    }

    // Fallback geométrico se não houver tabela
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
      final volumeM3 =
          (pi * h / 3.0) * (r * r + r * radiusAtH + radiusAtH * radiusAtH);
      return volumeM3 * 1000.0;
    }
  }

  /// Retorna a porcentagem do nível de água
  static double percentFromHeight(WaterTank tank, double heightMeters) {
    final h = heightMeters.clamp(0.0, tank.tankHeight);

    // Se houver tabela, calcula porcentagem pelo volume
    if (tank.calibrationTable.isNotEmpty) {
      final volume = volumeFromHeight(tank, h);
      return volume / tank.capacityLiter;
    }

    // Fallback geométrico
    if (tank.tankHeight <= 0) return 0.0;
    return h / tank.tankHeight;
  }
}

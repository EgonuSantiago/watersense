import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_tank.dart';
import '../models/consumption.dart';

class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    if (_prefs == null) _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- USER EMAIL ---
  Future<void> saveUserEmail(String email) async {
    final prefs = await _getPrefs;
    await prefs.setString('user_email', email);
  }

  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs;
    return prefs.getString('user_email');
  }

  // --- WATER TANK ---
  Future<void> saveWaterTank(WaterTank tank) async {
    final prefs = await _getPrefs;
    await prefs.setString('water_tank', jsonEncode(tank.toJson()));
  }

  Future<WaterTank?> getWaterTank() async {
    final prefs = await _getPrefs;
    final s = prefs.getString('water_tank');
    if (s == null) return null;
    try {
      final jsonData = jsonDecode(s);
      if (jsonData is Map<String, dynamic>) {
        return WaterTank.fromJson(jsonData);
      } else {
        print('⚠️ WaterTank salvo inválido');
        return null;
      }
    } catch (e) {
      print('⚠️ Erro ao ler WaterTank: $e');
      return null;
    }
  }

  // --- LAST VOLUME ---
  Future<void> saveLastVolume(double liters) async {
    final prefs = await _getPrefs;
    await prefs.setDouble('last_volume', liters);
  }

  Future<double?> getLastVolume() async {
    final prefs = await _getPrefs;
    return prefs.getDouble('last_volume');
  }

  // --- CONSUMPTION ---
  Future<void> saveConsumption(Consumption c) async {
    final prefs = await _getPrefs;
    final list = prefs.getStringList('consumptions') ?? [];
    list.add(jsonEncode(c.toJson()));
    await prefs.setStringList('consumptions', list);
  }

  Future<List<Consumption>> getAllConsumptions() async {
    final prefs = await _getPrefs;
    final list = prefs.getStringList('consumptions') ?? [];
    return list
        .map((s) {
          try {
            return Consumption.fromJson(jsonDecode(s));
          } catch (e) {
            print('⚠️ Consumo inválido: $e');
            return null;
          }
        })
        .whereType<Consumption>()
        .toList();
  }

  // --- AGREGADOS POR TIPO ---
  Future<List<Consumption>> getConsumptionsByType(ConsumptionType type) async {
    return (await getAllConsumptions()).where((c) => c.type == type).toList();
  }

  Future<List<Consumption>> getHalfHourConsumptions() async =>
      getConsumptionsByType(ConsumptionType.minutes30);

  Future<List<Consumption>> getDailyConsumptions() async =>
      getConsumptionsByType(ConsumptionType.daily);

  Future<List<Consumption>> getWeeklyConsumptions() async =>
      getConsumptionsByType(ConsumptionType.weekly);

  Future<List<Consumption>> getMonthlyConsumptions() async =>
      getConsumptionsByType(ConsumptionType.monthly);

  // --- AGREGAR AUTOMÁTICO ---
  Future<void> aggregateConsumptions() async {
    final halfHour = await getHalfHourConsumptions();

    // Agrupa em diário (48 medições de 30min = 24h)
    if (halfHour.length >= 48) {
      final last48 = halfHour.sublist(halfHour.length - 48);
      final dailyTotal = last48.fold<double>(
        0,
        (sum, c) => sum + c.volumeChange,
      );
      await saveConsumption(
        Consumption(
          volumeChange: dailyTotal,
          timestamp: DateTime.now(),
          type: ConsumptionType.daily,
        ),
      );
    }

    // Agrupa semanal (7 dias)
    final daily = await getDailyConsumptions();
    if (daily.length >= 7) {
      final last7 = daily.sublist(daily.length - 7);
      final weeklyTotal = last7.fold<double>(
        0,
        (sum, c) => sum + c.volumeChange,
      );
      await saveConsumption(
        Consumption(
          volumeChange: weeklyTotal,
          timestamp: DateTime.now(),
          type: ConsumptionType.weekly,
        ),
      );
    }

    // Agrupa mensal (4 semanas)
    final weekly = await getWeeklyConsumptions();
    if (weekly.length >= 4) {
      final last4 = weekly.sublist(weekly.length - 4);
      final monthlyTotal = last4.fold<double>(
        0,
        (sum, c) => sum + c.volumeChange,
      );
      await saveConsumption(
        Consumption(
          volumeChange: monthlyTotal,
          timestamp: DateTime.now(),
          type: ConsumptionType.monthly,
        ),
      );
    }
  }

  // --- HELPER: REMOVE ALL DATA ---
  Future<void> clearAll() async {
    final prefs = await _getPrefs;
    await prefs.clear();
  }
}

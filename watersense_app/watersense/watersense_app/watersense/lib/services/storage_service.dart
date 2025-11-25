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

  Future<void> saveUserEmail(String email) async {
    final p = await _getPrefs;
    await p.setString('user_email', email);
  }

  Future<void> saveWaterTank(WaterTank tank) async {
    final p = await _getPrefs;
    await p.setString('water_tank', jsonEncode(tank.toJson()));
  }

  Future<WaterTank?> getWaterTank() async {
    final p = await _getPrefs;
    final s = p.getString('water_tank');
    if (s == null) return null;
    return WaterTank.fromJson(jsonDecode(s));
  }

  Future<void> saveLastVolume(double liters) async {
    final p = await _getPrefs;
    await p.setDouble('last_volume', liters);
  }

  Future<double?> getLastVolume() async {
    final p = await _getPrefs;
    return p.getDouble('last_volume');
  }

  Future<void> saveConsumption(Consumption c) async {
    final p = await _getPrefs;
    final list = p.getStringList('consumptions') ?? [];
    list.add(jsonEncode(c.toJson()));
    await p.setStringList('consumptions', list);
  }

  Future<List<Consumption>> getAllConsumptions() async {
    final p = await _getPrefs;
    final list = p.getStringList('consumptions') ?? [];
    return list.map((s) => Consumption.fromJson(jsonDecode(s))).toList();
  }
}

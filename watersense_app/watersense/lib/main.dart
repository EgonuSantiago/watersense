import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/config_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/consumption_screen.dart';

void main() {
  runApp(WaterSenseApp());
}

class WaterSenseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaterSense',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // vai direto para o login sem permissões
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/config': (context) => ConfigScreen(),
        '/home': (context) => HomeScreen(),
        '/history': (context) => HistoryScreen(),
        '/consumption': (context) => ConsumptionScreen(),
      },
    );
  }
}

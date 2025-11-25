import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/config_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/consumption_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ Desativa Impeller (Vulkan) no Android para evitar travamentos em alguns dispositivos
  if (defaultTargetPlatform == TargetPlatform.android) {
    debugDisableImpeller();
  }

  runApp(WaterSenseApp());
}

void debugDisableImpeller() {
  debugPrint("⚠️ Impeller desativado, usando OpenGL Skia");
}

class WaterSenseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaterSense',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PermissionsWrapper(), // chama o wrapper de permissões
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

// Widget que pede a permissão de localização antes de mostrar a tela de login
class PermissionsWrapper extends StatefulWidget {
  @override
  _PermissionsWrapperState createState() => _PermissionsWrapperState();
}

class _PermissionsWrapperState extends State<PermissionsWrapper> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Corrigido: chamada da função
  }

  Future<void> _requestPermissions() async {
    // Solicita apenas a permissão de localização necessária para BLE
    await Permission.locationWhenInUse.request();

    // Verifica se a permissão foi concedida
    bool granted = await Permission.locationWhenInUse.isGranted;

    setState(() {
      _permissionsGranted = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsGranted) {
      // Mostra tela de carregamento enquanto solicita permissão
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Permissão concedida, vai para o login
    return LoginScreen();
  }
}

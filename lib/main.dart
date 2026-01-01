import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/ruler_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TapeMeasureApp());
}

class TapeMeasureApp extends StatelessWidget {
  const TapeMeasureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '줄자',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const RulerScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:schengen/providers/stay_provider.dart';
import 'package:schengen/screens/home_screen.dart';
import 'package:schengen/utils/logger.dart';
import 'package:time_machine/time_machine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger.init();
  final logger = AppLogger.getLogger('Main');
  logger.info('Initializing Schengen Tracker app');

  // Initialize Time Machine with rootBundle for Flutter
  try {
    await TimeMachine.initialize({'rootBundle': rootBundle});
    logger.info('Time Machine initialized successfully');
  } catch (e, stackTrace) {
    logger.severe('Failed to initialize Time Machine', e, stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StayProvider(),
      child: MaterialApp(
        title: 'Schengen Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A659E)),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

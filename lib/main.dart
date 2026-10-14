import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/local_storage_service.dart';
import 'services/firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/match_provider.dart';
import 'providers/request_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/review_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Local Storage
  final storage = await LocalStorageService.init();

  // Try initializing Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  runApp(SkillSwapApp(storage: storage));
}

class SkillSwapApp extends StatelessWidget {
  final LocalStorageService storage;

  const SkillSwapApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storage)),
        ChangeNotifierProvider(create: (_) => MatchProvider(storage)),
        ChangeNotifierProvider(create: (_) => RequestProvider(storage)),
        ChangeNotifierProvider(create: (_) => ChatProvider(storage)),
        ChangeNotifierProvider(create: (_) => ReviewProvider(storage)),
      ],
      child: MaterialApp(
        title: 'SkillSwap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

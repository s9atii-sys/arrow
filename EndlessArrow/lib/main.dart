import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/progress_service.dart';
import 'services/settings_service.dart';
import 'services/sfx_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Paint the first frame immediately. Waiting on AdMob (or network fonts)
  // before runApp is what left users on a white screen for several seconds.
  unawaited(_bootstrap());
  runApp(const ArrowChallengeApp());
}

Future<void> _bootstrap() async {
  await Future.wait([
    ProgressService.instance.load(),
    SettingsService.instance.load(),
  ]);
  unawaited(SfxService.instance.preload());
  unawaited(AdService.instance.initialize());
}

class ArrowChallengeApp extends StatefulWidget {
  const ArrowChallengeApp({super.key});

  @override
  State<ArrowChallengeApp> createState() => _ArrowChallengeAppState();
}

class _ArrowChallengeAppState extends State<ArrowChallengeApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onDetach: () {
        SfxService.instance.dispose();
        AdService.instance.dispose();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Challenge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFDCE1F5),
      ),
      home: const SplashScreen(),
    );
  }
}

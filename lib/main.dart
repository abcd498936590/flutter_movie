import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:movie/entity/video.dart';
import 'package:movie/pages/home_page.dart';
import 'package:movie/pages/player_page.dart';
import 'package:movie/pages/search_page.dart';
import 'package:movie/pages/settings_page.dart';
import 'package:movie/provider/movie_provider.dart';
import 'package:movie/request/dio_client.dart';
import 'package:movie/utils/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SpUtil().init();
  await HttpUtil().init();
  await windowManager.ensureInitialized();

  if (args.isNotEmpty && args.first == 'multi_window') {
    final String argumentString = args[2];
    if (argumentString == 'settings_window') {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => MovieProvider()..loadSettings(),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.green,
            ),
            home: const SettingsPage(),
          ),
        ),
      );
    } else if (argumentString == 'search_window') {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => MovieProvider()..loadSettings(),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.green,
            ),
            home: const SearchPage(),
          ),
        ),
      );
    } else {
      Map<String, dynamic> argument = {};
      try {
        if (argumentString.isNotEmpty) {
          argument = Map<String, dynamic>.from(jsonDecode(argumentString));
        }
      } catch (e) {
        debugPrint("Arg decoding error: $e");
      }
      final video = VideoSourceListItem.fromJson(argument);
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.green,
          ),
          home: PlayerPage(video: video),
        ),
      );
    }
  } else {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 750),
      center: true,
      title: 'Movie Desktop',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => MovieProvider())],

        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '影视迷',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

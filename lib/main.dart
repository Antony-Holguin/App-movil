import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qh_app/screens/my_home_page.dart';
import 'package:qh_app/screens/second_home_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social man app',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      //home: const MyHomePage(),
      home: const SecondHomePage(),
      locale: const Locale('es', 'ES'),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 11, 19, 28)));
  }
}

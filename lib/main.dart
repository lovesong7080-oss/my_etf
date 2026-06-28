import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyETFApp());
}

class MyETFApp extends StatelessWidget {
  const MyETFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '내 ETF',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
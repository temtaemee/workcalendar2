import 'package:flutter/material.dart';
import 'pages/mainpage.dart'; // 새로 만든 화면 import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Flutter App',
      home: const mainpage(), // 새 화면이 앱의 시작점이 됨
    );
  }
}

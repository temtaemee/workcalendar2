import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  String getTodayFormatted() {
    final now = DateTime.now();
    final year = DateFormat('yyyy년').format(now);
    final monthDay = DateFormat('MM월 dd일').format(now);
    return '$year\n$monthDay';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTodayFormatted(),
          textAlign: TextAlign.left,
          style: const TextStyle(fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text('Hello from Mainpage Page'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                '출근하기',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

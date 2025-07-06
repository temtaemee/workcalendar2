import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/mainpage.dart';
import 'pages/calendar.dart';
import 'pages/setting.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const HomeNavigation(),
    );
  }
}

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});
  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    MainPage(),
    Calendar(),
    Setting(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
              color: Color.fromARGB(255, 214, 214, 214),
              height: 1,
              thickness: 0.5),
          Container(
            height: 85,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: '메인'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today), label: '캘린더'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings), label: '설정'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

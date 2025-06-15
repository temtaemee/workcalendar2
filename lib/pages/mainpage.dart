import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/company.dart';
import '../widgets/company_modal.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 1; // 0: 일, 1: 주, 2: 월

  // 출근/퇴근 상태 및 시간 관련 변수
  bool isWorking = false;
  DateTime? startTime;
  Duration workingDuration = Duration.zero;
  Timer? timer;

  String getTodayFormatted() {
    final now = DateTime.now();
    final year = DateFormat('yyyy년').format(now);
    final monthDay = DateFormat('MM월 dd일').format(now);
    return '$year\n$monthDay';
  }

  String getWorkStatTitle() {
    switch (selectedIndex) {
      case 0:
        return '오늘 근무 통계';
      case 1:
        return '이번 주 근무 통계';
      case 2:
        return '이번 달 근무 통계';
      default:
        return '';
    }
  }

  String getPayTitle() {
    switch (selectedIndex) {
      case 0:
        return '오늘 주급 계산';
      case 1:
        return '이번 주 주급 계산';
      case 2:
        return '이번 달 주급 계산';
      default:
        return '';
    }
  }

  void startWork() {
    setState(() {
      isWorking = true;
      startTime = DateTime.now();
      workingDuration = Duration.zero;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        workingDuration = DateTime.now().difference(startTime!);
      });
    });
  }

  void endWork() {
    setState(() {
      isWorking = false;
      timer?.cancel();
      timer = null;
    });
  }

  String getWorkingTimeText() {
    if (!isWorking || startTime == null) {
      return '오늘 0시간 0분 근무';
    }
    final hours = workingDuration.inHours;
    final minutes = workingDuration.inMinutes % 60;
    return '오늘 ${hours}시간 ${minutes}분째 근무 중';
  }

  void _showAddCompanyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CompanyModal(
          onSave: (Company company) {
            // TODO: 회사 정보 저장 로직 구현
            print(company.toJson());
          },
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
          // 상단 일|주|월 버튼
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ToggleButtons(
                  isSelected: [
                    selectedIndex == 0,
                    selectedIndex == 1,
                    selectedIndex == 2,
                  ],
                  borderRadius: BorderRadius.circular(20),
                  selectedColor: Colors.black,
                  color: Colors.black,
                  fillColor: Colors.grey[200],
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 32),
                  children: const [
                    Text('일'),
                    Text('주'),
                    Text('월'),
                  ],
                  onPressed: (int index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),
              ],
            ),
          ),
          // 위쪽 여백 및 통계 영역
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getWorkStatTitle(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      '총 0 시간',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('• 회사를 추가하세요'),
                    GestureDetector(
                      onTap: _showAddCompanyModal,
                      child: const Text('+', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  '목표시간을 설정 할 수 있습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // 주급 계산 영역
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getPayTitle(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      '총 0 원',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('• 시급을 설정해주세요'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.arrow_drop_down, size: 18),
                          Text('시급'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('0원'),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  '목표금액을 설정 할 수 있습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Spacer(),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Color.fromARGB(255, 60, 60, 60),
                    width: 0.5
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getWorkingTimeText(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: isWorking ? endWork : startWork,
                    style: TextButton.styleFrom(
                      backgroundColor: isWorking
                          ? Colors.redAccent // 퇴근하기일 때 빨간색
                          : const Color(0xFFB9FF8A), // 출근하기일 때 연두색
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isWorking ? '퇴근하기' : '출근하기',
                      style: TextStyle(
                        color: isWorking ? Colors.white : Colors.black, // 퇴근하기는 흰색, 출근하기는 검정
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

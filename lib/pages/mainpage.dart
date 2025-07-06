import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/company.dart';
import '../models/work_schedule.dart';
import '../repositories/work_schedule_repository.dart';
import '../widgets/company_modal.dart';
import '../repositories/company_repository.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final WorkScheduleRepository _workScheduleRepository = WorkScheduleRepository();
  final CompanyRepository _companyRepository = CompanyRepository();
  
  int selectedIndex = 1; // 0: 일, 1: 주, 2: 월
  Duration _totalWorkDuration = Duration.zero;
  double _totalPay = 0.0;
  List<Company> _companies = [];
  Map<int?, Duration> _workDurationByCompany = {};
  bool _isLoading = false;

  bool isWorking = false;
  DateTime? startTime;
  Duration workingDuration = Duration.zero;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    setState(() { _isLoading = true; });

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (selectedIndex) {
      case 0: // 일
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 1: // 주
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 2: // 월
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      default:
        return;
    }

    final schedules = await _workScheduleRepository.getSchedulesByDateRange(startDate, endDate);
    final companies = await _companyRepository.getAllCompanies();

    Duration totalDuration = Duration.zero;
    double totalPay = 0.0;
    Map<int?, Duration> workDurationByCompany = {};

    for (final schedule in schedules) {
      final duration = schedule.workingHours;
      totalDuration += duration;

      workDurationByCompany[schedule.companyId] = 
          (workDurationByCompany[schedule.companyId] ?? Duration.zero) + duration;

      if (schedule.company != null && schedule.company!.paymentType == PaymentType.hourly) {
        final hourlyRate = schedule.company!.paymentAmount ?? 0;
        totalPay += (duration.inMinutes / 60.0) * hourlyRate;
      }
    }
    
    if(mounted) {
      setState(() {
        _totalWorkDuration = totalDuration;
        _totalPay = totalPay;
        _companies = companies;
        _workDurationByCompany = workDurationByCompany;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes <= 0) return '0h';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  String getTodayFormatted() {
    final now = DateTime.now();
    final year = DateFormat('yyyy년').format(now);
    final monthDay = DateFormat('MM월 dd일').format(now);
    return '$year $monthDay';
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
    return '예상 급여';
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
          onSave: (Company company) async {
            await _companyRepository.addCompany(company);
            await _fetchStatistics();
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
        toolbarHeight: 60,
        title: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              getTodayFormatted(),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 20, //글자 크기
                fontWeight: FontWeight.w600, //볻드
                color: Colors.black87, //글자 색
              ),
            )),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
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
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 32),
                  children: const [
                    Text('일'),
                    Text('주'),
                    Text('월'),
                  ],
                  onPressed: (int index) {
                    setState(() {
                      selectedIndex = index;
                    });
                    _fetchStatistics();
                  },
                ),
              ],
            ),
          ),
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
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '총 ${_formatDuration(_totalWorkDuration)}',
                      style: const
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_companies.isEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('• 회사를 추가하세요'),
                      GestureDetector(
                        onTap: _showAddCompanyModal,
                        child: const Text('+', style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  )
                else
                  ...[
                    if (_workDurationByCompany[null] != null && _workDurationByCompany[null]! > Duration.zero)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('-'),
                            Text(
                              _formatDuration(_workDurationByCompany[null]!),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ..._companies.map((company) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: company.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(company.name),
                                ],
                              ),
                              Text(
                                _formatDuration(_workDurationByCompany[company.id] ?? Duration.zero),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                  ],
                const SizedBox(height: 32),
                const Text(
                  '목표시간을 설정 할 수 있습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
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
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '총 ${NumberFormat.decimalPattern().format(_totalPay)} 원',
                      style: const
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_companies.isEmpty || _companies.every((c) => c.paymentAmount == null || c.paymentAmount == 0))
                  const Text('• 시급을 설정해주세요')
                else
                  ..._companies.where((c) => c.paymentAmount != null && c.paymentAmount! > 0).map((company) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: company.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${company.name} | 시급 ${NumberFormat.decimalPattern().format(company.paymentAmount)}원'),
                          ],
                        ),
                      )),
                const SizedBox(height: 32),
                const Text(
                  '목표금액을 설정 할 수 있습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            height: 60,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(31, 101, 101, 101),
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
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
                        ? const Color.fromARGB(255, 255, 43, 43)
                        : const Color.fromARGB(255, 169, 255, 77),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isWorking ? '퇴근하기' : '출근하기',
                    style: TextStyle(
                      color: isWorking ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

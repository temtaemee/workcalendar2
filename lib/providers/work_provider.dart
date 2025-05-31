import 'package:flutter/material.dart';
import 'dart:async';
import '../models/work_record.dart';
import '../models/company.dart';
import '../database_helper.dart';

class WorkProvider extends ChangeNotifier {
  final List<WorkRecord> _records = [];
  List<Company> _companies = [];
  DateTime? _checkInDateTime;
  String _selectedPeriod = '주간';
  final List<String> periods = ['일간', '주간', '월간', '연간'];
  Company? _selectedCompany;
  Timer? _timer;
  Duration _currentWorkDuration = Duration.zero;
  bool _hasAttemptedLoad = false;
  
  List<WorkRecord> get records => _records;
  List<Company> get companies => _companies;
  DateTime? get checkInDateTime => _checkInDateTime;
  TimeOfDay? get checkInTime => _checkInDateTime != null 
      ? TimeOfDay.fromDateTime(_checkInDateTime!)
      : null;
  String get selectedPeriod => _selectedPeriod;
  Company? get selectedCompany => _selectedCompany;
  bool get isCheckedIn => _checkInDateTime != null;
  bool get hasCompanies => _companies.isNotEmpty;
  Duration get currentWorkDuration => _currentWorkDuration;
  bool get hasAttemptedLoad => _hasAttemptedLoad;

  WorkProvider() {
    loadCompanies();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadCompanies() async {
    try {
      print("WorkProvider: 회사 목록 로딩 시작...");
      _companies = await DatabaseHelper().getCompanies();
      print("WorkProvider: 로딩된 회사 수: ${_companies.length}");
      if (_companies.isNotEmpty && _selectedCompany == null) {
        _selectedCompany = _companies.first;
        print("WorkProvider: 기본 선택된 회사: ${_selectedCompany?.name}");
      }
    } catch (e) {
      print("WorkProvider: 회사 로딩 중 에러 발생: $e");
      _companies = []; // 에러 발생 시 빈 리스트로 처리
    } finally {
      _hasAttemptedLoad = true;
      print("WorkProvider: 회사 로딩 시도 완료. hasAttemptedLoad: $_hasAttemptedLoad");
      notifyListeners(); // 데이터 로드 완료/실패 후 UI 갱신
    }
  }

  void addCompany(Company company) {
    _companies.add(company);
    if (_companies.length == 1) {
      _selectedCompany = company;
    }
    notifyListeners();
  }

  void setSelectedCompany(Company company) {
    _selectedCompany = company;
    notifyListeners();
  }

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_checkInDateTime != null) {
        final now = DateTime.now();
        _currentWorkDuration = now.difference(_checkInDateTime!);
        notifyListeners();
      }
    });
  }

  void checkIn() {
    if (_selectedCompany == null) return;
    _checkInDateTime = DateTime.now();
    _currentWorkDuration = Duration.zero;
    _startTimer();
    notifyListeners();
  }

  void checkOut() {
    if (_checkInDateTime == null || _selectedCompany == null) return;
    
    _timer?.cancel();
    final record = WorkRecord(
      date: DateTime.now(),
      checkIn: TimeOfDay.fromDateTime(_checkInDateTime!),
      checkOut: TimeOfDay.fromDateTime(DateTime.now()),
      companyId: _selectedCompany!.id!,
      hourlyWage: _selectedCompany!.hourlyWage,
    );
    
    _records.add(record);
    _checkInDateTime = null;
    _currentWorkDuration = Duration.zero;
    notifyListeners();
  }

  Duration getWorkDuration() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '일간':
        startDate = DateTime(now.year, now.month, now.day);
      case '주간':
        startDate = now.subtract(Duration(days: now.weekday - 1));
      case '월간':
        startDate = DateTime(now.year, now.month, 1);
      case '연간':
        startDate = DateTime(now.year, 1, 1);
      default:
        startDate = now;
    }
    
    return _records
        .where((record) => record.date.isAfter(startDate))
        .fold(Duration.zero, (prev, record) => prev + record.workDuration);
  }

  double getWage() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '일간':
        startDate = DateTime(now.year, now.month, now.day);
      case '주간':
        startDate = now.subtract(Duration(days: now.weekday - 1));
      case '월간':
        startDate = DateTime(now.year, now.month, 1);
      case '연간':
        startDate = DateTime(now.year, 1, 1);
      default:
        startDate = now;
    }
    
    return _records
        .where((record) => record.date.isAfter(startDate))
        .fold(0.0, (prev, record) => prev + record.dailyWage);
  }

  String getPeriodLabel() {
    switch (_selectedPeriod) {
      case '일간':
        return '오늘';
      case '주간':
        return '이번 주';
      case '월간':
        return '이번 달';
      case '연간':
        return '올해';
      default:
        return '';
    }
  }
} 
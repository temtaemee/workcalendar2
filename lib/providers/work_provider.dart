import 'package:flutter/material.dart';
import 'dart:async';
import '../models/work_record.dart';
import '../models/company.dart';

class WorkProvider extends ChangeNotifier {
  final List<WorkRecord> _records = [];
  final List<Company> _companies = [];
  DateTime? _checkInDateTime;
  String _selectedPeriod = '주간';
  final List<String> periods = ['일간', '주간', '월간', '연간'];
  Company? _selectedCompany;
  Timer? _timer;
  Duration _currentWorkDuration = Duration.zero;
  
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      company: _selectedCompany!.name,
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
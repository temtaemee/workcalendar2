import 'package:flutter/material.dart';
import 'dart:async';
import '../models/work_record.dart';
import '../models/company.dart';
import '../database_helper.dart';

class WorkProvider extends ChangeNotifier {
  List<Company> _companies = [];
  DateTime? _checkInDateTime;
  int? _currentWorkRecordId; // 출근중인 WorkRecord의 id
  String _selectedPeriod = '주간';
  final List<String> periods = ['일간', '주간', '월간', '연간'];
  Company? _selectedCompany;
  Timer? _timer;
  Duration _currentWorkDuration = Duration.zero;
  bool _hasAttemptedLoad = false;
  
  List<Company> get companies => _companies;
  DateTime? get checkInDateTime => _checkInDateTime;
  DateTime? get checkInTime => _checkInDateTime;
  String get selectedPeriod => _selectedPeriod;
  Company? get selectedCompany => _selectedCompany;
  bool get isCheckedIn => _checkInDateTime != null;
  bool get hasCompanies => _companies.isNotEmpty;
  Duration get currentWorkDuration => _currentWorkDuration;
  bool get hasAttemptedLoad => _hasAttemptedLoad;

  WorkProvider() {
    loadCompanies();
    _restoreCheckInState();
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

  Future<void> _restoreCheckInState() async {
    final db = DatabaseHelper();
    final dbRecords = await db.getWorkRecords();
    final ongoingList = dbRecords.where((r) => r.checkOut == null).toList();
    final ongoing = ongoingList.isNotEmpty ? ongoingList.first : null;
    if (ongoing != null) {
      _checkInDateTime = ongoing.checkIn;
      _currentWorkRecordId = ongoing.id;
      _startTimer();
      notifyListeners();
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
        final now = DateTime.now().toUtc().add(const Duration(hours: 9));
        _currentWorkDuration = now.difference(_checkInDateTime!);
        notifyListeners();
      }
    });
  }

  void checkIn() async {
    if (_selectedCompany == null) return;
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    _checkInDateTime = now;
    _currentWorkDuration = Duration.zero;
    final record = WorkRecord(
      date: DateTime(now.year, now.month, now.day),
      checkIn: now,
      checkOut: null,
      companyId: _selectedCompany!.id!,
      hourlyWage: _selectedCompany!.hourlyWage,
    );
    print('[출근] companyId: \'${_selectedCompany!.id}\', time: \'${now}\'');
    final id = await DatabaseHelper().insertWorkRecord(record);
    _currentWorkRecordId = id;
    _startTimer();
    notifyListeners();
  }

  void checkOut() async {
    if (_checkInDateTime == null || _selectedCompany == null || _currentWorkRecordId == null) return;
    _timer?.cancel();
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    // 기존 출근 기록 불러오기
    final db = DatabaseHelper();
    final dbRecords = await db.getWorkRecords();
    final recordList = dbRecords.where((r) => r.id == _currentWorkRecordId).toList();
    final record = recordList.isNotEmpty ? recordList.first : null;
    if (record != null) {
      final updated = WorkRecord(
        id: record.id,
        date: record.date,
        checkIn: record.checkIn,
        checkOut: now,
        companyId: record.companyId,
        hourlyWage: record.hourlyWage,
      );
      print('[퇴근] companyId: \'${record.companyId}\', time: \'${now}\'');
      await db.updateWorkRecord(updated);
    }
    _checkInDateTime = null;
    _currentWorkRecordId = null;
    _currentWorkDuration = Duration.zero;
    notifyListeners();
  }

  Future<Duration> getWorkDuration() async {
    final dbRecords = await DatabaseHelper().getWorkRecords();
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '일간':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case '주간':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case '월간':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case '연간':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now;
    }

    return dbRecords
        .where((record) => record.date.isAfter(startDate))
        .fold<Duration>(Duration.zero, (prev, record) => prev + record.workDuration);
  }

  Future<double> getWage() async {
    final dbRecords = await DatabaseHelper().getWorkRecords();
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '일간':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case '주간':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case '월간':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case '연간':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now;
    }

    return dbRecords
        .where((record) => record.date.isAfter(startDate))
        .fold<double>(0.0, (prev, record) => prev + record.dailyWage);
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
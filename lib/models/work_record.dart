import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // DateFormat을 위해 추가

class WorkRecord {
  final int? id;
  final DateTime date; // 'YYYY-MM-DD'로 저장될 예정
  final TimeOfDay? checkIn; // 'HH:mm'으로 저장될 예정
  final TimeOfDay? checkOut; // 'HH:mm'으로 저장될 예정
  final int companyId; // company 이름 대신 ID를 저장
  final double hourlyWage;

  WorkRecord({
    this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.companyId,
    required this.hourlyWage,
  });

  // TimeOfDay를 "HH:mm" 문자열로 변환
  String? _timeOfDayToString(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // "HH:mm" 문자열을 TimeOfDay로 변환
  TimeOfDay? _stringToTimeOfDay(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // DateTime을 "YYYY-MM-DD" 문자열로 변환
  String _dateToString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // "YYYY-MM-DD" 문자열을 DateTime으로 변환
  DateTime _stringToDate(String dateStr) {
    return DateFormat('yyyy-MM-dd').parse(dateStr);
  }

  // SQLite를 위한 Map 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': _dateToString(date), // 'YYYY-MM-DD'
      'checkIn': _timeOfDayToString(checkIn), // 'HH:mm'
      'checkOut': _timeOfDayToString(checkOut), // 'HH:mm'
      'company_id': companyId, // 외래 키
      'hourlyWage': hourlyWage,
    };
  }

  // SQLite Map에서 객체 생성
  factory WorkRecord.fromJson(Map<String, dynamic> json) {
    return WorkRecord(
      id: json['id'],
      date: DateFormat('yyyy-MM-dd').parse(json['date']),
      checkIn: json['checkIn'] != null ? TimeOfDay(hour: int.parse(json['checkIn'].split(':')[0]), minute: int.parse(json['checkIn'].split(':')[1])) : null,
      checkOut: json['checkOut'] != null ? TimeOfDay(hour: int.parse(json['checkOut'].split(':')[0]), minute: int.parse(json['checkOut'].split(':')[1])) : null,
      companyId: json['company_id'],
      hourlyWage: json['hourlyWage'],
    );
  }

  Duration get workDuration {
    if (checkIn == null || checkOut == null) return Duration.zero;
    
    final now = DateTime.now(); // 날짜는 중요하지 않음, 시간만 비교
    final checkInDateTime = DateTime(now.year, now.month, now.day, checkIn!.hour, checkIn!.minute);
    final checkOutDateTime = DateTime(now.year, now.month, now.day, checkOut!.hour, checkOut!.minute);
    
    // checkOut이 checkIn보다 이전 시간일 경우 (예: 야간 근무) 다음 날로 처리
    if (checkOutDateTime.isBefore(checkInDateTime)) {
      return checkOutDateTime.add(const Duration(days: 1)).difference(checkInDateTime);
    }
    return checkOutDateTime.difference(checkInDateTime);
  }

  double get dailyWage {
    final hours = workDuration.inMinutes / 60.0;
    return hours * hourlyWage;
  }
} 
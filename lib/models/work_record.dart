import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // DateFormat을 위해 추가

class WorkRecord {
  final int? id;
  final DateTime date; // 'YYYY-MM-DD'로 저장될 예정
  final DateTime? checkIn; // 'YYYY-MM-DD HH:mm'으로 저장될 예정
  final DateTime? checkOut; // 'YYYY-MM-DD HH:mm'으로 저장될 예정
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

  // DateTime을 "YYYY-MM-DD HH:mm" 문자열로 변환
  String? _dateTimeToString(DateTime? dateTime) {
    if (dateTime == null) return null;
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  // "YYYY-MM-DD HH:mm" 문자열을 DateTime으로 변환
  DateTime? _stringToDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return null;
    return DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeStr);
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
      'date': DateFormat('yyyy-MM-dd').format(date),
      'checkIn': checkIn != null ? DateFormat('yyyy-MM-dd HH:mm').format(checkIn!) : null,
      'checkOut': checkOut != null ? DateFormat('yyyy-MM-dd HH:mm').format(checkOut!) : null,
      'company_id': companyId,
      'hourlyWage': hourlyWage,
    };
  }

  // SQLite Map에서 객체 생성
  factory WorkRecord.fromJson(Map<String, dynamic> json) {
    return WorkRecord(
      id: json['id'],
      date: DateFormat('yyyy-MM-dd').parse(json['date']),
      checkIn: json['checkIn'] != null ? DateFormat('yyyy-MM-dd HH:mm').parse(json['checkIn']) : null,
      checkOut: json['checkOut'] != null ? DateFormat('yyyy-MM-dd HH:mm').parse(json['checkOut']) : null,
      companyId: json['company_id'],
      hourlyWage: json['hourlyWage'],
    );
  }

  Duration get workDuration {
    if (checkIn == null || checkOut == null) return Duration.zero;
    return checkOut!.difference(checkIn!);
  }

  double get dailyWage {
    final hours = workDuration.inMinutes / 60.0;
    return hours * hourlyWage;
  }
} 
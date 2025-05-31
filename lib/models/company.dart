import 'package:flutter/material.dart';

class Company {
  final int? id;
  final String name;
  final List<bool> workDays; // [월,화,수,목,금,토,일]
  final TimeOfDay startTime; // 'HH:mm'으로 저장될 예정
  final TimeOfDay endTime; // 'HH:mm'으로 저장될 예정
  final bool excludeLunchTime;
  final TimeOfDay? lunchStartTime; // 'HH:mm'으로 저장될 예정
  final TimeOfDay? lunchEndTime; // 'HH:mm'으로 저장될 예정
  final double hourlyWage;

  Company({
    this.id,
    required this.name,
    required this.workDays,
    required this.startTime,
    required this.endTime,
    required this.excludeLunchTime,
    this.lunchStartTime,
    this.lunchEndTime,
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

  // SQLite를 위한 Map 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workDays': workDays.map((b) => b.toString()).join(','), // "true,false,true" 형식
      'startTime': _timeOfDayToString(startTime),
      'endTime': _timeOfDayToString(endTime),
      'excludeLunchTime': excludeLunchTime ? 1 : 0, // SQLite는 boolean을 INTEGER로 저장
      'lunchStartTime': _timeOfDayToString(lunchStartTime),
      'lunchEndTime': _timeOfDayToString(lunchEndTime),
      'hourlyWage': hourlyWage,
    };
  }

  // SQLite Map에서 객체 생성
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      workDays: (json['workDays'] as String).split(',').map((s) => s == 'true').toList(),
      startTime: TimeOfDay(hour: int.parse(json['startTime'].split(':')[0]), minute: int.parse(json['startTime'].split(':')[1])),
      endTime: TimeOfDay(hour: int.parse(json['endTime'].split(':')[0]), minute: int.parse(json['endTime'].split(':')[1])),
      excludeLunchTime: json['excludeLunchTime'] == 1,
      lunchStartTime: json['lunchStartTime'] != null ? TimeOfDay(hour: int.parse(json['lunchStartTime'].split(':')[0]), minute: int.parse(json['lunchStartTime'].split(':')[1])) : null,
      lunchEndTime: json['lunchEndTime'] != null ? TimeOfDay(hour: int.parse(json['lunchEndTime'].split(':')[0]), minute: int.parse(json['lunchEndTime'].split(':')[1])) : null,
      hourlyWage: json['hourlyWage'],
    );
  }
} 
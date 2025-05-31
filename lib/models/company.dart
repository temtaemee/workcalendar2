import 'package:flutter/material.dart';

class Company {
  final String name;
  final List<bool> workDays; // [월,화,수,목,금,토,일]
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool excludeLunchTime;
  final TimeOfDay? lunchStartTime;
  final TimeOfDay? lunchEndTime;
  final double hourlyWage;

  Company({
    required this.name,
    required this.workDays,
    required this.startTime,
    required this.endTime,
    required this.excludeLunchTime,
    this.lunchStartTime,
    this.lunchEndTime,
    required this.hourlyWage,
  });

  // JSON 변환을 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'workDays': workDays,
      'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'excludeLunchTime': excludeLunchTime,
      'lunchStartTime': lunchStartTime != null
          ? {'hour': lunchStartTime!.hour, 'minute': lunchStartTime!.minute}
          : null,
      'lunchEndTime': lunchEndTime != null
          ? {'hour': lunchEndTime!.hour, 'minute': lunchEndTime!.minute}
          : null,
      'hourlyWage': hourlyWage,
    };
  }

  // JSON에서 객체 생성을 위한 팩토리 메서드
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'],
      workDays: List<bool>.from(json['workDays']),
      startTime: TimeOfDay(
        hour: json['startTime']['hour'],
        minute: json['startTime']['minute'],
      ),
      endTime: TimeOfDay(
        hour: json['endTime']['hour'],
        minute: json['endTime']['minute'],
      ),
      excludeLunchTime: json['excludeLunchTime'],
      lunchStartTime: json['lunchStartTime'] != null
          ? TimeOfDay(
              hour: json['lunchStartTime']['hour'],
              minute: json['lunchStartTime']['minute'],
            )
          : null,
      lunchEndTime: json['lunchEndTime'] != null
          ? TimeOfDay(
              hour: json['lunchEndTime']['hour'],
              minute: json['lunchEndTime']['minute'],
            )
          : null,
      hourlyWage: json['hourlyWage'],
    );
  }
} 
import 'package:flutter/material.dart';

enum PaymentType {
  hourly('시급'),
  weekly('주급'),
  monthly('월급');

  final String label;
  const PaymentType(this.label);
}

class Company {
  final int? id;
  final String name;
  final Color color;
  final List<bool> workingDays; // [일, 월, 화, 수, 목, 금, 토]
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final PaymentType? paymentType;
  final int? paymentAmount;
  final TimeOfDay? lunchStartTime;
  final TimeOfDay? lunchEndTime;
  final DateTime? regDate;
  final DateTime? uptDate;

  Company({
    this.id,
    required this.name,
    required this.color,
    required this.workingDays,
    required this.startTime,
    required this.endTime,
    this.paymentType,
    this.paymentAmount,
    this.lunchStartTime,
    this.lunchEndTime,
    this.regDate,
    this.uptDate,
  });

  // 추후 DB 저장을 위한 JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'workingDays': workingDays,
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'paymentType': paymentType?.name,
      'paymentAmount': paymentAmount,
      'lunchStartTime': lunchStartTime != null 
          ? '${lunchStartTime!.hour}:${lunchStartTime!.minute}' 
          : null,
      'lunchEndTime': lunchEndTime != null 
          ? '${lunchEndTime!.hour}:${lunchEndTime!.minute}' 
          : null,
      'regDate': regDate?.toIso8601String(),
      'uptDate': uptDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'workingDays': workingDays.map((e) => e ? 1 : 0).join(','),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'paymentType': paymentType?.name,
      'paymentAmount': paymentAmount,
      'lunchStartTime': lunchStartTime != null
          ? '${lunchStartTime!.hour}:${lunchStartTime!.minute}'
          : null,
      'lunchEndTime': lunchEndTime != null
          ? '${lunchEndTime!.hour}:${lunchEndTime!.minute}'
          : null,
      'regDate': regDate?.toIso8601String() ?? now,
      'uptDate': now,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    final startTimeParts = (map['startTime'] as String).split(':');
    final endTimeParts = (map['endTime'] as String).split(':');
    
    TimeOfDay? lunchStartTime;
    if (map['lunchStartTime'] != null) {
      final lunchStartParts = (map['lunchStartTime'] as String).split(':');
      lunchStartTime = TimeOfDay(hour: int.parse(lunchStartParts[0]), minute: int.parse(lunchStartParts[1]));
    }

    TimeOfDay? lunchEndTime;
    if (map['lunchEndTime'] != null) {
      final lunchEndParts = (map['lunchEndTime'] as String).split(':');
      lunchEndTime = TimeOfDay(hour: int.parse(lunchEndParts[0]), minute: int.parse(lunchEndParts[1]));
    }
    
    return Company(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      workingDays: (map['workingDays'] as String).split(',').map((e) => e == '1').toList(),
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      paymentType: map['paymentType'] != null ? PaymentType.values.byName(map['paymentType']) : null,
      paymentAmount: map['paymentAmount'],
      lunchStartTime: lunchStartTime,
      lunchEndTime: lunchEndTime,
      regDate: DateTime.parse(map['regDate']),
      uptDate: DateTime.parse(map['uptDate']),
    );
  }
} 
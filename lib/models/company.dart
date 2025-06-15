import 'package:flutter/material.dart';

enum PaymentType {
  hourly('시급'),
  weekly('주급'),
  monthly('월급');

  final String label;
  const PaymentType(this.label);
}

class Company {
  final int id;
  final String name;
  final List<bool> workingDays; // [일, 월, 화, 수, 목, 금, 토]
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final PaymentType? paymentType;
  final int? paymentAmount;
  final TimeOfDay? lunchStartTime;
  final TimeOfDay? lunchEndTime;

  Company({
    required this.id,
    required this.name,
    required this.workingDays,
    required this.startTime,
    required this.endTime,
    this.paymentType,
    this.paymentAmount,
    this.lunchStartTime,
    this.lunchEndTime,
  });

  // 추후 DB 저장을 위한 JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
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
    };
  }
} 
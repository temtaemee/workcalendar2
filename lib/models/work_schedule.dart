import 'package:workcalendar2/models/company.dart';

class WorkSchedule {
  final int? id;
  final int? companyId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime regDate;
  final DateTime uptDate;
  final Company? company;

  WorkSchedule({
    this.id,
    this.companyId,
    required this.startTime,
    required this.endTime,
    required this.regDate,
    required this.uptDate,
    this.company,
  });

  Duration get workingHours => endTime.difference(startTime);

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'companyId': companyId,
      'startDate': startTime.toIso8601String(),
      'endDate': endTime.toIso8601String(),
      'regDate': regDate.toIso8601String() ?? now,
      'uptDate': now,
    };
  }

  factory WorkSchedule.fromMap(Map<String, dynamic> map) {
    return WorkSchedule(
      id: map['id'],
      companyId: map['companyId'],
      startTime: DateTime.parse(map['startDate']),
      endTime: DateTime.parse(map['endDate']),
      regDate: DateTime.parse(map['regDate']),
      uptDate: DateTime.parse(map['uptDate']),
    );
  }

  WorkSchedule copyWith({
    int? id,
    int? companyId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? regDate,
    DateTime? uptDate,
    Company? company,
  }) {
    return WorkSchedule(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      regDate: regDate ?? this.regDate,
      uptDate: uptDate ?? this.uptDate,
      company: company ?? this.company,
    );
  }
} 
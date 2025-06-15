class WorkSchedule {
  final String id;
  final String companyId;
  final DateTime startTime;
  final DateTime endTime;

  WorkSchedule({
    required this.id,
    required this.companyId,
    required this.startTime,
    required this.endTime,
  });

  Duration get workingHours => endTime.difference(startTime);

  WorkSchedule copyWith({
    String? id,
    String? companyId,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return WorkSchedule(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
} 
import 'package:flutter/material.dart';

class WorkRecord {
  final DateTime date;
  final TimeOfDay? checkIn;
  final TimeOfDay? checkOut;
  final String company;
  final double hourlyWage;

  const WorkRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.company,
    required this.hourlyWage,
  });

  Duration get workDuration {
    if (checkIn == null || checkOut == null) return Duration.zero;
    
    final now = DateTime.now();
    final checkInTime = DateTime(
      now.year, now.month, now.day, 
      checkIn!.hour, checkIn!.minute
    );
    final checkOutTime = DateTime(
      now.year, now.month, now.day, 
      checkOut!.hour, checkOut!.minute
    );
    
    return checkOutTime.difference(checkInTime);
  }

  double get dailyWage {
    final hours = workDuration.inMinutes / 60.0;
    return hours * hourlyWage;
  }
} 
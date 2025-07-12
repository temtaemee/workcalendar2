import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:workcalendar2/models/work_schedule.dart';
import 'package:workcalendar2/models/company.dart';
import 'package:workcalendar2/repositories/work_schedule_repository.dart';
import '../widgets/day_detail_modal.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  final WorkScheduleRepository _workScheduleRepository = WorkScheduleRepository();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<WorkSchedule>> _events = {};

  @override
  void initState() {
    super.initState();
    _fetchSchedulesForMonth(_focusedDay);
  }

  void _fetchSchedulesForMonth(DateTime month) async {
    print('[Calendar] Fetching schedules for month: ${DateFormat('yyyy-MM').format(month)}');
    final schedules = await _workScheduleRepository.getSchedulesByMonth(month);
    final events = <DateTime, List<WorkSchedule>>{};
    for (var schedule in schedules) {
      final day = DateTime.utc(schedule.startTime.year, schedule.startTime.month, schedule.startTime.day);
      if (events[day] == null) {
        events[day] = [];
      }
      events[day]!.add(schedule);
    }
    print('[Calendar] Fetched ${schedules.length} schedules, grouped into ${events.keys.length} days.');
    setState(() {
      _events = events;
    });
  }

  List<WorkSchedule> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes == 0) return '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  Duration _calculateTotalDuration(List<WorkSchedule> schedules) {
    Duration totalDuration = Duration.zero;
    for (final schedule in schedules) {
      Duration scheduleDuration = schedule.endTime.difference(schedule.startTime);

      if (schedule.company?.lunchStartTime != null && schedule.company?.lunchEndTime != null) {
        final lunchStart = schedule.company!.lunchStartTime!;
        final lunchEnd = schedule.company!.lunchEndTime!;
        final lunchDuration = Duration(hours: lunchEnd.hour - lunchStart.hour, minutes: lunchEnd.minute - lunchStart.minute);
        scheduleDuration -= lunchDuration;
      }
      totalDuration += scheduleDuration;
    }
    return totalDuration;
  }

  void _showDayDetailModal(BuildContext context, DateTime selectedDay) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return DayDetailModal(
          selectedDay: selectedDay,
          schedules: _getEventsForDay(selectedDay),
          onTodayPressed: (DateTime today) {
            setState(() {
              _selectedDay = null;
              _focusedDay = today;
            });
          },
          onDataChanged: () {
            _fetchSchedulesForMonth(_focusedDay);
          },
        );
      },
    );
    // When the dialog is closed, refetch the data to ensure the calendar is up-to-date
    _fetchSchedulesForMonth(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          DateFormat('yyyy년 MM월').format(_focusedDay),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: TableCalendar(
        eventLoader: _getEventsForDay,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          final events = _getEventsForDay(selectedDay);
          print('[Calendar] Day selected: ${DateFormat('yyyy-MM-dd').format(selectedDay)}, found ${events.length} events.');
          _showDayDetailModal(context, selectedDay);
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          _fetchSchedulesForMonth(focusedDay);
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final events = _getEventsForDay(day);
            if (events.isNotEmpty) {
              final totalDuration = _calculateTotalDuration(events);
              return Container(
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(totalDuration),
                      style: const TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ],
                ),
              );
            }
            return null; // Use default builder for days with no events
          },
          markerBuilder: (context, day, events) {
            // 사용자의 요청에 따라 마커를 완전히 제거합니다.
            return const SizedBox.shrink();
          },
          todayBuilder: (context, day, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              child: Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${day.day}',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            final events = _getEventsForDay(day);
            final uniqueCompanies = events.map((e) => e.company).where((c) => c != null).toSet().toList();

            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${day.day}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    if (events.isNotEmpty)
                      Text(
                        _formatDuration(_calculateTotalDuration(events)),
                        style: const TextStyle(fontSize: 10, color: Colors.blue),
                      )
                    else 
                      const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.red),
          holidayTextStyle: const TextStyle(color: Colors.red),
          cellMargin: EdgeInsets.zero,
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.black87),
          weekendStyle: TextStyle(color: Colors.red),
        ),
        headerVisible: false,
        rowHeight: 80,
        daysOfWeekHeight: 20,
        pageAnimationEnabled: true,
        pageAnimationCurve: Curves.easeInOut,
        pageAnimationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

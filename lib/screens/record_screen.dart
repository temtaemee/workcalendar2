import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/work_provider.dart';
import '../models/work_record.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('근무 기록'),
        centerTitle: true,
      ),
      body: Consumer<WorkProvider>(
        builder: (context, provider, child) {
          final workRecords = _groupByDate(provider.records);
          return Column(
            children: [
              _buildCalendar(workRecords),
              const Divider(height: 1),
              Expanded(
                child: _selectedDay == null
                    ? const Center(child: Text('날짜를 선택하세요'))
                    : _buildDayRecords(workRecords[_selectedDay!] ?? []),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 날짜별 WorkRecord 리스트를 Map으로 그룹핑
  Map<DateTime, List<WorkRecord>> _groupByDate(List<WorkRecord> records) {
    return records.fold({}, (map, record) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      map[date] = [...(map[date] ?? []), record];
      return map;
    });
  }

  /// 캘린더 위젯
  Widget _buildCalendar(Map<DateTime, List<WorkRecord>> workRecords) {
    return TableCalendar<WorkRecord>(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      locale: 'ko_KR',
      daysOfWeekHeight: 30, // << 요일 영역 높이 설정
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: TextStyle(color: Colors.black),
        holidayTextStyle: TextStyle(color: Colors.red),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.black),
        weekendStyle: TextStyle(color: Colors.red),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey)),
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          if (day.weekday == DateTime.saturday) {
            return Center(
              child: Text(
                '${day.day}',
                style: const TextStyle(color: Colors.blue),
              ),
            );
          }
          return null;
        },
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: (day) => workRecords[DateTime(day.year, day.month, day.day)] ?? [],
    );
  }

  /// 선택한 날짜의 근무 기록 리스트
  Widget _buildDayRecords(List<WorkRecord> records) {
    if (records.isEmpty) {
      return const Center(child: Text('근무 기록이 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final r = records[index];
        final duration = r.workDuration;
        final wage = r.dailyWage;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.companyId.toString(), style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      '${NumberFormat('#,###').format(wage.round())}원',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${r.checkIn?.format(context)} ~ ${r.checkOut?.format(context)}'),
                    const Spacer(),
                    Text('${duration.inHours}시간 ${duration.inMinutes.remainder(60)}분'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

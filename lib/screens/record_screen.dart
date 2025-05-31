import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/work_provider.dart';
import '../models/work_record.dart';
import '../database_helper.dart';
import '../models/company.dart';

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
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('근무 기록'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Object?>>(
        future: Future.wait([
          DatabaseHelper().getWorkRecordsByDateRange(firstDayOfMonth, lastDayOfMonth),
          DatabaseHelper().getCompanies(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final workRecords = (snapshot.data![0] as List).cast<WorkRecord>();
          final companies = (snapshot.data![1] as List).cast<Company>();
          final companyMap = { for (var c in companies) c.id!: c };
          final workRecordsByDate = _groupByDate(workRecords);
          // 오늘 총 근무 시간 계산
          final today = DateTime.now();
          final todayRecords = workRecordsByDate[DateTime(today.year, today.month, today.day)] ?? [];
          final totalDuration = todayRecords.fold<Duration>(
            Duration.zero,
            (prev, r) => prev + r.workDuration,
          );
          String twoDigits(int n) => n.toString().padLeft(2, '0');
          final hh = twoDigits(totalDuration.inHours);
          final mm = twoDigits(totalDuration.inMinutes.remainder(60));
          // 선택된 날짜의 기록
          final selectedRecords = _selectedDay == null
              ? []
              : workRecordsByDate[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  '오늘 총 근무 시간: $hh:$mm',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildCalendar(workRecordsByDate),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildDayRecordsWithCompany(
                        (selectedRecords as List).cast<WorkRecord>(),
                        companyMap,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildDayRecordsWithCompany(List<WorkRecord> records, Map<int, Company> companyMap) {
    if (records.isEmpty) {
      return const Center(child: Text('근무 기록이 없습니다'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final r = records[index];
        final company = companyMap[r.companyId];
        final companyName = company?.name ?? '알 수 없음';
        final duration = r.workDuration;
        final timeStr = '${r.checkIn?.format(context) ?? '--:--'} ~ ${r.checkOut?.format(context) ?? '--:--'}';
        final durationStr = duration.inHours > 0
            ? '${duration.inHours}시간${duration.inMinutes.remainder(60) > 0 ? ' ${duration.inMinutes.remainder(60)}분' : ''}'
            : '${duration.inMinutes}분';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(companyName, style: Theme.of(context).textTheme.titleMedium),
                ),
                Expanded(
                  flex: 4,
                  child: Text(timeStr, style: const TextStyle(fontSize: 16)),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      durationStr,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

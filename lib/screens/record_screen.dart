import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
  DateTime _focusedDay = DateTime.now().toUtc().add(const Duration(hours: 9));
  DateTime? _selectedDay;
  Future<List<Object?>>? _futureData;

  @override
  void initState() {
    super.initState();
    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    _focusedDay = nowKst;
    _selectedDay = nowKst;
    _futureData = _loadMonthData(_focusedDay);
  }

  Future<List<Object?>> _loadMonthData(DateTime focusedDay) {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    return Future.wait([
      DatabaseHelper().getWorkRecordsByDateRange(firstDayOfMonth, lastDayOfMonth),
      DatabaseHelper().getCompanies(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '근무 기록',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<List<Object?>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final workRecords = (snapshot.data![0] as List).cast<WorkRecord>();
          final companies = (snapshot.data![1] as List).cast<Company>();
          final companyMap = { for (var c in companies) c.id!: c };
          final workRecordsByDate = _groupByDate(workRecords);
          final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
          final today = DateTime(nowKst.year, nowKst.month, nowKst.day);
          final todayRecords = workRecordsByDate[today] ?? [];
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '오늘 총 근무 시간: $hh:$mm',
                  style: GoogleFonts.notoSans(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildCalendar(workRecordsByDate),
                    ),
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
    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final todayKst = DateTime(nowKst.year, nowKst.month, nowKst.day);
    return TableCalendar<WorkRecord>(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      locale: 'ko_KR',
      rowHeight: 56,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: GoogleFonts.notoSans(
          color: Colors.black87,
          fontSize: 14,
        ),
        holidayTextStyle: GoogleFonts.notoSans(
          color: Colors.red[700],
          fontSize: 14,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue[700],
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.blue[100],
          shape: BoxShape.circle,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.notoSans(
          color: Colors.black87,
          fontSize: 14,
        ),
        weekendStyle: GoogleFonts.notoSans(
          color: Colors.red[700],
          fontSize: 14,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) => _buildDayCell(day, workRecords),
        selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, workRecords, isSelected: true),
        todayBuilder: (context, day, focusedDay) {
          final isKstToday = isSameDay(day, todayKst);
          return _buildDayCell(day, workRecords, isToday: isKstToday);
        },
        markerBuilder: (context, day, events) => SizedBox.shrink(),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          final kstSelected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
          final kstFocused = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
          _selectedDay = kstSelected;
          _focusedDay = kstFocused;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          final kstFocused = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
          _focusedDay = kstFocused;
          _futureData = _loadMonthData(kstFocused);
        });
      },
      eventLoader: (day) => workRecords[DateTime(day.year, day.month, day.day)] ?? [],
    );
  }

  Widget _buildDayCell(DateTime day, Map<DateTime, List<WorkRecord>> workRecords, {bool isSelected = false, bool isToday = false}) {
    final records = workRecords[DateTime(day.year, day.month, day.day)] ?? [];
    final totalDuration = records.fold<Duration>(
      Duration.zero,
          (prev, r) => prev + r.workDuration,
    );
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hh = twoDigits(totalDuration.inHours);
    final mm = twoDigits(totalDuration.inMinutes.remainder(60));
    final bgColor = isSelected
        ? Colors.blue[700]
        : isToday
        ? Colors.blue[100]
        : Colors.transparent;
    final textColor = isSelected ? Colors.white : Colors.black;

    return SizedBox(
      height: 56, // 여기로 고정
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: Text(
                '${day.day}',
                style: TextStyle(color: textColor),
              ),
            ),
            if (records.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '$hh:$mm',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildDayRecordsWithCompany(List<WorkRecord> records, Map<int, Company> companyMap) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          '근무 기록이 없습니다',
          style: GoogleFonts.notoSans(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final r = records[index];
        final company = companyMap[r.companyId];
        final companyName = company?.name ?? '알 수 없음';
        final duration = r.workDuration;
        final timeStr = '${DateFormat('HH:mm').format(r.checkIn!)} ~ ${DateFormat('HH:mm').format(r.checkOut!)}';
        final durationStr = duration.inHours > 0
            ? '${duration.inHours}시간${duration.inMinutes.remainder(60) > 0 ? ' ${duration.inMinutes.remainder(60)}분' : ''}'
            : '${duration.inMinutes}분';
        return GestureDetector(
          onTap: () => _showEditModal(context, r, companyMap),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      companyName,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      timeStr,
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        durationStr,
                        style: GoogleFonts.notoSans(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditModal(BuildContext context, WorkRecord record, Map<int, Company> companyMap) {
    final companies = companyMap.values.toList();
    int? selectedCompanyId = record.companyId;
    DateTime? checkInDateTime = record.checkIn != null 
        ? DateTime(
            record.date.year,
            record.date.month,
            record.date.day,
            record.checkIn!.hour,
            record.checkIn!.minute,
          )
        : null;
    DateTime? checkOutDateTime = record.checkOut != null
        ? DateTime(
            record.date.year,
            record.date.month,
            record.date.day,
            record.checkOut!.hour,
            record.checkOut!.minute,
          )
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '근무 기록 수정',
                    style: GoogleFonts.notoSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: selectedCompanyId,
                    decoration: const InputDecoration(
                      labelText: '회사',
                      border: OutlineInputBorder(),
                    ),
                    items: companies.map((company) {
                      return DropdownMenuItem(
                        value: company.id,
                        child: Text(company.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCompanyId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: checkInDateTime ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  checkInDateTime ?? DateTime.now(),
                                ),
                              );
                              if (time != null) {
                                setState(() {
                                  checkInDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Text(
                            checkInDateTime != null
                                ? '${DateFormat('yyyy-MM-dd HH:mm').format(checkInDateTime!)}'
                                : '체크인 날짜/시간 선택',
                            style: GoogleFonts.notoSans(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: checkOutDateTime ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  checkOutDateTime ?? DateTime.now(),
                                ),
                              );
                              if (time != null) {
                                setState(() {
                                  checkOutDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Text(
                            checkOutDateTime != null
                                ? '${DateFormat('yyyy-MM-dd HH:mm').format(checkOutDateTime!)}'
                                : '체크아웃 날짜/시간 선택',
                            style: GoogleFonts.notoSans(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedCompanyId != null && 
                          checkInDateTime != null && 
                          checkOutDateTime != null) {
                        final updatedRecord = WorkRecord(
                          id: record.id,
                          date: checkInDateTime!,
                          checkIn: checkInDateTime,
                          checkOut: checkOutDateTime,
                          companyId: selectedCompanyId!,
                          hourlyWage: record.hourlyWage,
                        );
                        
                        await DatabaseHelper().updateWorkRecord(updatedRecord);
                        if (mounted) {
                          setState(() {
                            _futureData = _loadMonthData(_focusedDay);
                          });
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '저장',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

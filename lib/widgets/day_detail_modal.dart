import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/work_schedule.dart';
import 'work_schedule_modal.dart';

class DayDetailModal extends StatefulWidget {
  final DateTime selectedDay;
  final Function(DateTime) onTodayPressed;

  const DayDetailModal({
    super.key,
    required this.selectedDay,
    required this.onTodayPressed,
  });

  @override
  State<DayDetailModal> createState() => _DayDetailModalState();
}

class _DayDetailModalState extends State<DayDetailModal> {
  late DateTime _currentDay;
  List<WorkSchedule> _schedules = []; // 임시 데이터

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
    // 임시 데이터 생성
    _schedules = [
      WorkSchedule(
        id: '1',
        companyId: 'default_company_id',
        startTime: DateTime(_currentDay.year, _currentDay.month, _currentDay.day, 9, 0),
        endTime: DateTime(_currentDay.year, _currentDay.month, _currentDay.day, 18, 0),
      ),
    ];
  }

  void _showWorkScheduleModal(BuildContext context, {WorkSchedule? schedule}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: WorkScheduleModal(
          schedule: schedule,
          isEdit: schedule != null,
          onSave: (updatedSchedule) {
            setState(() {
              if (schedule != null) {
                final index = _schedules.indexWhere((s) => s.id == schedule.id);
                if (index != -1) {
                  _schedules[index] = updatedSchedule;
                }
              } else {
                _schedules.add(updatedSchedule);
              }
            });
          },
          onDelete: schedule != null ? (id) {
            setState(() {
              _schedules.removeWhere((s) => s.id == id);
            });
          } : null,
        ),
      ),
    );
  }

  Widget _buildWorkScheduleItem(WorkSchedule schedule) {
    final hours = schedule.workingHours.inHours;
    final minutes = schedule.workingHours.inMinutes % 60;
    final timeText = minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';

    return GestureDetector(
      onTap: () => _showWorkScheduleModal(context, schedule: schedule),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text('회사'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${DateFormat('dd일 HH:mm').format(schedule.startTime)} ~ ${DateFormat('dd일 HH:mm').format(schedule.endTime)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            Text(
              timeText,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final today = DateTime.now();
    final koreanWeekday = ['월', '화', '수', '목', '금', '토', '일'][_currentDay.weekday - 1];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 날짜 표시
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              '${DateFormat('MM월 dd일').format(_currentDay)} $koreanWeekday요일',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // 근무표 영역
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: _schedules.map((schedule) => _buildWorkScheduleItem(schedule)).toList(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: IconButton(
                    onPressed: () => _showWorkScheduleModal(context),
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 30,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 하단 오늘 버튼 (오늘이 아닐 때만)
          if (!isSameDay(_currentDay, today))
            Container(
              margin: const EdgeInsets.only(top: 10),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _currentDay = today;
                  });
                },
                child: const Text(
                  '오늘',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 
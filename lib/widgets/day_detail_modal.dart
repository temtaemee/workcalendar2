import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/work_schedule.dart';
import '../repositories/work_schedule_repository.dart';
import '../repositories/company_repository.dart';
import 'work_schedule_modal.dart';

class DayDetailModal extends StatefulWidget {
  final DateTime selectedDay;
  final List<WorkSchedule> schedules;
  final Function(DateTime) onTodayPressed;
  final Function() onDataChanged;

  const DayDetailModal({
    super.key,
    required this.selectedDay,
    required this.schedules,
    required this.onTodayPressed,
    required this.onDataChanged,
  });

  @override
  State<DayDetailModal> createState() => _DayDetailModalState();
}

class _DayDetailModalState extends State<DayDetailModal> {
  final WorkScheduleRepository _workScheduleRepository = WorkScheduleRepository();
  final CompanyRepository _companyRepository = CompanyRepository();
  late DateTime _currentDay;
  List<WorkSchedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
    _schedules = widget.schedules;
  }

  Future<void> _refetchSchedules() async {
    final schedules = await _workScheduleRepository.getSchedulesByDay(_currentDay);
    if (mounted) {
      setState(() {
        _schedules = schedules;
      });
    }
  }

  void _showWorkScheduleModal(BuildContext context, {WorkSchedule? schedule}) async {
    final companies = await _companyRepository.getAllCompanies();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: WorkScheduleModal(
          schedule: schedule,
          isEdit: schedule != null,
          selectedDate: _currentDay,
          companies: companies,
          onSave: (updatedSchedule) async {
            if (schedule != null) {
              await _workScheduleRepository.updateWorkSchedule(updatedSchedule);
            } else {
              await _workScheduleRepository.addWorkSchedule(updatedSchedule);
            }
            await _refetchSchedules();
            widget.onDataChanged();
          },
          onDelete: schedule != null ? (id) async {
            await _workScheduleRepository.deleteWorkSchedule(id);
            await _refetchSchedules();
            widget.onDataChanged();
          } : null,
        ),
      ),
    );
  }

  Widget _buildWorkScheduleItem(WorkSchedule schedule) {
    final duration = schedule.workingHours;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final timeText = minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';

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
                color: schedule.company?.color.withOpacity(0.2) ?? Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                schedule.company?.name ?? '-',
                style: TextStyle(
                  color: schedule.company?.color ?? Colors.grey.shade800,
                  fontWeight: FontWeight.bold
                ),
              ),
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
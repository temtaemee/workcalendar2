import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/company.dart';
import '../models/work_schedule.dart';
import '../repositories/company_repository.dart';
import '../repositories/work_schedule_repository.dart';
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
  List<Company> _companies = [];

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
    _schedules = widget.schedules;
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final companies = await _companyRepository.getAllCompanies();
    if (mounted) {
      setState(() {
        _companies = companies;
      });
    }
  }

  Future<void> _refetchSchedules() async {
    final schedules = await _workScheduleRepository.getSchedulesByDay(_currentDay);
    if (mounted) {
      setState(() {
        _schedules = schedules;
      });
    }
  }

  void _showWorkScheduleModal(BuildContext context, {WorkSchedule? schedule}) {
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
          companies: _companies,
          isEdit: schedule != null,
          selectedDate: _currentDay,
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
    final hours = schedule.workingHours.inHours;
    final minutes = schedule.workingHours.inMinutes % 60;
    final timeText = minutes > 0 ? '$hours시간 $minutes분' : '$hours시간';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Slidable(
          key: ValueKey(schedule.id),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.3,
            children: [
              CustomSlidableAction(
                onPressed: (context) async {
                  final bool? confirmed = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text('삭제 확인'),
                        content: const Text('정말로 이 근무 기록을 삭제하시겠습니까?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('삭제', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirmed == true) {
                    await _workScheduleRepository.deleteWorkSchedule(schedule.id!);
                    await _refetchSchedules();
                    widget.onDataChanged();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('근무 기록이 삭제되었습니다.')),
                      );
                    }
                  }
                },
                child: Container(
                  color: Colors.red,
                  child: const Center(
                    child: Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => _showWorkScheduleModal(context, schedule: schedule),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
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
                      schedule.company?.name ?? '회사 없음',
                      style: TextStyle(
                        color: schedule.company?.color ?? Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${DateFormat('HH:mm').format(schedule.startTime)} ~ ${DateFormat('HH:mm').format(schedule.endTime)}',
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
          ),
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 날짜 표시
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                '${DateFormat('MM월 dd일').format(_currentDay)} $koreanWeekday요일',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // 근무표 영역
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: _schedules.map((schedule) => _buildWorkScheduleItem(schedule)).toList(),
              ),
            ),
            // 추가 버튼
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              child: IconButton(
                onPressed: () => _showWorkScheduleModal(context),
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 30,
                color: Colors.grey[600],
              ),
            ),
            // 하단 오늘 버튼
            if (!isSameDay(_currentDay, today))
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _currentDay = today;
                    });
                    _refetchSchedules();
                  },
                  child: const Text(
                    '오늘',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 
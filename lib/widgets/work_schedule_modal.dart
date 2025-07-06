import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/work_schedule.dart';
import '../models/company.dart';

class WorkScheduleModal extends StatefulWidget {
  final WorkSchedule? schedule;
  final bool isEdit;
  final Function(WorkSchedule) onSave;
  final Function(int)? onDelete;
  final DateTime selectedDate;
  final List<Company> companies;

  const WorkScheduleModal({
    super.key,
    this.schedule,
    required this.isEdit,
    required this.onSave,
    this.onDelete,
    required this.selectedDate,
    required this.companies,
  });

  @override
  State<WorkScheduleModal> createState() => _WorkScheduleModalState();
}

class _WorkScheduleModalState extends State<WorkScheduleModal> {
  late int _selectedCompanyId;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late DateTime _selectedDate;
  bool _autoExcludeLunch = true;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.schedule?.companyId ?? 0;
    
    _startTime = widget.schedule?.startTime != null
        ? TimeOfDay.fromDateTime(widget.schedule!.startTime)
        : const TimeOfDay(hour: 9, minute: 0);
    
    _endTime = widget.schedule?.endTime != null
        ? TimeOfDay.fromDateTime(widget.schedule!.endTime)
        : const TimeOfDay(hour: 18, minute: 0);

    _selectedDate = widget.isEdit 
        ? DateTime(widget.schedule!.startTime.year, widget.schedule!.startTime.month, widget.schedule!.startTime.day) 
        : widget.selectedDate;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hour <= 12 ? time.hour : time.hour - 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour.toString().padLeft(2, '0')}:$minute';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          height: 280,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black12,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final time = isStart ? _startTime : _endTime;
                        Navigator.pop(context, time);
                      },
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: false,
                  minuteInterval: 1,
                  backgroundColor: Colors.white,
                  initialDateTime: DateTime(
                    2024, 1, 1,
                    isStart ? _startTime.hour : _endTime.hour,
                    isStart ? _startTime.minute : _endTime.minute,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      final newTime = TimeOfDay(
                        hour: newDateTime.hour,
                        minute: newDateTime.minute,
                      );
                      if (isStart) {
                        _startTime = newTime;
                      } else {
                        _endTime = newTime;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSave() {
    final companyMatches = widget.companies.where((c) => c.id == _selectedCompanyId);
    final Company? selectedCompany = companyMatches.isNotEmpty ? companyMatches.first : null;

    final startDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final endDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);

    bool shouldSplit = _autoExcludeLunch &&
        selectedCompany != null &&
        selectedCompany.lunchStartTime != null &&
        selectedCompany.lunchEndTime != null;

    if (shouldSplit) {
      final lunchStart = selectedCompany.lunchStartTime!;
      final lunchEnd = selectedCompany.lunchEndTime!;
      final lunchStartDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, lunchStart.hour, lunchStart.minute);
      final lunchEndDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, lunchEnd.hour, lunchEnd.minute);

      if (startDateTime.isBefore(lunchStartDateTime) && endDateTime.isAfter(lunchEndDateTime)) {
        // 근무 기록 1: 근무 시작 ~ 점심 시작
        final schedule1 = WorkSchedule(
          id: widget.schedule?.id, // 수정 모드일 경우 기존 ID 유지
          companyId: _selectedCompanyId,
          startTime: startDateTime,
          endTime: lunchStartDateTime,
          regDate: widget.schedule?.regDate ?? DateTime.now(),
          uptDate: DateTime.now(),
        );
        widget.onSave(schedule1);

        // 근무 기록 2: 점심 종료 ~ 근무 종료
        final schedule2 = WorkSchedule(
          companyId: _selectedCompanyId,
          startTime: lunchEndDateTime,
          endTime: endDateTime,
          regDate: DateTime.now(),
          uptDate: DateTime.now(),
        );
        widget.onSave(schedule2);

        Navigator.pop(context);
        return;
      }
    }

    // 분할하지 않는 경우
    final schedule = WorkSchedule(
      id: widget.schedule?.id,
      companyId: _selectedCompanyId == 0 ? null : _selectedCompanyId,
      startTime: startDateTime,
      endTime: endDateTime,
      regDate: widget.schedule?.regDate ?? DateTime.now(),
      uptDate: DateTime.now(),
    );
    widget.onSave(schedule);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 선택
                    if (widget.isEdit) ...[
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              const Icon(Icons.calendar_today, color: Colors.black54, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 회사 선택
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _selectedCompanyId,
                        decoration: const InputDecoration(
                          labelText: '회사',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                        dropdownColor: Colors.white,
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('없음', style: TextStyle(color: Colors.black87)),
                          ),
                          ...widget.companies.map((company) {
                            return DropdownMenuItem<int>(
                              value: company.id!,
                              child: Row(
                                children: [
                                  CircleAvatar(backgroundColor: company.color, radius: 6),
                                  const SizedBox(width: 8),
                                  Text(company.name, style: const TextStyle(color: Colors.black87)),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCompanyId = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 점심시간 제외 체크박스
                    if (widget.companies.any((c) => c.id == _selectedCompanyId && c.lunchStartTime != null))
                      CheckboxListTile(
                        title: const Text("점심시간 자동 제외"),
                        value: _autoExcludeLunch,
                        onChanged: (newValue) {
                          setState(() {
                            _autoExcludeLunch = newValue!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    // 시간 선택
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => _selectTime(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.transparent,
                              ),
                              child: Text(_formatTimeOfDay(_startTime)),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('~', style: TextStyle(color: Colors.black54)),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () => _selectTime(false),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.transparent,
                              ),
                              child: Text(_formatTimeOfDay(_endTime)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 저장 버튼
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton(
                        onPressed: _handleSave,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.grey[50],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isEdit ? '수정하기' : '추가하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (widget.isEdit && widget.onDelete != null) ...[
                      const SizedBox(height: 8),
                      // 삭제 버튼
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextButton(
                          onPressed: () {
                            if (widget.schedule?.id != null) {
                              widget.onDelete!(widget.schedule!.id!);
                              Navigator.pop(context);
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '삭제하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
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
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  bool _autoExcludeLunch = true;
  Company? _selectedCompany;
  bool _timeManuallyChanged = false;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.schedule?.companyId ?? 0;
    try {
      _selectedCompany = widget.companies.firstWhere((c) => c.id == _selectedCompanyId);
    } catch (e) {
      _selectedCompany = null;
    }

    if (widget.isEdit && widget.schedule != null) {
      _startDateTime = widget.schedule!.startTime;
      _endDateTime = widget.schedule!.endTime;
      _timeManuallyChanged = true;
    } else {
      final date = widget.selectedDate;
      _startDateTime = DateTime(date.year, date.month, date.day, 9, 0);
      _endDateTime = DateTime(date.year, date.month, date.day, 18, 0);
      _timeManuallyChanged = false;
    }
  }

  void _updateTimesForCompany(Company? company) {
    final date = _startDateTime; // Use the current start date as the base
    if (company != null) {
      setState(() {
        _startDateTime = DateTime(date.year, date.month, date.day, company.startTime.hour, company.startTime.minute);
        _endDateTime = DateTime(date.year, date.month, date.day, company.endTime.hour, company.endTime.minute);
      });
    } else { // '회사 없음'
      setState(() {
        _startDateTime = DateTime(date.year, date.month, date.day, 9, 0);
        _endDateTime = DateTime(date.year, date.month, date.day, 18, 0);
      });
    }
  }

  String _formatTimeOfDay(DateTime dt) {
    final time = TimeOfDay.fromDateTime(dt);
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour.toString().padLeft(2, '0')}:$minute';
  }

  Future<void> _selectTime(bool isStart) async {
    DateTime tempDateTime = isStart ? _startDateTime : _endDateTime;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: 280,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소', style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: tempDateTime,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(primary: Colors.black),
                                    dialogBackgroundColor: Colors.white,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() {
                                tempDateTime = DateTime(
                                  picked.year, picked.month, picked.day,
                                  tempDateTime.hour, tempDateTime.minute,
                                );
                              });
                            }
                          },
                          child: Text(
                            DateFormat('MM월 dd일 (E)', 'ko_KR').format(tempDateTime),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (isStart) {
                                _startDateTime = tempDateTime;
                              } else {
                                _endDateTime = tempDateTime;
                              }
                              _timeManuallyChanged = true;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('완료', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: false,
                      minuteInterval: 5,
                      backgroundColor: Colors.white,
                      initialDateTime: tempDateTime,
                      onDateTimeChanged: (DateTime newDateTime) {
                        tempDateTime = DateTime(
                          tempDateTime.year, tempDateTime.month, tempDateTime.day,
                          newDateTime.hour, newDateTime.minute,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleSave() {
    if (_endDateTime.isBefore(_startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 합니다.'), backgroundColor: Colors.red),
      );
      return;
    }

    bool shouldSplit = _autoExcludeLunch && _selectedCompany != null && _selectedCompany!.lunchStartTime != null && _selectedCompany!.lunchEndTime != null;

    if (shouldSplit) {
      final lunchStart = _selectedCompany!.lunchStartTime!;
      final lunchEnd = _selectedCompany!.lunchEndTime!;
      DateTime lunchStartDateTime = DateTime(_startDateTime.year, _startDateTime.month, _startDateTime.day, lunchStart.hour, lunchStart.minute);
      DateTime lunchEndDateTime = DateTime(_startDateTime.year, _startDateTime.month, _startDateTime.day, lunchEnd.hour, lunchEnd.minute);

      if (lunchStartDateTime.isBefore(_startDateTime)) {
        lunchStartDateTime = lunchStartDateTime.add(const Duration(days: 1));
        lunchEndDateTime = lunchEndDateTime.add(const Duration(days:1));
      }

      if (_startDateTime.isBefore(lunchStartDateTime) && _endDateTime.isAfter(lunchEndDateTime)) {
        final schedule1 = WorkSchedule(
          id: widget.schedule?.id,
          companyId: _selectedCompanyId,
          startTime: _startDateTime,
          endTime: lunchStartDateTime,
          regDate: widget.schedule?.regDate ?? DateTime.now(),
          uptDate: DateTime.now(),
        );
        widget.onSave(schedule1);

        final schedule2 = WorkSchedule(
          companyId: _selectedCompanyId,
          startTime: lunchEndDateTime,
          endTime: _endDateTime,
          regDate: DateTime.now(),
          uptDate: DateTime.now(),
        );
        widget.onSave(schedule2);
        Navigator.pop(context);
        return;
      }
    }

    final schedule = WorkSchedule(
      id: widget.schedule?.id,
      companyId: _selectedCompanyId <= 0 ? null : _selectedCompanyId,
      startTime: _startDateTime,
      endTime: _endDateTime,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.isEdit ? '근무 수정' : '근무 추가',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 1. 회사 선택 (순서만 위로, 필수는 아님)
                DropdownButtonFormField<int>(
                  value: _selectedCompanyId <= 0 ? 0 : _selectedCompanyId,
                  items: [
                    const DropdownMenuItem<int>(value: 0, child: Text('회사 없음')),
                    ...widget.companies.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCompanyId = value ?? 0;
                      try {
                        _selectedCompany = widget.companies.firstWhere((c) => c.id == _selectedCompanyId);
                      } catch (e) {
                        _selectedCompany = null;
                      }
                      
                      if (!_timeManuallyChanged) {
                        _updateTimesForCompany(_selectedCompany);
                      }
                    });
                  },
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: '회사',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. 시간 선택
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => _selectTime(true), child: Text(_formatTimeOfDay(_startDateTime), style: const TextStyle(fontSize: 20, color: Colors.black)))),
                      const Text('~', style: TextStyle(fontSize: 20, color: Colors.grey)),
                      Expanded(child: TextButton(onPressed: () => _selectTime(false), child: Text(_formatTimeOfDay(_endDateTime), style: const TextStyle(fontSize: 20, color: Colors.black)))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // 3. 점심시간 (조건부 표시)
                if (_selectedCompany != null && _selectedCompany!.lunchStartTime != null)
                  CheckboxListTile(
                    value: _autoExcludeLunch,
                    onChanged: (v) => setState(() => _autoExcludeLunch = v ?? true),
                    title: const Text('점심시간 자동 제외'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                const SizedBox(height: 16),

                // 4. 저장/삭제 버튼
                Row(
                  children: [
                    if (widget.isEdit && widget.onDelete != null)
                      TextButton(onPressed: () { widget.onDelete!(widget.schedule!.id!); Navigator.pop(context); }, child: const Text('삭제', style: TextStyle(color: Colors.red))),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/work_schedule.dart';

class WorkScheduleModal extends StatefulWidget {
  final WorkSchedule? schedule;
  final bool isEdit;
  final Function(WorkSchedule) onSave;
  final Function(String)? onDelete;

  const WorkScheduleModal({
    super.key,
    this.schedule,
    required this.isEdit,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<WorkScheduleModal> createState() => _WorkScheduleModalState();
}

class _WorkScheduleModalState extends State<WorkScheduleModal> {
  late String _selectedCompanyId;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _selectedCompanyId = widget.schedule?.companyId ?? 'default_company_id';
    
    final now = DateTime.now();
    _startTime = widget.schedule?.startTime != null
        ? TimeOfDay.fromDateTime(widget.schedule!.startTime)
        : TimeOfDay(hour: now.hour, minute: now.minute);
    
    final endTime = now.add(const Duration(hours: 9));
    _endTime = widget.schedule?.endTime != null
        ? TimeOfDay.fromDateTime(widget.schedule!.endTime)
        : TimeOfDay(hour: endTime.hour, minute: endTime.minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hour <= 12 ? time.hour : time.hour - 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour.toString().padLeft(2, '0')}:$minute';
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
    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _endTime.hour,
      _endTime.minute,
    );

    final schedule = WorkSchedule(
      id: widget.schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      companyId: _selectedCompanyId,
      startTime: startDateTime,
      endTime: endDateTime,
    );

    widget.onSave(schedule);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                // 회사 선택
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonFormField<String>(
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
                      DropdownMenuItem(
                        value: 'default_company_id',
                        child: Text('기본 회사', style: TextStyle(color: Colors.black87)), // 임시 데이터
                      ),
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
                          widget.onDelete!(widget.schedule!.id);
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
    );
  }
} 
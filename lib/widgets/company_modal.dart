import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:workcalendar2/models/company.dart';

class CompanyModal extends StatefulWidget {
  final Function(Company) onSave;
  final Company? company;

  const CompanyModal({
    super.key,
    required this.onSave,
    this.company,
  });

  @override
  State<CompanyModal> createState() => _CompanyModalState();
}

class _CompanyModalState extends State<CompanyModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  List<bool> _workingDays = [false, true, true, true, true, true, false]; // 기본값 월~금
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  PaymentType? _paymentType;
  final _paymentController = TextEditingController();
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 13, minute: 0);
  bool _useLunchTime = true;
  bool get _isEdit => widget.company != null;
  Color _selectedColor = Colors.blue; // 기본 색상

  final List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final company = widget.company!;
      _nameController.text = company.name;
      _workingDays = company.workingDays;
      _startTime = company.startTime;
      _endTime = company.endTime;
      _paymentType = company.paymentType;
      if (company.paymentAmount != null) {
        _paymentController.text = company.paymentAmount.toString();
      }
      if (company.lunchStartTime != null && company.lunchEndTime != null) {
        _useLunchTime = true;
        _lunchStartTime = company.lunchStartTime!;
        _lunchEndTime = company.lunchEndTime!;
      } else {
        _useLunchTime = false;
      }
      _selectedColor = company.color;
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('색상 선택'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(bool isStart, bool isLunch) async {
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
                        final time = isLunch
                            ? (isStart ? _lunchStartTime : _lunchEndTime)
                            : (isStart ? _startTime : _endTime);
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
                  minuteInterval: 5,
                  backgroundColor: Colors.white,
                  initialDateTime: DateTime(
                    2024, 1, 1,
                    isLunch
                        ? (isStart ? _lunchStartTime.hour : _lunchEndTime.hour)
                        : (isStart ? _startTime.hour : _endTime.hour),
                    isLunch
                        ? (isStart ? _lunchStartTime.minute : _lunchEndTime.minute)
                        : (isStart ? _startTime.minute : _endTime.minute),
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      final newTime = TimeOfDay(
                        hour: newDateTime.hour,
                        minute: newDateTime.minute,
                      );
                      if (isLunch) {
                        if (isStart) {
                          _lunchStartTime = newTime;
                        } else {
                          _lunchEndTime = newTime;
                        }
                      } else {
                        if (isStart) {
                          _startTime = newTime;
                        } else {
                          _endTime = newTime;
                        }
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

  String _formatTimeOfDay(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hour <= 12 ? time.hour : time.hour - 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour.toString().padLeft(2, '0')}:$minute';
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final company = Company(
        id: widget.company?.id,
        name: _nameController.text,
        color: _selectedColor,
        regDate: widget.company?.regDate ?? now,
        uptDate: now,
        workingDays: _workingDays,
        startTime: _startTime,
        endTime: _endTime,
        paymentType: _paymentType,
        paymentAmount: _paymentController.text.isNotEmpty
            ? int.parse(_paymentController.text)
            : null,
        lunchStartTime: _useLunchTime ? _lunchStartTime : null,
        lunchEndTime: _useLunchTime ? _lunchEndTime : null,
      );
      widget.onSave(company);
      Navigator.pop(context);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '(선택)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black38
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEdit ? '회사 수정' : '회사 추가',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('기본 정보'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '회사명',
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black26),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '회사명을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Row(
                    children: [
                      const Text(
                        '회사 색상',
                        style: TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        backgroundColor: _selectedColor,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _buildSectionTitle('근무 요일'),
                const SizedBox(height: 12),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _workingDays[index] = !_workingDays[index];
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _workingDays[index] 
                              ? Colors.black87 
                              : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              _weekdays[index],
                              style: TextStyle(
                                color: _workingDays[index] 
                                  ? Colors.white 
                                  : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('근무 시간', 
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87
                  )
                ),
                const SizedBox(height: 12),
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
                          onPressed: () => _selectTime(true, false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                          onPressed: () => _selectTime(false, false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(_formatTimeOfDay(_endTime)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Text('급여 정보', 
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87
                      )
                    ),
                    SizedBox(width: 4),
                    Text('(선택)', 
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black38
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            canvasColor: Colors.white,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<PaymentType>(
                              value: _paymentType,
                              hint: const Text('급여 유형',
                                style: TextStyle(color: Colors.black54)),
                              items: PaymentType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.label),
                                );
                              }).toList(),
                              onChanged: (PaymentType? value) {
                                setState(() {
                                  _paymentType = value;
                                });
                              },
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _paymentController,
                        decoration: InputDecoration(
                          labelText: '금액',
                          labelStyle: const TextStyle(color: Colors.black54),
                          suffixText: '원',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black26),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('점심 시간', 
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87
                      )
                    ),
                    Switch.adaptive(
                      value: _useLunchTime,
                      onChanged: (bool value) {
                        setState(() {
                          _useLunchTime = value;
                        });
                      },
                      activeColor: Colors.black87,
                    ),
                  ],
                ),
                if (_useLunchTime) ...[
                  const SizedBox(height: 12),
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
                            onPressed: () => _selectTime(true, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(_formatTimeOfDay(_lunchStartTime)),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('~', style: TextStyle(color: Colors.black54)),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => _selectTime(false, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(_formatTimeOfDay(_lunchEndTime)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
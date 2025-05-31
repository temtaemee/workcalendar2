import 'package:flutter/material.dart';
import '../models/company.dart';

class AddCompanyScreen extends StatefulWidget {
  const AddCompanyScreen({super.key});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hourlyWageController = TextEditingController();
  
  List<bool> _workDays = [true, true, true, true, true, false, false]; // 월~금 기본 선택
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _excludeLunchTime = true;
  TimeOfDay _lunchStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lunchEndTime = const TimeOfDay(hour: 13, minute: 0);

  final List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void dispose() {
    _nameController.dispose();
    _hourlyWageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectLunchTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _lunchStartTime : _lunchEndTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _lunchStartTime = picked;
        } else {
          _lunchEndTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회사 추가'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '회사명',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '회사명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              const Text('근무 요일', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  return FilterChip(
                    label: Text(_weekdays[index]),
                    selected: _workDays[index],
                    onSelected: (bool selected) {
                      setState(() {
                        _workDays[index] = selected;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              
              const Text('근무 시간', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(context, true),
                      child: Text('시작: ${_startTime.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectTime(context, false),
                      child: Text('종료: ${_endTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              SwitchListTile(
                title: const Text('점심시간 제외'),
                value: _excludeLunchTime,
                onChanged: (bool value) {
                  setState(() {
                    _excludeLunchTime = value;
                  });
                },
              ),
              if (_excludeLunchTime) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selectLunchTime(context, true),
                        child: Text('시작: ${_lunchStartTime.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selectLunchTime(context, false),
                        child: Text('종료: ${_lunchEndTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _hourlyWageController,
                decoration: const InputDecoration(
                  labelText: '시급',
                  border: OutlineInputBorder(),
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '시급을 입력해주세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final company = Company(
                        name: _nameController.text,
                        workDays: _workDays,
                        startTime: _startTime,
                        endTime: _endTime,
                        excludeLunchTime: _excludeLunchTime,
                        lunchStartTime: _excludeLunchTime ? _lunchStartTime : null,
                        lunchEndTime: _excludeLunchTime ? _lunchEndTime : null,
                        hourlyWage: double.parse(_hourlyWageController.text),
                      );
                      Navigator.pop(context, company);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '회사 추가하기',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
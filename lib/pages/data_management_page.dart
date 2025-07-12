import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/company.dart';
import '../repositories/company_repository.dart';
import '../repositories/work_schedule_repository.dart';

class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  final CompanyRepository _companyRepository = CompanyRepository();
  final WorkScheduleRepository _workScheduleRepository = WorkScheduleRepository();

  List<Company> _companies = [];
  int? _selectedCompanyId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    final companies = await _companyRepository.getAllCompanies();
    if (mounted) {
      setState(() {
        _companies = companies;
        if (_companies.isNotEmpty) {
          _selectedCompanyId = _companies.first.id;
        }
      });
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
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
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _runUpdate() async {
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('적용할 회사를 선택해주세요.')),
      );
      return;
    }
    
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('근무 기록 업데이트'),
        content: Text(
          '${DateFormat('yyyy/MM/dd').format(_startDate)} ~ ${DateFormat('yyyy/MM/dd').format(_endDate)} 기간의 \'회사 없음\' 기록을 모두 선택된 회사로 변경합니다. 이 작업은 되돌릴 수 없습니다. 정말 실행하시겠습니까?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('업데이트', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() { _isLoading = true; });
      final count = await _workScheduleRepository.updateCompanyForSchedulesInRange(
        _selectedCompanyId!,
        _startDate,
        _endDate,
      );
      setState(() { _isLoading = false; });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count개의 근무 기록이 업데이트되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('데이터 관리')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. 기간 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                  ),
                  child: Text(DateFormat('yyyy/MM/dd').format(_startDate)),
                ),
                const Text('~'),
                ElevatedButton(
                  onPressed: () => _selectDate(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                  ),
                  child: Text(DateFormat('yyyy/MM/dd').format(_endDate)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('2. 회사 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_companies.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedCompanyId,
                items: _companies.map((company) {
                  return DropdownMenuItem<int>(value: company.id, child: Text(company.name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCompanyId = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              )
            else
              const Text('먼저 회사를 추가해주세요.'),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('업데이트 실행'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
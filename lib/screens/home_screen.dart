import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/work_provider.dart';
import '../models/company.dart';
import 'add_company_screen.dart';
import 'package:work_calendar_app/screens/add_company_screen.dart';
import 'package:work_calendar_app/providers/work_provider.dart';
import 'package:work_calendar_app/models/company.dart';
import 'dart:ui';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WorkProvider>(
        builder: (context, provider, child) {
          // 로딩 중이거나 아직 회사를 불러오지 못한 경우
          if (provider.companies.isEmpty && !provider.hasAttemptedLoad) { // 로드 시도 여부 플래그 추가 가정
            // provider.loadCompanies(); // 여기서 호출하거나 initSate에서 호출
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '등록된 회사가 없습니다',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddCompanyScreen(context),
                    child: const Text('회사 추가하기'),
                  ),
                ],
              ),
            );
          }
          
          // 회사 목록이 있을 경우 UI
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 회사 선택 드롭다운
                DropdownButtonFormField<Company>(
                  decoration: const InputDecoration(
                    labelText: '회사 선택',
                    border: OutlineInputBorder(),
                  ),
                  value: provider.selectedCompany, // provider.selectedCompany가 null일 수 있음
                  hint: const Text("회사를 선택해주세요"), // selectedCompany가 null일 때 표시될 텍스트
                  isExpanded: true, // 드롭다운이 전체 너비를 차지하도록
                  items: provider.companies.map((company) {
                    return DropdownMenuItem<Company>(
                      value: company, // Company 객체 전체를 value로 사용
                      child: Text(company.name),
                    );
                  }).toList(),
                  onChanged: (Company? newValue) {
                    if (newValue != null) {
                      provider.setSelectedCompany(newValue);
                    }
                  },
                  validator: (value) => value == null ? '회사를 선택해주세요.' : null,
                ),
                const SizedBox(height: 20),

                // 선택된 회사 정보 및 출퇴근 UI (기존 UI를 여기에 통합)
                if (provider.selectedCompany != null) ...[
                  Text(
                    '선택된 회사: ${provider.selectedCompany!.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('ID: ${provider.selectedCompany!.id}'),
                  const SizedBox(height: 20),
                  
                  // 출근/퇴근 버튼 로직 (기존 홈스크린의 로직을 가져와야 함)
                  if (provider.isCheckedIn) ...[
                    Text('출근 시간: ${TimeOfDay.fromDateTime(provider.checkInDateTime!).format(context)}'),
                    Text('현재 근무 시간: ${_formatDuration(provider.currentWorkDuration)}'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        provider.checkOut();
                        // 출퇴근 기록 저장 로직 (필요시 WorkProvider 또는 여기서 호출)
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text('퇴근'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () {
                        provider.checkIn();
                      },
                      child: const Text('출근'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // 추가적인 정보 표시 (예: 오늘 근무 기록, 총 근무 시간 등)
                  // 이 부분은 기존 HomeScreen의 다른 UI 요소들을 참고하여 구성합니다.
                  
                ] else ...[
                  const Center(child: Text('회사를 선택하면 출퇴근 기능을 사용할 수 있습니다.')),
                ],
                
                // 기타 UI 요소들 (예: 근무 통계 보기 버튼 등)
                const Spacer(), // 남은 공간을 채움
                ElevatedButton(
                    onPressed: () {
                    // 근무 기록 화면으로 이동하는 로직 등
                    },
                    child: const Text('근무 기록 보기'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCompanyScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCompanyScreen(BuildContext context) async {
    final workProvider = Provider.of<WorkProvider>(context, listen: false);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCompanyScreen()),
    );
    if (result != null && result is Company) {
      // workProvider.addCompany(result); // 기존 로직, WorkProvider에서 DB 저장을 안하므로 주석 처리 또는 삭제
      await workProvider.loadCompanies(); // 회사 추가 후 목록 새로고침
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }
} 
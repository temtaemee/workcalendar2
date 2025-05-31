import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/work_provider.dart';
import '../models/company.dart';
import 'add_company_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WorkProvider>(
        builder: (context, provider, child) {
          if (!provider.hasCompanies) {
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

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 날짜 표시
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(DateTime.now()),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 회사 선택 및 기간 선택
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Company>(
                              value: provider.selectedCompany,
                              items: provider.companies.map((Company company) {
                                return DropdownMenuItem<Company>(
                                  value: company,
                                  child: Text(company.name),
                                );
                              }).toList(),
                              onChanged: (Company? newValue) {
                                if (newValue != null) {
                                  provider.setSelectedCompany(newValue);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddCompanyScreen(context),
                        icon: const Icon(Icons.add),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: provider.selectedPeriod,
                            items: provider.periods.map((String period) {
                              return DropdownMenuItem<String>(
                                value: period,
                                child: Text(period),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                provider.setSelectedPeriod(newValue);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 근무 통계
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${provider.getPeriodLabel()} 근무 통계',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('근무 시간'),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDuration(provider.getWorkDuration()),
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${provider.getPeriodLabel()} 급여'),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${NumberFormat('#,###').format(provider.getWage().round())}원',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // 출퇴근 정보 및 버튼
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (provider.checkInDateTime != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '오늘의 근무 정보',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('출근 시간'),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDateTime(provider.checkInDateTime!),
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontFeatures: [
                                                const FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.grey.shade300,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('현재 근무 시간'),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDuration(provider.currentWorkDuration),
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: Theme.of(context).primaryColor,
                                              fontFeatures: [
                                                const FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          if (provider.isCheckedIn) {
                            provider.checkOut();
                          } else {
                            provider.checkIn();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: provider.isCheckedIn 
                              ? Colors.red.shade400
                              : Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          provider.isCheckedIn ? '퇴근하기' : '출근하기',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddCompanyScreen(BuildContext context) async {
    final result = await Navigator.push<Company>(
      context,
      MaterialPageRoute(builder: (context) => const AddCompanyScreen()),
    );
    
    if (result != null) {
      if (!context.mounted) return;
      context.read<WorkProvider>().addCompany(result);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$hours시간 $minutes분 $seconds초';
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }
} 
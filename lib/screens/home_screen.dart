import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/work_provider.dart';
import '../models/company.dart';
import 'add_company_screen.dart';
import 'package:work_calendar_app/screens/add_company_screen.dart';
import 'package:work_calendar_app/providers/work_provider.dart';
import 'package:work_calendar_app/models/company.dart';
import 'dart:ui';
import '../database_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime nowUtc = DateTime.now().toUtc();
    DateTime kst = nowUtc.add(const Duration(hours: 9));
    final today = DateTime(kst.year, kst.month, kst.day);
    print('nowUtc: $nowUtc');
    print('kst: $kst');
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Consumer<WorkProvider>(
          builder: (context, provider, child) {
            if (provider.companies.isEmpty && !provider.hasAttemptedLoad) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.companies.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '등록된 회사가 없습니다',
                      style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showAddCompanyScreen(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        textStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text('회사 추가하기'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<Company>(
                          decoration: InputDecoration(
                            labelText: '회사 선택',
                            labelStyle: GoogleFonts.notoSans(fontWeight: FontWeight.w500),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                          value: provider.selectedCompany,
                          hint: Text("회사를 선택해주세요", style: GoogleFonts.notoSans()),
                          isExpanded: true,
                          items: provider.companies.map((company) {
                            return DropdownMenuItem<Company>(
                              value: company,
                              child: Text(company.name, style: GoogleFonts.notoSans(fontWeight: FontWeight.w500)),
                            );
                          }).toList(),
                          onChanged: (Company? newValue) {
                            if (newValue != null) {
                              provider.setSelectedCompany(newValue);
                            }
                          },
                          validator: (value) => value == null ? '회사를 선택해주세요.' : null,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('yyyy년 M월 d일 (E)', 'ko').format(kst),
                                style: GoogleFonts.notoSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (provider.selectedCompany != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                provider.selectedCompany!.name,
                                style: GoogleFonts.notoSans(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: provider.isCheckedIn ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  provider.isCheckedIn ? '근무 중' : '퇴근',
                                  style: GoogleFonts.notoSans(
                                    color: provider.isCheckedIn ? Colors.green[800] : Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                provider.isCheckedIn
                                  ? '출근: ${DateFormat('HH:mm').format(provider.checkInDateTime!)}'
                                  : '출근 전',
                                style: GoogleFonts.notoSans(fontSize: 15, color: Colors.black87),
                              ),
                              const SizedBox(width: 16),
                              if (provider.isCheckedIn)
                                Text(
                                  '근무: ${_formatDuration(provider.currentWorkDuration)}',
                                  style: GoogleFonts.notoSans(fontSize: 15, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: provider.isCheckedIn
                                    ? () { provider.checkOut(); }
                                    : () { provider.checkIn(); },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: provider.isCheckedIn ? Colors.redAccent : Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    textStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  child: Text(provider.isCheckedIn ? '퇴근' : '출근'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              '회사를 선택하면 출퇴근 기능을 사용할 수 있습니다.',
                              style: GoogleFonts.notoSans(color: Colors.grey[600], fontSize: 15),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 근무 통계/급여 통계 영역 (사진 스타일)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Consumer<WorkProvider>(
                              builder: (context, provider, _) => ToggleButtons(
                                isSelected: [provider.selectedPeriod == '일간', provider.selectedPeriod == '주간', provider.selectedPeriod == '월간'],
                                onPressed: (index) {
                                  final period = ['일간', '주간', '월간'][index];
                                  provider.setSelectedPeriod(period);
                                },
                                borderRadius: BorderRadius.circular(20),
                                selectedColor: Colors.white,
                                fillColor: Colors.blueAccent,
                                color: Colors.blueAccent,
                                constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
                                children: [
                                  Text('일', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                                  Text('주', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                                  Text('월', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Consumer<WorkProvider>(
                          builder: (context, provider, _) {
                            final companies = provider.companies;
                            if (companies.isEmpty) {
                              return Center(child: Text('등록된 회사가 없습니다', style: GoogleFonts.notoSans(fontSize: 16, color: Colors.grey[600])));
                            }
                            return FutureBuilder<List>(
                              future: DatabaseHelper().getWorkRecords(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return SizedBox();
                                final records = snapshot.data!;
                                final now = DateTime.now();
                                DateTime startDate, endDate;
                                String periodLabel;
                                switch (provider.selectedPeriod) {
                                  case '일간':
                                    startDate = DateTime(now.year, now.month, now.day);
                                    endDate = startDate.add(const Duration(days: 1));
                                    periodLabel = '오늘';
                                    break;
                                  case '주간':
                                    startDate = now.subtract(Duration(days: now.weekday - 1));
                                    endDate = startDate.add(const Duration(days: 7));
                                    periodLabel = '이번 주';
                                    break;
                                  case '월간':
                                    startDate = DateTime(now.year, now.month, 1);
                                    endDate = DateTime(now.year, now.month + 1, 1);
                                    periodLabel = '이번 달';
                                    break;
                                  default:
                                    startDate = now;
                                    endDate = now;
                                    periodLabel = '';
                                }
                                // 기간 내 전체/회사별 집계
                                final periodRecords = records.where((r) => r.date.isAfter(startDate.subtract(const Duration(seconds: 1))) && r.date.isBefore(endDate)).toList();
                                final totalDuration = periodRecords.fold<Duration>(Duration.zero, (prev, r) => prev + r.workDuration);
                                final totalWage = periodRecords.fold<double>(0.0, (prev, r) => prev + r.dailyWage);
                                String twoDigits(int n) => n.toString().padLeft(2, '0');
                                final hh = twoDigits(totalDuration.inHours);
                                final mm = twoDigits(totalDuration.inMinutes.remainder(60));
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 근무 통계 제목과 총 근무시간 한 줄
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('$periodLabel 근무 통계', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('총 $hh시간 $mm분', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 15)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ...companies.map((company) {
                                      final companyRecords = periodRecords.where((r) => r.companyId == company.id).toList();
                                      final cDuration = companyRecords.fold<Duration>(Duration.zero, (prev, r) => prev + r.workDuration);
                                      final chh = twoDigits(cDuration.inHours);
                                      final cmm = twoDigits(cDuration.inMinutes.remainder(60));
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(company.name, style: GoogleFonts.notoSans(fontSize: 15)),
                                            Text('$chh시간 $cmm분 근무', style: GoogleFonts.notoSans(fontSize: 15)),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 16),
                                    // 주급 계산 제목과 총 금액 한 줄
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('$periodLabel 급 계산', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('총 ${totalWage.toStringAsFixed(0)}원', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600, fontSize: 15)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ...companies.map((company) {
                                      final companyRecords = periodRecords.where((r) => r.companyId == company.id).toList();
                                      final cWage = companyRecords.fold<double>(0.0, (prev, r) => prev + r.dailyWage);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(company.name, style: GoogleFonts.notoSans(fontSize: 15)),
                                            Text('${cWage.toStringAsFixed(0)}원', style: GoogleFonts.notoSans(fontSize: 15)),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            );
          },
        ),
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
      await workProvider.loadCompanies();
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
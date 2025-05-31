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
                                  ? '출근: ${TimeOfDay.fromDateTime(provider.checkInDateTime!).format(context)}'
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
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: ElevatedButton(
                      onPressed: () async {
                        final records = await DatabaseHelper().getWorkRecordsByDateRange(today);
                        final companies = await DatabaseHelper().getCompanies();
                        final companyMap = { for (var c in companies) c.id!: c };
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          isScrollControlled: true,
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: records.isEmpty
                                  ? Center(child: Text('오늘 근무 기록이 없습니다', style: GoogleFonts.notoSans(fontSize: 16, color: Colors.grey[600])))
                                  : ListView.builder(
                                      itemCount: records.length,
                                      itemBuilder: (context, index) {
                                        final r = records[index];
                                        final company = companyMap[r.companyId];
                                        final companyName = company?.name ?? '알 수 없음';
                                        final duration = r.workDuration;
                                        final timeStr = '${r.checkIn?.format(context) ?? '--:--'} ~ ${r.checkOut?.format(context) ?? '--:--'}';
                                        final durationStr = duration.inHours > 0
                                            ? '${duration.inHours}시간${duration.inMinutes.remainder(60) > 0 ? ' ${duration.inMinutes.remainder(60)}분' : ''}'
                                            : '${duration.inMinutes}분';
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    companyName,
                                                    style: GoogleFonts.notoSans(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 4,
                                                  child: Text(
                                                    timeStr,
                                                    style: GoogleFonts.notoSans(
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Text(
                                                      durationStr,
                                                      style: GoogleFonts.notoSans(
                                                        color: Colors.red[700],
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.blueAccent)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text('근무 기록 보기'),
                    ),
                  ),
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
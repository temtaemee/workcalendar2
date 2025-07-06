import 'package:flutter/material.dart';
import '../models/company.dart';
import '../repositories/company_repository.dart';
import '../widgets/company_modal.dart';

class CompanyManagementPage extends StatefulWidget {
  const CompanyManagementPage({super.key});

  @override
  State<CompanyManagementPage> createState() => _CompanyManagementPageState();
}

class _CompanyManagementPageState extends State<CompanyManagementPage> {
  final CompanyRepository _companyRepository = CompanyRepository();
  List<Company> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() { _isLoading = true; });
    final companies = await _companyRepository.getAllCompanies();
    if (mounted) {
      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    }
  }

  void _showCompanyModal({Company? company}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanyModal(
        company: company,
        onSave: (updatedCompany) async {
          if (company == null) {
            await _companyRepository.addCompany(updatedCompany);
          } else {
            await _companyRepository.updateCompany(updatedCompany);
          }
          await _fetchCompanies();
        },
      ),
    );
  }

  Future<void> _deleteCompany(int id) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회사 삭제'),
        content: const Text('정말로 이 회사를 삭제하시겠습니까? 관련된 모든 근무 기록의 연결이 끊어집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _companyRepository.deleteCompany(id);
      await _fetchCompanies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회사 관리'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _companies.length,
              itemBuilder: (context, index) {
                final company = _companies[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: company.color,
                    radius: 10,
                  ),
                  title: Text(company.name),
                  onTap: () => _showCompanyModal(company: company),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteCompany(company.id!),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCompanyModal(),
        child: const Icon(Icons.add),
      ),
    );
  }
} 
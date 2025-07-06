import 'package:flutter/material.dart';
import 'package:workcalendar2/pages/company_management_page.dart';
import 'package:workcalendar2/pages/data_management_page.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: false,
        toolbarHeight: 60,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('회사 관리'),
            subtitle: const Text('회사를 추가하거나 수정, 삭제합니다.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompanyManagementPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('데이터 관리'),
            subtitle: const Text('기존 근무 기록에 회사 정보를 일괄 적용합니다.'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DataManagementPage()),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}

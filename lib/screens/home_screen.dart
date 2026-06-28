import 'package:flutter/material.dart';
import 'account_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = [
      {'icon': '💰', 'name': '개인연금', 'amount': '0원'},
      {'icon': '🏢', 'name': 'DC', 'amount': '0원'},
      {'icon': '💳', 'name': 'ISA', 'amount': '0원'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 ETF', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Text('📊 나의 ETF 자산 관리',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('개인연금 · DC · ISA 통합 관리'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: _SummaryCard(title: '총 매수금액', value: '0원')),
              SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: '총 수익률', value: '연동 예정')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('계좌', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final account in accounts)
            Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountScreen(accountName: account['name']!),
                    ),
                  );
                },
                leading: Text(account['icon']!, style: const TextStyle(fontSize: 28)),
                title: Text(
                  account['name']!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: Text(account['amount']!),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
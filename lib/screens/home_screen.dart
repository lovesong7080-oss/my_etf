import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final accounts = ['개인연금', 'DC', 'ISA'];

  Map<String, int> accountValues = {'개인연금': 0, 'DC': 0, 'ISA': 0};

  int totalBuyAmount = 0;
  int totalEvaluationAmount = 0;

  int get totalProfit => totalEvaluationAmount - totalBuyAmount;

  double get totalProfitRate {
    if (totalBuyAmount == 0) return 0;
    return totalProfit / totalBuyAmount * 100;
  }

  @override
  void initState() {
    super.initState();
    loadTotals();
  }

  Future<void> loadTotals() async {
    final prefs = await SharedPreferences.getInstance();

    int buyTotal = 0;
    int evaluationTotal = 0;
    final values = <String, int>{};

    for (final account in accounts) {
      final saved = prefs.getString('etfs_$account');
      int accountEvaluation = 0;

      if (saved != null) {
        final List data = jsonDecode(saved);

        for (final item in data) {
          final etf = Map<String, dynamic>.from(item);
          final buyPrice = etf['buyPrice'] ?? 0;
          final currentPrice = etf['currentPrice'] ?? buyPrice;
          final quantity = etf['quantity'] ?? 0;

          buyTotal += (buyPrice as int) * (quantity as int);
          evaluationTotal += (currentPrice as int) * quantity;
          accountEvaluation += currentPrice * quantity;
        }
      }

      values[account] = accountEvaluation;
    }

    setState(() {
      totalBuyAmount = buyTotal;
      totalEvaluationAmount = evaluationTotal;
      accountValues = values;
    });
  }

  String won(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String percent(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  Color profitColor(num value) {
    if (value > 0) return Colors.red;
    if (value < 0) return Colors.blue;
    return Colors.black;
  }

  String accountIcon(String account) {
    if (account == '개인연금') return '💰';
    if (account == 'DC') return '🏢';
    if (account == 'ISA') return '💳';
    return '📁';
  }

  Future<void> openAccount(String account) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountScreen(accountName: account)),
    );

    loadTotals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 ETF'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: loadTotals,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            MainAssetCard(
              totalEvaluationAmount: totalEvaluationAmount,
              totalProfit: totalProfit,
              totalProfitRate: totalProfitRate,
              won: won,
              percent: percent,
              profitColor: profitColor,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: '총 매수금액',
                    value: '${won(totalBuyAmount)}원',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: '총 평가금액',
                    value: '${won(totalEvaluationAmount)}원',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: '평가손익',
                    value: '${won(totalProfit)}원',
                    valueColor: profitColor(totalProfit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: '수익률',
                    value: percent(totalProfitRate),
                    valueColor: profitColor(totalProfitRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              '계좌',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final account in accounts)
              AccountTile(
                icon: accountIcon(account),
                title: account,
                value: '${won(accountValues[account] ?? 0)}원',
                onTap: () => openAccount(account),
              ),
          ],
        ),
      ),
    );
  }
}

class MainAssetCard extends StatelessWidget {
  final int totalEvaluationAmount;
  final int totalProfit;
  final double totalProfitRate;
  final String Function(int) won;
  final String Function(double) percent;
  final Color Function(num) profitColor;

  const MainAssetCard({
    super.key,
    required this.totalEvaluationAmount,
    required this.totalProfit,
    required this.totalProfitRate,
    required this.won,
    required this.percent,
    required this.profitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 내 ETF 총자산',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Text(
            '${won(totalEvaluationAmount)}원',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            '${won(totalProfit)}원  /  ${percent(totalProfitRate)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: profitColor(totalProfit),
            ),
          ),
          const SizedBox(height: 8),
          const Text('개인연금 · DC · ISA 통합 자산'),
        ],
      ),
    );
  }
}

class AccountTile extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const AccountTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        leading: Text(icon, style: const TextStyle(fontSize: 26)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        trailing: Text(value),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
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
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

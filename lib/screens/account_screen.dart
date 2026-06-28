import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/naver_service.dart';

class AccountScreen extends StatefulWidget {
  final String accountName;

  const AccountScreen({
    super.key,
    required this.accountName,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<Map<String, dynamic>> etfs = [];
  bool isLoadingPrices = false;

  String get storageKey => 'etfs_${widget.accountName}';

  @override
  void initState() {
    super.initState();
    loadEtfs();
  }

  Future<void> loadEtfs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(storageKey);

    if (savedData != null) {
      final List decoded = jsonDecode(savedData);
      setState(() {
        etfs = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }

    await refreshPrices();
  }

  Future<void> saveEtfs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(etfs));
  }

  int get totalBuyAmount {
    int total = 0;
    for (final etf in etfs) {
      total += (etf['buyPrice'] as int) * (etf['quantity'] as int);
    }
    return total;
  }

  int get totalEvaluationAmount {
    int total = 0;
    for (final etf in etfs) {
      final currentPrice = etf['currentPrice'] as int?;
      final quantity = etf['quantity'] as int;
      if (currentPrice != null) {
        total += currentPrice * quantity;
      }
    }
    return total;
  }

  int get totalProfitLoss => totalEvaluationAmount - totalBuyAmount;

  double get totalProfitRate {
    if (totalBuyAmount == 0) return 0;
    return totalProfitLoss / totalBuyAmount * 100;
  }

  Future<void> refreshPrices() async {
    if (etfs.isEmpty) return;

    setState(() {
      isLoadingPrices = true;
    });

    for (final etf in etfs) {
      final price = await NaverService.getCurrentPrice(etf['name']);
      etf['currentPrice'] = price;
    }

    await saveEtfs();

    if (mounted) {
      setState(() {
        isLoadingPrices = false;
      });
    }
  }

  void showAddEtfDialog() {
    final nameController = TextEditingController();
    final buyPriceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('ETF 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ETF 이름',
                  hintText: '예: KODEX 200',
                ),
              ),
              TextField(
                controller: buyPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '매수가'),
              ),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '수량'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final buyPrice = int.tryParse(buyPriceController.text) ?? 0;
                final quantity = int.tryParse(quantityController.text) ?? 0;

                if (name.isEmpty || buyPrice <= 0 || quantity <= 0) {
                  return;
                }

                final currentPrice = await NaverService.getCurrentPrice(name);

                setState(() {
                  etfs.add({
                    'name': name,
                    'buyPrice': buyPrice,
                    'quantity': quantity,
                    'currentPrice': currentPrice,
                  });
                });

                await saveEtfs();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void deleteEtf(int index) async {
    setState(() {
      etfs.removeAt(index);
    });
    await saveEtfs();
  }

  String formatWon(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  String formatRate(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  Color profitColor(num value) {
    if (value > 0) return Colors.red;
    if (value < 0) return Colors.blue;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName),
        actions: [
          IconButton(
            onPressed: isLoadingPrices ? null : refreshPrices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (isLoadingPrices)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(child: Text('현재가 불러오는 중...')),
            ),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: '총 매수금액',
                  value: '${formatWon(totalBuyAmount)}원',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: '총 평가금액',
                  value: totalEvaluationAmount == 0
                      ? '조회 전'
                      : '${formatWon(totalEvaluationAmount)}원',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: '평가손익',
                  value: totalEvaluationAmount == 0
                      ? '조회 전'
                      : '${formatWon(totalProfitLoss)}원',
                  valueColor: profitColor(totalProfitLoss),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: '수익률',
                  value: totalEvaluationAmount == 0
                      ? '조회 전'
                      : formatRate(totalProfitRate),
                  valueColor: profitColor(totalProfitRate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '보유 ETF',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (etfs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('아직 등록된 ETF가 없습니다.')),
            ),
          for (int i = 0; i < etfs.length; i++)
            _EtfCard(
              etf: etfs[i],
              onDelete: () => deleteEtf(i),
              formatWon: formatWon,
              formatRate: formatRate,
              profitColor: profitColor,
            ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: showAddEtfDialog,
            icon: const Icon(Icons.add),
            label: const Text('ETF 추가'),
          ),
        ],
      ),
    );
  }
}

class _EtfCard extends StatelessWidget {
  final Map<String, dynamic> etf;
  final VoidCallback onDelete;
  final String Function(int) formatWon;
  final String Function(double) formatRate;
  final Color Function(num) profitColor;

  const _EtfCard({
    required this.etf,
    required this.onDelete,
    required this.formatWon,
    required this.formatRate,
    required this.profitColor,
  });

  @override
  Widget build(BuildContext context) {
    final buyPrice = etf['buyPrice'] as int;
    final quantity = etf['quantity'] as int;
    final currentPrice = etf['currentPrice'] as int?;

    final buyAmount = buyPrice * quantity;
    final evaluationAmount =
        currentPrice == null ? null : currentPrice * quantity;
    final profitLoss =
        evaluationAmount == null ? null : evaluationAmount - buyAmount;
    final profitRate =
        profitLoss == null ? null : profitLoss / buyAmount * 100;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        title: Text(
          etf['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          currentPrice == null
              ? '매수가 ${formatWon(buyPrice)}원 · ${quantity}주\n현재가 조회 실패'
              : '매수가 ${formatWon(buyPrice)}원 · 현재가 ${formatWon(currentPrice)}원 · ${quantity}주',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              evaluationAmount == null
                  ? '${formatWon(buyAmount)}원'
                  : '${formatWon(evaluationAmount)}원',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (profitLoss != null && profitRate != null)
              Text(
                '${formatWon(profitLoss)}원 / ${formatRate(profitRate)}',
                style: TextStyle(
                  color: profitColor(profitLoss),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            GestureDetector(
              onTap: onDelete,
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _SummaryCard({
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
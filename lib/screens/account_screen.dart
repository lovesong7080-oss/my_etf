import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/price_service.dart';

class AccountScreen extends StatefulWidget {
  final String accountName;

  const AccountScreen({super.key, required this.accountName});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<Map<String, dynamic>> etfs = [];

  final List<String> etfNames = [
    'KODEX 200',
    'KODEX 미국S&P500',
    'KODEX 미국나스닥100',
    'KODEX 반도체',
    'TIGER 미국S&P500',
    'TIGER 미국나스닥100',
    'ACE 미국S&P500',
    'ACE 미국나스닥100',
    'SOL 미국배당다우존스',
    'SOL 반도체소부장',
    'HANARO Fn K-반도체',
    'RISE 미국S&P500',
    'RISE 미국나스닥100',
  ];

  String get storageKey => 'etfs_${widget.accountName}';

  @override
  void initState() {
    super.initState();
    loadEtfs();
  }

  Future<void> loadEtfs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);

    if (saved == null) return;

    final List data = jsonDecode(saved);
    setState(() {
      etfs = data.map((e) {
        final item = Map<String, dynamic>.from(e);
        item['currentPrice'] ??= item['buyPrice'] ?? 0;
        return item;
      }).toList();
    });
  }

  Future<void> saveEtfs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(etfs));
  }

  Future<void> refreshPrices() async {
    final updatedEtfs = await PriceService.refreshEtfPrices(etfs);

    setState(() {
      etfs = updatedEtfs;
    });

    await saveEtfs();
  }

  int get totalBuyAmount {
    return etfs.fold(0, (sum, e) {
      return sum + (e['buyPrice'] as int) * (e['quantity'] as int);
    });
  }

  int get totalEvaluationAmount {
    return etfs.fold(0, (sum, e) {
      return sum + (e['currentPrice'] as int) * (e['quantity'] as int);
    });
  }

  int get totalProfit => totalEvaluationAmount - totalBuyAmount;

  double get totalProfitRate {
    if (totalBuyAmount == 0) return 0;
    return totalProfit / totalBuyAmount * 100;
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

  String brandText(String name) {
    final upper = name.toUpperCase();
    if (upper.contains('KODEX')) return 'KODEX';
    if (upper.contains('TIGER')) return 'TIGER';
    if (upper.contains('ACE')) return 'ACE';
    if (upper.contains('SOL')) return 'SOL';
    if (upper.contains('HANARO')) return 'HANARO';
    if (upper.contains('RISE')) return 'RISE';
    return 'ETF';
  }

  void openEtfDialog({int? index}) {
    final isEdit = index != null;
    final old = isEdit ? etfs[index] : null;

    final nameController = TextEditingController(text: old?['name'] ?? '');
    final buyPriceController = TextEditingController(
      text: old?['buyPrice']?.toString() ?? '',
    );
    final currentPriceController = TextEditingController(
      text: old?['currentPrice']?.toString() ?? '',
    );
    final quantityController = TextEditingController(
      text: old?['quantity']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'ETF 수정' : 'ETF 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              initialValue: TextEditingValue(text: nameController.text),
              optionsBuilder: (value) {
                if (value.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return etfNames.where(
                  (name) =>
                      name.toLowerCase().contains(value.text.toLowerCase()),
                );
              },
              onSelected: (selected) {
                nameController.text = selected;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    controller.text = nameController.text;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );

                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'ETF 이름'),
                    );
                  },
            ),
            TextField(
              controller: buyPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '매수가'),
            ),
            TextField(
              controller: currentPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '현재가'),
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
              final currentPrice =
                  int.tryParse(currentPriceController.text) ?? 0;
              final quantity = int.tryParse(quantityController.text) ?? 0;

              if (name.isEmpty ||
                  buyPrice <= 0 ||
                  currentPrice <= 0 ||
                  quantity <= 0) {
                return;
              }

              final newEtf = {
                'name': name,
                'buyPrice': buyPrice,
                'currentPrice': currentPrice,
                'quantity': quantity,
              };

              setState(() {
                if (isEdit) {
                  etfs[index] = newEtf;
                } else {
                  etfs.add(newEtf);
                }
              });

              await saveEtfs();

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('${etfs[index]['name']}을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                etfs.removeAt(index);
              });

              await saveEtfs();

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.accountName)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: refreshPrices,
            icon: const Icon(Icons.refresh),
            label: const Text('현재가 새로고침'),
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
            EtfCard(
              etf: etfs[i],
              brand: brandText(etfs[i]['name']),
              won: won,
              percent: percent,
              profitColor: profitColor,
              onTap: () => openEtfDialog(index: i),
              onDelete: () => confirmDelete(i),
            ),
          const SizedBox(height: 18),

          AllocationCard(etfs: etfs, won: won),

          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => openEtfDialog(),
            icon: const Icon(Icons.add),
            label: const Text('ETF 추가'),
          ),
        ],
      ),
    );
  }
}

class EtfCard extends StatelessWidget {
  final Map<String, dynamic> etf;
  final String brand;
  final String Function(int) won;
  final String Function(double) percent;
  final Color Function(num) profitColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const EtfCard({
    super.key,
    required this.etf,
    required this.brand,
    required this.won,
    required this.percent,
    required this.profitColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final buyPrice = etf['buyPrice'] as int;
    final currentPrice = etf['currentPrice'] as int;
    final quantity = etf['quantity'] as int;

    final evaluationAmount = currentPrice * quantity;
    final profit = evaluationAmount - (buyPrice * quantity);
    final rate = buyPrice == 0 ? 0.0 : profit / (buyPrice * quantity) * 100;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  brand,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etf['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '매수가 ${won(buyPrice)}원 · 현재가 ${won(currentPrice)}원 · $quantity주',
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${won(evaluationAmount)}원',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${won(profit)}원 / ${percent(rate)}',
                    style: TextStyle(
                      color: profitColor(profit),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class AllocationCard extends StatelessWidget {
  final List<Map<String, dynamic>> etfs;
  final String Function(int) won;

  static const chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  const AllocationCard({super.key, required this.etfs, required this.won});

  @override
  Widget build(BuildContext context) {
    final total = etfs.fold<int>(
      0,
      (sum, e) => sum + (e['currentPrice'] as int) * (e['quantity'] as int),
    );

    if (etfs.isEmpty || total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '보유 비중',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: [
                  for (int i = 0; i < etfs.length; i++)
                    PieChartSectionData(
                      color: chartColors[i % chartColors.length],
                      value:
                          ((etfs[i]['currentPrice'] as int) *
                                  (etfs[i]['quantity'] as int))
                              .toDouble(),
                      title:
                          '${((((etfs[i]['currentPrice'] as int) * (etfs[i]['quantity'] as int)) / total) * 100).toStringAsFixed(1)}%',
                      radius: 54,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final etf in etfs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      etf['name'],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${(((etf['currentPrice'] as int) * (etf['quantity'] as int)) / total * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    won(
                      (etf['currentPrice'] as int) * (etf['quantity'] as int),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

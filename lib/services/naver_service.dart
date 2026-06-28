import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverService {
  static const Map<String, String> etfCodes = {
    'KODEX 200': '069500',
    'kodex 200': '069500',
    'HANARO Fn K-반도체': '395270',
    'hanaro fn k-반도체': '395270',
    'SOL 반도체소부장': '455850',
    'sol반도체 소부장': '455850',
    'sol 반도체소부장': '455850',
  };

  static Future<int?> getCurrentPrice(String etfName) async {
    final code = etfCodes[etfName.trim()];

    if (code == null) {
      return null;
    }

    final url = Uri.parse(
      'https://api.finance.naver.com/service/itemSummary.nhn?itemcode=$code',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    final price = data['now'];

    if (price is int) {
      return price;
    }

    return int.tryParse(price.toString());
  }
}
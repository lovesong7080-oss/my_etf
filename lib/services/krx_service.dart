import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_key.dart';

class KrxService {
  static const Map<String, String> etfCodes = {
    'KODEX 200': '069500',
    'kodex 200': '069500',
    'KODEX 미국S&P500': '379800',
    'TIGER 미국S&P500': '360750',
    'TIGER 미국나스닥100': '133690',
    'ACE 미국S&P500': '360200',
    'ACE 미국나스닥100': '367380',
    'SOL 미국배당다우존스': '446720',
    'SOL 반도체소부장': '455850',
    'HANARO Fn K-반도체': '395270',
    'RISE 미국S&P500': '379780',
    'RISE 미국나스닥100': '368590',
  };

  static Future<int?> getCurrentPrice(String etfName) async {
    try {
      final code = etfCodes[etfName.trim()];

      if (code == null || ApiKey.serviceKey.isEmpty) {
        return null;
      }

      final url =
          Uri.parse(
            'https://apis.data.go.kr/1160100/service/GetSecuritiesProductInfoService/getETFPriceInfo',
          ).replace(
            queryParameters: {
              'serviceKey': ApiKey.serviceKey,
              'resultType': 'json',
              'numOfRows': '10',
              'pageNo': '1',
              'likeSrtnCd': code,
            },
          );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final items = data['response']?['body']?['items']?['item'];

      if (items == null) return null;

      final List itemList = items is List ? items : [items];

      for (final item in itemList) {
        if (item['srtnCd'] == code) {
          final priceText = item['clpr'].toString().replaceAll(',', '');
          return int.tryParse(priceText);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static String? getCode(String etfName) {
    return etfCodes[etfName.trim()];
  }
}

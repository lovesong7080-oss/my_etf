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
    final code = etfCodes[etfName.trim()];

    if (code == null) {
      return null;
    }

    if (ApiKey.serviceKey.isEmpty) {
      return null;
    }

    // TODO: 공공데이터포털/KRX API 키 발급 후 실제 시세 API 연결
    // 현재는 API 키 자리와 종목코드 매핑만 준비합니다.
    await Future.delayed(const Duration(milliseconds: 200));

    return null;
  }

  static String? getCode(String etfName) {
    return etfCodes[etfName.trim()];
  }
}

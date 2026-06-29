import 'api_key.dart';
import 'krx_service.dart';
import 'naver_service.dart';

class PriceService {
  static Future<int> getCurrentPrice({
    required String etfName,
    required int currentPrice,
  }) async {
    if (ApiKey.serviceKey.isNotEmpty) {
      final krxPrice = await KrxService.getCurrentPrice(etfName);

      if (krxPrice != null && krxPrice > 0) {
        return krxPrice;
      }
    }

    final naverPrice = await NaverService.getCurrentPrice(etfName);

    if (naverPrice != null && naverPrice > 0) {
      return naverPrice;
    }

    return currentPrice;
  }

  static Future<List<Map<String, dynamic>>> refreshEtfPrices(
    List<Map<String, dynamic>> etfs,
  ) async {
    final updatedEtfs = <Map<String, dynamic>>[];

    for (final etf in etfs) {
      final updatedPrice = await getCurrentPrice(
        etfName: etf['name'],
        currentPrice: etf['currentPrice'],
      );

      updatedEtfs.add({...etf, 'currentPrice': updatedPrice});
    }

    return updatedEtfs;
  }
}

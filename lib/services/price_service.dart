import 'naver_service.dart';

class PriceService {
  static Future<int> getCurrentPrice({
    required String etfName,
    required int currentPrice,
  }) async {
    final realPrice = await NaverService.getCurrentPrice(etfName);

    if (realPrice != null && realPrice > 0) {
      return realPrice;
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

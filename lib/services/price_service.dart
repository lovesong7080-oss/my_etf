class PriceService {
  static Future<int> getCurrentPrice({
    required String etfName,
    required int currentPrice,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final name = etfName.toUpperCase();

    if (name.contains('KODEX')) return currentPrice + 25;
    if (name.contains('TIGER')) return currentPrice + 35;
    if (name.contains('ACE')) return currentPrice + 30;
    if (name.contains('SOL')) return currentPrice + 20;
    if (name.contains('HANARO')) return currentPrice + 15;
    if (name.contains('RISE')) return currentPrice + 25;

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

      updatedEtfs.add({
        ...etf,
        'currentPrice': updatedPrice,
      });
    }

    return updatedEtfs;
  }
}
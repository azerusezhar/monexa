import 'package:intl/intl.dart';

class AppFormatters {
  static String formatToIdrCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

extension NumberFormattingExtensions on num {
  String toRupiahFormat() {
    return AppFormatters.formatToIdrCurrency(this.toDouble());
  }
}

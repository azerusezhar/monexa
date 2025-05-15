import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat idrCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ', 
    decimalDigits: 0,
  );


  static String formatToIdrCurrency(num value) {
    return idrCurrency.format(value);
  }
}

extension NumberFormattingExtensions on num {
  String toRupiahFormat() {
    return AppFormatters.idrCurrency.format(this);
  }
}
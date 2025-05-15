import 'package:intl/intl.dart';

extension DateFormatting on String {
  String toLocalDate() {
    try {
      final dateTime = DateTime.parse(this).toLocal();
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return this;
    }
  }
}
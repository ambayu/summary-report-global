import 'package:intl/intl.dart';

String formatDateTime(DateTime value) {
  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(value);
}

String formatShortDate(DateTime value) {
  return DateFormat('dd MMM', 'id_ID').format(value);
}

import 'package:intl/intl.dart';

class DateFormatter {
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateLongFormat = DateFormat('d MMM yyyy', 'es');
  static final _dateShortFormat = DateFormat('d MMM', 'es');

  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatDate(DateTime dt) => _dateFormat.format(dt);
  static String formatLong(DateTime dt) => _dateLongFormat.format(dt);
  static String formatShort(DateTime dt) => _dateShortFormat.format(dt);

  static String formatChatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) return formatTime(dt);
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return _weekdayEs(dt.weekday);
    return formatDate(dt);
  }

  static String _weekdayEs(int weekday) {
    const days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday];
  }
}

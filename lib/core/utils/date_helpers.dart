import 'package:intl/intl.dart';

class DateHelpers {
  DateHelpers._();

  static final _monthYear = DateFormat('MMMM yyyy');
  static final _shortDate = DateFormat('d MMM');
  static final _longDate = DateFormat('d MMM yyyy');
  static final _dayNum = DateFormat('d');

  static String monthYear(DateTime d) => _monthYear.format(d);
  static String shortDate(DateTime d) => _shortDate.format(d);
  static String longDate(DateTime d)  => _longDate.format(d);
  static String dayNum(DateTime d)    => _dayNum.format(d);

  /// "in 3 days", "today", "tomorrow", "2 weeks".
  static String relative(DateTime target) {
    final now = DateTime.now();
    final a = DateTime(target.year, target.month, target.day);
    final b = DateTime(now.year, now.month, now.day);
    final days = a.difference(b).inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'tomorrow';
    if (days == -1) return 'yesterday';
    if (days > 0 && days < 7) return 'in $days days';
    if (days < 0 && days > -7) return '${-days} days ago';
    if (days >= 7 && days < 30) {
      final w = (days / 7).round();
      return 'in $w ${w == 1 ? 'week' : 'weeks'}';
    }
    if (days >= 30) {
      final m = (days / 30).round();
      return 'in $m ${m == 1 ? 'month' : 'months'}';
    }
    return _shortDate.format(target);
  }

  /// "5h ago", "2d ago", "3w ago".
  static String relativeAgo(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    final months = (diff.inDays / 30).round();
    return '${months}mo ago';
  }

  /// Start of month helper.
  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);
  static DateTime monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);
  static DateTime addMonths(DateTime d, int n) =>
      DateTime(d.year, d.month + n, d.day);
}

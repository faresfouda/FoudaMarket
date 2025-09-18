import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseTimestamp(dynamic timestamp) {
  if (timestamp == null) {
    return DateTime.now();
  }

  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  } else if (timestamp is Map && timestamp['_seconds'] != null) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
  } else if (timestamp.runtimeType.toString() == 'Timestamp') {
    return timestamp.toDate();
  } else {
    return DateTime.now();
  }
}

String formatTimeAgo(dynamic timestamp) {
  if (timestamp == null) return 'غير معروف';

  DateTime date;
  if (timestamp is Timestamp) {
    date = timestamp.toDate();
  } else if (timestamp is String) {
    date = DateTime.tryParse(timestamp) ?? DateTime.now();
  } else if (timestamp is Map && timestamp['_seconds'] != null) {
    date = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
  } else if (timestamp.runtimeType.toString() == 'Timestamp') {
    date = timestamp.toDate();
  } else {
    return 'غير معروف';
  }

  final now = DateTime.now();
  final difference = now.difference(date);
  final time =
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  if (difference.inDays > 365) {
    final years = (difference.inDays / 365).floor();
    return 'منذ $years ${years == 1 ? 'سنة' : 'سنوات'} ($time)';
  } else if (difference.inDays > 30) {
    final months = (difference.inDays / 30).floor();
    return 'منذ $months ${months == 1 ? 'شهر' : 'شهور'} ($time)';
  } else if (difference.inDays > 7) {
    final weeks = (difference.inDays / 7).floor();
    return 'منذ $weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'} ($time)';
  } else if (difference.inDays > 0) {
    return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'} ($time)';
  } else if (difference.inHours > 0) {
    return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'} ($time)';
  } else if (difference.inMinutes > 0) {
    return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
  } else {
    return 'الآن';
  }
}

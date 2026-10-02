import 'package:intl/intl.dart';

class ApplicationService {
  static String generateReferenceNumber() {
    final year = DateTime.now().year;
    final sequence = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'LA-$year-${sequence.toString().padLeft(6, '0')}';
  }

  static String formatSubmissionDateTime() {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(now)} • ${timeFormat.format(now)}';
  }

  static String getExpectedProcessingTime() {
    return '3–5 Working Days';
  }
}

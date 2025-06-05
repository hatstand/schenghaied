import 'package:schengen/models/stay_record.dart';

class SchengenCalculator {
  // Constants for Schengen rules
  static const int maxStayDays = 90;
  static const int lookbackPeriodDays = 180;

  // Calculate days spent in the Schengen zone in the last 180 days from a reference date
  static int calculateDaysSpent(
    List<StayRecord> stays, [
    DateTime? referenceDate,
  ]) {
    final date = referenceDate ?? DateTime.now();
    final lookbackDate = date.subtract(
      const Duration(days: lookbackPeriodDays),
    );

    int daysSpent = 0;

    for (var stay in stays) {
      // Skip stays that ended before the lookback period
      if (stay.exitDate != null && stay.exitDate!.isBefore(lookbackDate)) {
        continue;
      }

      // Calculate the start date for this stay for our counting
      DateTime startCountingFrom = stay.entryDate.isAfter(lookbackDate)
          ? stay.entryDate
          : lookbackDate;

      // Calculate the end date for this stay for our counting
      DateTime endCountingAt =
          stay.exitDate == null || stay.exitDate!.isAfter(date)
          ? date
          : stay.exitDate!;

      // Add the days from this stay within our period
      if (!endCountingAt.isBefore(startCountingFrom)) {
        daysSpent += endCountingAt.difference(startCountingFrom).inDays + 1;
      }
    }

    return daysSpent;
  }

  // Calculate days remaining in the Schengen zone based on past stays
  static int calculateDaysRemaining(
    List<StayRecord> stays, [
    DateTime? referenceDate,
  ]) {
    int daysSpent = calculateDaysSpent(stays, referenceDate);
    return maxStayDays - daysSpent;
  }

  // Check if a person is currently in the Schengen zone
  static bool isCurrentlyInSchengen(List<StayRecord> stays) {
    if (stays.isEmpty) return false;

    // Sort by entry date descending to check the most recent stay
    final sortedStays = List<StayRecord>.from(stays)
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    // If the most recent stay has no exit date, the person is still in Schengen
    return sortedStays.first.exitDate == null;
  }

  // Get the most recent stay record
  static StayRecord? getMostRecentStay(List<StayRecord> stays) {
    if (stays.isEmpty) return null;

    final sortedStays = List<StayRecord>.from(stays)
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));

    return sortedStays.first;
  }
}

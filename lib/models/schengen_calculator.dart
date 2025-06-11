import 'package:schengen/models/stay_record.dart';
import 'package:schengen/utils/logger.dart';
import 'package:time_machine/time_machine.dart';

class SchengenCalculator {
  // Constants for Schengen rules
  static const int maxStayDays = 90;
  static const int lookbackPeriodDays = 180;
  static final logger = AppLogger.getLogger('SchengenCalculator');

  // Calculate days spent in the Schengen zone in the last 180 days from a reference date
  static int calculateDaysSpent(
    List<StayRecord> stays, [
    LocalDate? referenceDate,
  ]) {
    final date = referenceDate ?? LocalDate.today();
    // Subtract 180 days from the reference date
    final lookbackDate = date.addDays(-lookbackPeriodDays);

    int daysSpent = 0;

    for (var stay in stays) {
      // Skip stays that ended before the lookback period
      if (stay.exitDate != null && stay.exitDate! < lookbackDate) {
        continue;
      }

      // Calculate the start date for this stay for our counting
      LocalDate startCountingFrom = stay.entryDate > lookbackDate
          ? stay.entryDate
          : lookbackDate;

      // Calculate the end date for this stay for our counting
      LocalDate endCountingAt = (stay.exitDate == null || stay.exitDate! > date)
          ? date
          : stay.exitDate!;

      // Add the days from this stay within our period
      final daysSpentFromThisStay =
          Period.differenceBetweenDates(
            startCountingFrom,
            endCountingAt,
            PeriodUnits.days,
          ).days +
          1;
      daysSpent += daysSpentFromThisStay;
    }
    return daysSpent;
  }

  // Calculate days remaining in the Schengen zone based on past stays
  static int calculateDaysRemaining(
    List<StayRecord> stays, [
    LocalDate? referenceDate,
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

  // Calculate days until the user must leave the Schengen zone
  static int? calculateDaysUntilMustLeave(
    List<StayRecord> stays, [
    LocalDate? referenceDate,
  ]) {
    final date = referenceDate ?? LocalDate.today();

    if (!isCurrentlyInSchengen(stays)) {
      return null;
    }

    // Calculate days spent and remaining based on the 90/180 rule
    int daysSpent = calculateDaysSpent(stays, date);
    int daysRemaining = maxStayDays - daysSpent;

    if (daysRemaining <= 0) {
      // Already overstayed, must leave immediately
      return 0;
    }

    // Try every day from today until 90 days later.
    final maxLookaheadDate = date.addDays(90);
    for (var cand = date; cand < maxLookaheadDate; cand += Period(days: 1)) {
      final daysSpent = calculateDaysSpent(stays, cand);
      final daysRemaining = maxStayDays - daysSpent;
      if (daysRemaining <= 0) {
        // Found the first day where the user must leave
        return Period.differenceBetweenDates(date, cand, PeriodUnits.days).days;
      }
    }
    throw Exception(
      'Unable to calculate days until must leave. This should not happen.',
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:schengen/models/stay_record.dart';
import 'package:schengen/models/schengen_calculator.dart';
import 'package:time_machine/time_machine.dart';

void main() {
  group('SchengenCalculator Tests', () {
    // Setup test data
    final today = LocalDate(2025, 6, 6); // Use a fixed date for testing

    final stayRecords = [
      StayRecord(
        id: 1,
        entryDate: LocalDate(2025, 1, 1),
        exitDate: LocalDate(2025, 1, 15),
        notes: 'Two week stay',
      ),
      StayRecord(
        id: 2,
        entryDate: LocalDate(2025, 3, 10),
        exitDate: LocalDate(2025, 3, 25),
        notes: 'Another two week stay',
      ),
      StayRecord(
        id: 3,
        entryDate: LocalDate(2025, 5, 20),
        exitDate: null, // Ongoing stay
        notes: 'Current stay',
      ),
    ];

    test('isCurrentlyInSchengen returns true when having ongoing stay', () {
      expect(SchengenCalculator.isCurrentlyInSchengen(stayRecords), true);
    });

    test('isCurrentlyInSchengen returns false with no ongoing stay', () {
      final completedStays = [
        StayRecord(
          id: 1,
          entryDate: LocalDate(2025, 1, 1),
          exitDate: LocalDate(2025, 1, 15),
        ),
        StayRecord(
          id: 2,
          entryDate: LocalDate(2025, 3, 10),
          exitDate: LocalDate(2025, 3, 25),
        ),
      ];

      expect(SchengenCalculator.isCurrentlyInSchengen(completedStays), false);
    });

    test('calculateDaysSpent returns correct total for the reference date', () {
      // January 1-15 = 15 days (inclusive)
      // March 10-25 = 16 days (inclusive)
      // May 20-June 6 = 18 days (inclusive)
      // Total: 15 + 16 + 18 = 49 days
      final daysSpent = SchengenCalculator.calculateDaysSpent(
        stayRecords,
        today,
      );
      expect(daysSpent, 49);
    });

    test('calculateDaysRemaining returns correct days left', () {
      // 90 - 49 = 41 days remaining
      final daysRemaining = SchengenCalculator.calculateDaysRemaining(
        stayRecords,
        today,
      );
      expect(daysRemaining, 41);
    });

    test('getMostRecentStay returns the latest stay', () {
      final latestStay = SchengenCalculator.getMostRecentStay(stayRecords);
      expect(latestStay?.id, 3);
    });

    test('calculateDaysUntilMustLeave returns correct countdown days', () {
      // Current stay is 18 days, plus previous stays of 31 days = 49 days total
      // We are allowed 90 days, so initially we have 41 days remaining

      // For this simple test case, no days are "rolling off" within those 41 days,
      // so the countdown should be 41 days
      final daysUntilMustLeave = SchengenCalculator.calculateDaysUntilMustLeave(
        stayRecords,
        today,
      );
      expect(daysUntilMustLeave, 41);
    });

    test('calculateDaysUntilMustLeave returns -1 when not in Schengen', () {
      final completedStays = [
        StayRecord(
          id: 1,
          entryDate: LocalDate(2025, 1, 1),
          exitDate: LocalDate(2025, 1, 15),
        ),
        StayRecord(
          id: 2,
          entryDate: LocalDate(2025, 3, 10),
          exitDate: LocalDate(2025, 3, 25),
        ),
      ];

      final daysUntilMustLeave = SchengenCalculator.calculateDaysUntilMustLeave(
        completedStays,
        today,
      );
      expect(daysUntilMustLeave, -1);
    });
  });
}

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
      expect(SchengenCalculator.isCurrentlyInSchengen(stayRecords), isTrue);
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

      expect(SchengenCalculator.isCurrentlyInSchengen(completedStays), isFalse);
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

    test('simple calculateDaysUntilMustLeave with one ongoing visit', () {
      final daysRemaining = SchengenCalculator.calculateDaysUntilMustLeave([
        StayRecord(entryDate: today, exitDate: null),
      ], today);
      expect(daysRemaining, 89);
    });

    test('calculateDaysUntilMustLeave returns correct countdown days', () {
      // Current stay is 18 days, plus previous stays of 31 days = 49 days total
      // We are allowed 90 days, so initially we have 41 days remaining
      // The first day rolls off during the current stay, adding back 15 days.
      final daysUntilMustLeave = SchengenCalculator.calculateDaysUntilMustLeave(
        stayRecords,
        today,
      );
      expect(daysUntilMustLeave, 56);
    });

    test('calculateDaysUntilMustLeave returns null when not in Schengen', () {
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
      expect(daysUntilMustLeave, isNull);
    });

    test(
      'calculateDaysUntilMustLeave includes days rolling off the beginning of the 180 day window',
      () {
        final completedStays = [
          StayRecord(
            id: 1,
            entryDate: LocalDate(2025, 1, 1),
            exitDate: LocalDate(2025, 1, 31),
            // 180 days after this is July 29th.
          ),
          // 31 days so far.
          // Complete the other 59 days right up to the 180 day window.
          StayRecord(
            id: 3,
            entryDate: LocalDate(2025, 5, 31),
            exitDate: null, // Ongoing stay
            notes: 'Current stay',
          ),
        ];

        final daysUntilMustLeave =
            SchengenCalculator.calculateDaysUntilMustLeave(
              completedStays,
              LocalDate(2025, 5, 31),
            );
        // All the days from the first stay are rolling off immediately.
        expect(daysUntilMustLeave, 89);
      },
    );
  });
}

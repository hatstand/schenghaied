// filepath: /home/john/code/schengen/lib/models/stay_record.dart
import 'package:intl/intl.dart';
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_text_patterns.dart';

// Ensure Time Machine is initialized in the app
Future<void> initializeTimeMachine() async {
  await TimeMachine.initialize();
}

class StayRecord {
  final int? id;
  final LocalDate entryDate;
  final LocalDate? exitDate;
  final String notes;

  StayRecord({
    this.id,
    required this.entryDate,
    this.exitDate,
    this.notes = '',
  });

  // Duration of the stay in days
  int get durationInDays {
    if (exitDate == null) {
      // If still in the Schengen zone, calculate days until today
      final today = LocalDate.today();
      // Calculate the period between dates and get days
      return today.periodSince(entryDate).days + 1;
    }
    return exitDate!.periodSince(entryDate).days + 1;
  }

  // Check if stay is ongoing (no exit date)
  bool get isOngoing => exitDate == null;

  // Format date for display
  String get formattedEntryDate => _formatLocalDate(entryDate);
  String get formattedExitDate =>
      exitDate != null ? _formatLocalDate(exitDate!) : 'Present';

  // Helper method to format LocalDate
  String _formatLocalDate(LocalDate date) {
    // Convert LocalDate to DateTime for formatting with intl package
    final dateTime = DateTime(date.year, date.monthOfYear, date.dayOfMonth);
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  // Get DateTime representation (for backward compatibility)
  DateTime get entryDateTime =>
      DateTime(entryDate.year, entryDate.monthOfYear, entryDate.dayOfMonth);

  DateTime? get exitDateTime => exitDate != null
      ? DateTime(exitDate!.year, exitDate!.monthOfYear, exitDate!.dayOfMonth)
      : null;

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_date': LocalDatePattern.iso.format(
        entryDate,
      ), // Store as ISO string
      'exit_date': exitDate != null
          ? LocalDatePattern.iso.format(exitDate!)
          : null, // Store as ISO string
      'notes': notes,
    };
  }

  // Create StayRecord from map (database)
  factory StayRecord.fromMap(Map<String, dynamic> map) {
    return StayRecord(
      id: map['id'],
      entryDate: LocalDatePattern.iso.parse(map['entry_date']).value,
      exitDate: map['exit_date'] != null
          ? LocalDatePattern.iso.parse(map['exit_date']).value
          : null,
      notes: map['notes'] ?? '',
    );
  }

  // Create a copy of this StayRecord with modified fields
  StayRecord copyWith({
    int? id,
    LocalDate? entryDate,
    Object? exitDate = const Object(),
    String? notes,
  }) {
    return StayRecord(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate == const Object()
          ? this.exitDate
          : (exitDate as LocalDate?),
      notes: notes ?? this.notes,
    );
  }

  // Create a StayRecord from DateTime objects (for backward compatibility)
  factory StayRecord.fromDateTime({
    int? id,
    required DateTime entryDateTime,
    DateTime? exitDateTime,
    String notes = '',
  }) {
    return StayRecord(
      id: id,
      entryDate: LocalDate.dateTime(entryDateTime),
      exitDate: exitDateTime != null ? LocalDate.dateTime(exitDateTime) : null,
      notes: notes,
    );
  }
}

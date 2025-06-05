import 'package:intl/intl.dart';

class StayRecord {
  final int? id;
  final DateTime entryDate;
  final DateTime? exitDate;
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
      return DateTime.now().difference(entryDate).inDays + 1;
    }
    return exitDate!.difference(entryDate).inDays + 1;
  }

  // Check if stay is ongoing (no exit date)
  bool get isOngoing => exitDate == null;

  // Format date for display
  String get formattedEntryDate => DateFormat('MMM dd, yyyy').format(entryDate);
  String get formattedExitDate => exitDate != null
      ? DateFormat('MMM dd, yyyy').format(exitDate!)
      : 'Present';

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_date': entryDate.millisecondsSinceEpoch,
      'exit_date': exitDate?.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  // Create StayRecord from map (database)
  factory StayRecord.fromMap(Map<String, dynamic> map) {
    return StayRecord(
      id: map['id'],
      entryDate: DateTime.fromMillisecondsSinceEpoch(map['entry_date']),
      exitDate: map['exit_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['exit_date'])
          : null,
      notes: map['notes'] ?? '',
    );
  }

  // Create a copy of this StayRecord with modified fields
  StayRecord copyWith({
    int? id,
    DateTime? entryDate,
    DateTime? exitDate,
    String? notes,
  }) {
    return StayRecord(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate ?? this.exitDate,
      notes: notes ?? this.notes,
    );
  }
}

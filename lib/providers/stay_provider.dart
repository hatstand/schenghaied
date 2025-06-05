// filepath: /home/john/code/schengen/lib/providers/stay_provider.dart
import 'package:flutter/foundation.dart';
import 'package:schengen/models/stay_record.dart';
import 'package:schengen/models/schengen_calculator.dart';
import 'package:schengen/services/database_service.dart';
import 'package:time_machine/time_machine.dart';

class StayProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<StayRecord> _stays = [];
  bool _isLoading = false;

  // Getters
  List<StayRecord> get stays => _stays;
  bool get isLoading => _isLoading;
  bool get isCurrentlyInSchengen =>
      SchengenCalculator.isCurrentlyInSchengen(_stays);
  int get daysSpent => SchengenCalculator.calculateDaysSpent(_stays);
  int get daysRemaining => SchengenCalculator.calculateDaysRemaining(_stays);

  // Load all stay records from the database
  Future<void> loadStays() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stays = await _databaseService.getAllStayRecords();
    } catch (e) {
      print('Error loading stays: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new stay record
  Future<void> addStay(StayRecord stay) async {
    try {
      final id = await _databaseService.insertStayRecord(stay);
      _stays.add(stay.copyWith(id: id));
      _stays.sort(
        (a, b) => b.entryDate.compareTo(a.entryDate),
      ); // Sort by newest first
      notifyListeners();
    } catch (e) {
      print('Error adding stay: $e');
    }
  }

  // Update an existing stay record
  Future<void> updateStay(StayRecord stay) async {
    try {
      await _databaseService.updateStayRecord(stay);
      final index = _stays.indexWhere((s) => s.id == stay.id);
      if (index != -1) {
        _stays[index] = stay;
        _stays.sort((a, b) => b.entryDate.compareTo(a.entryDate)); // Re-sort
        notifyListeners();
      }
    } catch (e) {
      print('Error updating stay: $e');
    }
  }

  // Delete a stay record
  Future<void> deleteStay(int id) async {
    try {
      await _databaseService.deleteStayRecord(id);
      _stays.removeWhere((stay) => stay.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting stay: $e');
    }
  }

  // Record exit from Schengen for the current stay
  Future<void> recordExit(LocalDate exitDate) async {
    if (!isCurrentlyInSchengen) return;

    try {
      final currentStay = SchengenCalculator.getMostRecentStay(_stays);
      if (currentStay != null && currentStay.exitDate == null) {
        final updatedStay = currentStay.copyWith(exitDate: exitDate);
        await updateStay(updatedStay);
      }
    } catch (e) {
      print('Error recording exit: $e');
    }
  }

  // Record exit from Schengen using DateTime (for backward compatibility)
  Future<void> recordExitDateTime(DateTime exitDateTime) async {
    recordExit(LocalDate.dateTime(exitDateTime));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schengen/models/stay_record.dart';
import 'package:schengen/providers/stay_provider.dart';
import 'package:intl/intl.dart';
import 'package:time_machine/time_machine.dart';

class StayDetailsScreen extends StatefulWidget {
  final StayRecord stay;

  const StayDetailsScreen({super.key, required this.stay});

  @override
  State<StayDetailsScreen> createState() => _StayDetailsScreenState();
}

class _StayDetailsScreenState extends State<StayDetailsScreen> {
  late StayRecord _stay;
  late TextEditingController _notesController;
  late LocalDate _entryDate;
  late LocalDate? _exitDate;

  @override
  void initState() {
    super.initState();
    _stay = widget.stay;
    _notesController = TextEditingController(text: _stay.notes);
    _entryDate = _stay.entryDate;
    _exitDate = _stay.exitDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stay Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stay Duration',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_stay.durationInDays} days',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Status',
                      _stay.isOngoing ? 'Ongoing stay' : 'Completed stay',
                    ),
                  ],
                ),
              ),
            ),

            // Entry Date Section
            _buildDateField(
              title: 'Entry Date',
              date: _entryDate,
              onTap: () => _selectDate(context, true),
            ),

            const SizedBox(height: 16),

            // Exit Date Section
            _buildDateField(
              title: 'Exit Date',
              date: _exitDate,
              onTap: () => _selectDate(context, false),
              allowNull: true,
            ),

            const SizedBox(height: 24),

            // Notes Section
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add notes about your stay',
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String title,
    required LocalDate? date,
    required VoidCallback onTap,
    bool allowNull = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allowNull && date != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _exitDate = null;
                        });
                      },
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
            child: Text(
              date != null
                  ? DateFormat('MMMM d, yyyy').format(
                      DateTime(date.year, date.monthOfYear, date.dayOfMonth),
                    )
                  : 'Not set',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isEntryDate) async {
    // Convert LocalDate to DateTime for the date picker
    final DateTime initialDateTime = isEntryDate
        ? DateTime(
            _entryDate.year,
            _entryDate.monthOfYear,
            _entryDate.dayOfMonth,
          )
        : (_exitDate != null
              ? DateTime(
                  _exitDate!.year,
                  _exitDate!.monthOfYear,
                  _exitDate!.dayOfMonth,
                )
              : DateTime.now());

    // Convert entry date to DateTime for the firstDate parameter
    final DateTime firstDateParam = isEntryDate
        ? DateTime(2000)
        : DateTime(
            _entryDate.year,
            _entryDate.monthOfYear,
            _entryDate.dayOfMonth,
          );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: firstDateParam,
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isEntryDate) {
          // Convert picked DateTime to LocalDate
          _entryDate = LocalDate.dateTime(picked);

          // Reset exit date if it's before the new entry date
          if (_exitDate != null) {
            if (_exitDate! < _entryDate) {
              _exitDate = null;
            }
          }
        } else {
          // Convert picked DateTime to LocalDate
          _exitDate = LocalDate.dateTime(picked);
        }
      });
    }
  }

  void _saveChanges() {
    // Validate data
    LocalDate today = LocalDate.today();
    if (_entryDate > today) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry date cannot be in the future'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_exitDate != null && _exitDate! < _entryDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exit date cannot be before entry date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update the stay record
    final updatedStay = _stay.copyWith(
      entryDate: _entryDate,
      exitDate: _exitDate,
      notes: _notesController.text.trim(),
    );

    // Save via provider
    Provider.of<StayProvider>(context, listen: false).updateStay(updatedStay);

    // Show success message and go back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stay updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true); // Return true to indicate successful update
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stay'),
        content: const Text(
          'Are you sure you want to delete this stay record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              // Delete the stay and go back
              Provider.of<StayProvider>(
                context,
                listen: false,
              ).deleteStay(_stay.id!);
              Navigator.of(context).pop(); // Close dialog

              // Return true and show confirmation message
              Navigator.of(
                context,
              ).pop(true); // Go back to previous screen with result

              // Show confirmation message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stay deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

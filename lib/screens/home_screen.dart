import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schengen/providers/stay_provider.dart';
import 'package:schengen/screens/add_stay_screen.dart';
import 'package:schengen/screens/stay_details_screen.dart';
import 'package:schengen/models/stay_record.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load stays when screen initializes
    Future.microtask(
      () => Provider.of<StayProvider>(context, listen: false).loadStays(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schengen Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Consumer<StayProvider>(
        builder: (context, stayProvider, child) {
          if (stayProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Status Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          'Current Status:',
                          stayProvider.isCurrentlyInSchengen
                              ? 'In Schengen Zone'
                              : 'Outside Schengen Zone',
                          stayProvider.isCurrentlyInSchengen
                              ? Colors.green
                              : Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          'Days Used (last 180 days):',
                          '${stayProvider.daysSpent} / 90 days',
                          stayProvider.daysSpent > 80
                              ? Colors.red
                              : stayProvider.daysSpent > 60
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          'Days Remaining:',
                          '${stayProvider.daysRemaining} days',
                          stayProvider.daysRemaining < 10
                              ? Colors.red
                              : stayProvider.daysRemaining < 30
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Title for stay list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Travel History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (stayProvider.isCurrentlyInSchengen)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Record Exit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showExitDialog(context),
                      ),
                  ],
                ),
              ),

              // Stay list
              Expanded(
                child: stayProvider.stays.isEmpty
                    ? const Center(
                        child: Text(
                          'No stays recorded yet. Add your first stay!',
                        ),
                      )
                    : ListView.builder(
                        itemCount: stayProvider.stays.length,
                        itemBuilder: (context, index) {
                          final stay = stayProvider.stays[index];
                          return _buildStayCard(context, stay);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddStayScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStayCard(BuildContext context, StayRecord stay) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          '${stay.formattedEntryDate} - ${stay.formattedExitDate}',
          style: TextStyle(
            fontWeight: stay.isOngoing ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${stay.durationInDays} days' +
              (stay.notes.isNotEmpty ? ' • ${stay.notes}' : ''),
        ),
        trailing: stay.isOngoing
            ? const Icon(Icons.circle, color: Colors.green)
            : Text('${stay.durationInDays} days'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StayDetailsScreen(stay: stay),
            ),
          );
        },
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final stayProvider = Provider.of<StayProvider>(context, listen: false);
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Exit from Schengen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('When did you exit the Schengen zone?'),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  selectedDate = date;
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Exit Date',
                ),
                child: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              stayProvider.recordExit(selectedDate);
              Navigator.of(context).pop();
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

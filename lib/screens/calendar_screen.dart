import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schengen/models/stay_record.dart';
import 'package:schengen/providers/stay_provider.dart';
import 'package:schengen/screens/add_stay_screen.dart';
import 'package:schengen/screens/stay_details_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isRangeSelectionMode = false;
  late CalendarFormat _calendarFormat;
  late Map<DateTime, List<StayRecord>> _events;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _events = {};

    // Load data when screen initializes if needed
    Future.microtask(() {
      final stayProvider = Provider.of<StayProvider>(context, listen: false);
      if (stayProvider.stays.isEmpty) {
        stayProvider.loadStays();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _generateEventsMap();
  }

  void _generateEventsMap() {
    final stayProvider = Provider.of<StayProvider>(context, listen: false);
    final Map<DateTime, List<StayRecord>> eventsMap = {};

    for (var stay in stayProvider.stays) {
      DateTime date = DateTime(
        stay.entryDate.year,
        stay.entryDate.month,
        stay.entryDate.day,
      );
      DateTime endDate = stay.exitDate != null
          ? DateTime(
              stay.exitDate!.year,
              stay.exitDate!.month,
              stay.exitDate!.day,
            )
          : DateTime.now();

      // Mark each day of the stay
      for (
        var d = date;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        final normalizedDate = DateTime(d.year, d.month, d.day);
        if (eventsMap[normalizedDate] == null) {
          eventsMap[normalizedDate] = [];
        }
        eventsMap[normalizedDate]!.add(stay);
      }
    }

    setState(() {
      _events = eventsMap;
    });
  }

  Color _getMarkerColor(List<StayRecord>? stays) {
    if (stays == null || stays.isEmpty) return Colors.transparent;
    return Colors.green.shade800; // For days in the Schengen zone
  }

  List<StayRecord> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _events[normalizedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRangeSelectionMode ? 'Select Date Range' : 'Schengen Calendar',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(
              _isRangeSelectionMode ? Icons.calendar_today : Icons.date_range,
            ),
            tooltip: _isRangeSelectionMode
                ? 'Switch to single date mode'
                : 'Switch to date range mode',
            onPressed: () {
              setState(() {
                _isRangeSelectionMode = !_isRangeSelectionMode;
                // Reset range selection when toggling modes
                if (!_isRangeSelectionMode) {
                  _rangeStart = null;
                  _rangeEnd = null;
                }
              });

              // Show instructions when entering range selection mode
              if (_isRangeSelectionMode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Select first day (entry date) then last day (exit date) of your stay',
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewStay(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<StayProvider>(
        builder: (context, stayProvider, child) {
          if (stayProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Calendar Widget
              TableCalendar(
                firstDay: DateTime.now().subtract(
                  const Duration(days: 365 * 2),
                ), // 2 years back
                lastDay: DateTime.now().add(
                  const Duration(days: 365),
                ), // 1 year ahead
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rangeSelectionMode: _isRangeSelectionMode
                    ? RangeSelectionMode.enforced
                    : RangeSelectionMode.disabled,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  markersMaxCount: 1,
                  markerDecoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  rangeStartDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getMarkerColor(
                              events as List<StayRecord>?,
                            ).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (_isRangeSelectionMode) {
                    setState(() {
                      if (_rangeStart == null ||
                          (_rangeStart != null && _rangeEnd != null)) {
                        _rangeStart = selectedDay;
                        _rangeEnd = null;
                      } else if (_rangeStart!.isBefore(selectedDay)) {
                        _rangeEnd = selectedDay;
                        // Once range is complete, add a stay
                        _addStayWithDateRange();
                      } else {
                        // If the selected end date is before the start date, swap them
                        _rangeEnd = _rangeStart;
                        _rangeStart = selectedDay;
                        // Once range is complete, add a stay
                        _addStayWithDateRange();
                      }
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  } else {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showStaysForSelectedDay(selectedDay);
                  }
                },
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _rangeStart = start;
                    _rangeEnd = end;
                    _focusedDay = focusedDay;
                  });

                  if (start != null && end != null) {
                    _addStayWithDateRange();
                  }
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green.shade800.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('In Schengen Zone'),
                    const SizedBox(width: 24),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Selected Day'),
                  ],
                ),
              ),

              // Range selection legend or usage hint
              if (_isRangeSelectionMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'First tap selects entry date, second tap selects exit date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Usage hint (shown in normal mode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap on any date to view, edit, or add stays',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Stats
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatWidget(
                          'Days Used',
                          '${stayProvider.daysSpent}/90',
                          stayProvider.daysSpent > 80
                              ? Colors.red
                              : stayProvider.daysSpent > 60
                              ? Colors.orange
                              : Colors.green,
                        ),
                        _buildStatWidget(
                          'Days Remaining',
                          '${stayProvider.daysRemaining}',
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatWidget(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showStaysForSelectedDay(DateTime selectedDay) {
    final events = _getEventsForDay(selectedDay);

    if (events.isEmpty) {
      // If no stays for this day, offer to add a new stay starting on this date
      _showAddStayOption(selectedDay);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DrayCurvedBottomSheet(
        title: 'Stays on ${DateFormat('MMM d, yyyy').format(selectedDay)}',
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: events.length,
          itemBuilder: (context, index) {
            final stay = events[index];
            return ListTile(
              title: Text(
                '${DateFormat('MMM d').format(stay.entryDate)} - ${stay.exitDate != null ? DateFormat('MMM d').format(stay.exitDate!) : 'Present'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(stay.notes.isNotEmpty ? stay.notes : 'No notes'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stay.durationInDays} days',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editStay(stay),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              onTap: () => _editStay(stay),
            );
          },
        ),
      ),
    );
  }

  /// Open the edit screen for a stay record
  Future<void> _editStay(StayRecord stay) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StayDetailsScreen(stay: stay)),
    );

    // If we returned from edit screen, refresh the events map
    // to reflect any changes in the stay records
    if (result != null) {
      setState(() {
        _generateEventsMap();
      });
    }
  }

  /// Open screen to add a new stay
  Future<void> _addNewStay() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStayScreen()),
    );

    // If we returned from add screen, refresh the events map
    if (result != null) {
      setState(() {
        _generateEventsMap();
      });
    }
  }

  /// Show a dialog offering to add a new stay starting on the selected date
  void _showAddStayOption(DateTime selectedDay) {
    // Don't offer to add stays in the future
    if (selectedDay.isAfter(DateTime.now())) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'No stays on ${DateFormat('MMM d, yyyy').format(selectedDay)}',
        ),
        content: const Text(
          'Would you like to add a new stay on this date? You can specify just the entry date or a complete date range.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addStayOnDate(selectedDay, null); // Only entry date
            },
            child: const Text('ENTRY ONLY'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _promptForDateRange(selectedDay);
            },
            child: const Text('DATE RANGE'),
          ),
        ],
      ),
    );
  }

  /// Navigate to the AddStayScreen with the selected date(s) pre-filled
  Future<void> _addStayOnDate(DateTime startDate, DateTime? endDate) async {
    // Use our AddStayScreen with initialEntryDate and optional initialExitDate
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddStayScreen(
          initialEntryDate: startDate,
          initialExitDate: endDate,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _generateEventsMap();
      });
    }
  }

  /// Show a dialog to select an exit date for the stay
  Future<void> _promptForDateRange(DateTime entryDate) async {
    DateTime? exitDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Exit Date'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Entry date: ${DateFormat('MMM d, yyyy').format(entryDate)}',
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          exitDate ?? entryDate.add(const Duration(days: 1)),
                      firstDate: entryDate.add(const Duration(days: 1)),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      setState(() {
                        exitDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Exit Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      exitDate != null
                          ? DateFormat('MMM d, yyyy').format(exitDate!)
                          : 'Select exit date',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: exitDate == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _addStayOnDate(entryDate, exitDate);
                      },
                child: const Text('CONTINUE'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Add a new stay with the selected date range
  void _addStayWithDateRange() {
    // Make sure we have both a start and end date selected
    if (_rangeStart == null || _rangeEnd == null) {
      return;
    }

    // Don't allow creating stays that end in the future
    if (_rangeEnd!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot create stays that end in the future'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to AddStayScreen with the selected date range
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddStayScreen(
              initialEntryDate: _rangeStart!,
              initialExitDate: _rangeEnd!,
            ),
          ),
        )
        .then((result) {
          if (result != null) {
            // Successfully added the stay, refresh events
            setState(() {
              _generateEventsMap();
              // Reset range selection mode
              _isRangeSelectionMode = false;
              _rangeStart = null;
              _rangeEnd = null;
            });
          }
        });
  }
}

class DrayCurvedBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const DrayCurvedBottomSheet({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Content
          child,
        ],
      ),
    );
  }
}

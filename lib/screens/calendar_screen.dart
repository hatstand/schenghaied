import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:schengen/models/stay_record.dart';
import 'package:schengen/providers/stay_provider.dart';
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
      DateTime date = DateTime(stay.entryDate.year, stay.entryDate.month, stay.entryDate.day);
      DateTime endDate = stay.exitDate != null 
          ? DateTime(stay.exitDate!.year, stay.exitDate!.month, stay.exitDate!.day)
          : DateTime.now();
      
      // Mark each day of the stay
      for (var d = date; !d.isAfter(endDate); d = d.add(const Duration(days: 1))) {
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
        title: const Text('Schengen Calendar'),
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
              // Calendar Widget
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365 * 2)), // 2 years back
                lastDay: DateTime.now().add(const Duration(days: 365)), // 1 year ahead
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
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
                            color: _getMarkerColor(events as List<StayRecord>?).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay; // update focused day when selecting a day
                  });
                  _showStaysForSelectedDay(selectedDay);
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
                  ],
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
    
    if (events.isEmpty) return;
    
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
              subtitle: Text(
                stay.notes.isNotEmpty ? stay.notes : 'No notes',
              ),
              trailing: Text(
                '${stay.durationInDays} days',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Content
          child,
        ],
      ),
    );
  }
}

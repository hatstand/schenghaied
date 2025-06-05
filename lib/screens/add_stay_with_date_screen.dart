import 'package:flutter/material.dart';
import 'package:schengen/screens/add_stay_screen.dart';

/// A helper widget that redirects to AddStayScreen with pre-filled date range
class AddStayWithDateScreen extends StatelessWidget {
  final DateTime initialEntryDate;
  final DateTime? initialExitDate;

  const AddStayWithDateScreen({
    super.key,
    required this.initialEntryDate,
    this.initialExitDate,
  });

  @override
  Widget build(BuildContext context) {
    return AddStayScreen(
      initialEntryDate: initialEntryDate,
      initialExitDate: initialExitDate,
    );
  }
}

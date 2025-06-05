import 'package:flutter/material.dart';
import 'package:schengen/screens/add_stay_screen.dart';

/// A helper widget that redirects to AddStayScreen with a pre-filled entry date
class AddStayWithDateScreen extends StatelessWidget {
  final DateTime initialEntryDate;

  const AddStayWithDateScreen({super.key, required this.initialEntryDate});

  @override
  Widget build(BuildContext context) {
    return AddStayScreen(initialEntryDate: initialEntryDate);
  }
}

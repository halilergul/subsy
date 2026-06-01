import 'package:flutter/material.dart';

/// Placeholder home screen. Real content (upcoming payments + monthly total)
/// is built in the `subscriptions-core` / `dashboard` features.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subsy')),
      body: const Center(
        child: Text('İskelet hazır — abonelikler yakında.'),
      ),
    );
  }
}

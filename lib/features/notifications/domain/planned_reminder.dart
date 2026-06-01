import 'package:flutter/foundation.dart';

/// A single reminder to be scheduled. `subscriptionId` doubles as the OS
/// notification id (stable, no collisions). `fireTime` is always in the future.
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.subscriptionId,
    required this.fireTime,
    required this.title,
    required this.body,
  });

  final int subscriptionId;
  final DateTime fireTime;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.subscriptionId == subscriptionId &&
      other.fireTime == fireTime &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(subscriptionId, fireTime, title, body);
}

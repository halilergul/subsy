import 'package:flutter/foundation.dart';

/// Reminder defaults (no magic numbers).
const int kDefaultLeadDays = 3;
const int kDefaultHour = 10;
const int kDefaultMinute = 0;
const int kMaxLeadDays = 7;

/// Global reminder settings (single record). `enabled` is only ever true once
/// notification permission has been granted.
@immutable
class NotificationSettings {
  const NotificationSettings({
    this.enabled = false,
    this.leadDays = kDefaultLeadDays,
    this.hour = kDefaultHour,
    this.minute = kDefaultMinute,
  });

  final bool enabled;
  final int leadDays;
  final int hour;
  final int minute;

  static const NotificationSettings defaults = NotificationSettings();

  NotificationSettings copyWith({bool? enabled, int? leadDays, int? hour, int? minute}) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      leadDays: leadDays ?? this.leadDays,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.enabled == enabled &&
      other.leadDays == leadDays &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, leadDays, hour, minute);
}

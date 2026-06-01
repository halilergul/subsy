import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';

/// Reminder settings: enable/disable, lead days, time of day. Saving persists
/// on-device and triggers rescheduling reactively.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _permissionDenied = false;

  Future<void> _toggle(NotificationSettings current, bool value) async {
    final controller = ref.read(notificationSettingsControllerProvider);
    final applied = await controller.setEnabled(current, value);
    if (!mounted) return;
    setState(() => _permissionDenied = value && !applied);
  }

  Future<void> _pickTime(NotificationSettings current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      await ref
          .read(notificationSettingsControllerProvider)
          .setTime(current, picked.hour, picked.minute);
    }
  }

  String _fmtTime(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Ayarlar yüklenemedi.')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hatırlatmalar'),
              subtitle: const Text('Yenilemeden önce yerel bildirim al (cihazında kalır).'),
              value: s.enabled,
              onChanged: (v) => _toggle(s, v),
            ),
            if (_permissionDenied)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bildirim izni kapalı. Hatırlatmaların çalışması için '
                        'sistem ayarlarından izin vermelisin.',
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _toggle(s, true),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            if (s.enabled) ...[
              const Divider(height: 32),
              Text('Kaç gün önce', style: theme.textTheme.titleSmall),
              Slider(
                value: s.leadDays.toDouble(),
                min: 0,
                max: kMaxLeadDays.toDouble(),
                divisions: kMaxLeadDays,
                label: '${s.leadDays} gün',
                onChanged: (v) => ref
                    .read(notificationSettingsControllerProvider)
                    .setLeadDays(s, v.round()),
              ),
              Text(
                s.leadDays == 0 ? 'Yenileme günü' : '${s.leadDays} gün önce',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Bildirim saati'),
                trailing: Text(
                  _fmtTime(s.hour, s.minute),
                  style: theme.textTheme.titleMedium,
                ),
                onTap: () => _pickTime(s),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

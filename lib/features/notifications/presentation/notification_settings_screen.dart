import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_text.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/shared/widgets/glass/ambient_background.dart';
import 'package:subsy/shared/widgets/glass/glass_buttons.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// Reminder settings: enable/disable, lead days, time of day. Saving persists
/// on-device and triggers rescheduling reactively. Liquid-Glass styled.
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
    final async = ref.watch(notificationSettingsProvider);
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight + 4;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: AppTokens.text,
            onTap: () => context.pop(),
          ),
        ),
        centerTitle: true,
        title: Text('Bildirimler', style: AppText.headline.copyWith(color: AppTokens.text)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70,
            child: IgnorePointer(
              child: DecoratedBox(decoration: BoxDecoration(gradient: AppTokens.topFade)),
            ),
          ),
          async.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppTokens.accentFg)),
            error: (_, _) => Center(
              child: Text('Ayarlar yüklenemedi.',
                  style: AppText.body.copyWith(color: AppTokens.muted)),
            ),
            data: (s) => _content(s, topInset),
          ),
        ],
      ),
    );
  }

  Widget _content(NotificationSettings s, double topInset) {
    return ListView(
      padding: EdgeInsets.fromLTRB(18, topInset, 18, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text('Bildirimler',
              style: AppText.largeTitle.copyWith(color: AppTokens.text)),
        ),
        GlassSurface(
          radius: 18,
          fill: GlassFill.strong,
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Hatırlatmalar',
                        style: AppText.body.copyWith(color: AppTokens.text)),
                    const SizedBox(height: 2),
                    Text('Yenilemeden önce yerel bildirim al (cihazında kalır).',
                        style: AppText.footnote.copyWith(color: AppTokens.muted)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: s.enabled,
                activeThumbColor: AppTokens.accentFg,
                onChanged: (v) => _toggle(s, v),
              ),
            ],
          ),
        ),
        if (_permissionDenied) ...[
          const SizedBox(height: 12),
          GlassSurface(
            radius: 16,
            fill: GlassFill.soft,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 20, color: AppTokens.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bildirim izni kapalı. Hatırlatmaların çalışması için sistem '
                    'ayarlarından izin vermelisin.',
                    style: AppText.footnote.copyWith(color: AppTokens.muted, height: 1.4),
                  ),
                ),
                TextButton(
                  onPressed: () => _toggle(s, true),
                  child: Text('Tekrar Dene',
                      style: AppText.subhead.copyWith(
                          color: AppTokens.accentFg, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
        if (s.enabled) ...[
          const SizedBox(height: 18),
          const _Label('Zamanlama'),
          const SizedBox(height: 10),
          GlassSurface(
            radius: 18,
            fill: GlassFill.strong,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kaç gün önce',
                        style: AppText.body.copyWith(color: AppTokens.text)),
                    Text(s.leadDays == 0 ? 'Yenileme günü' : '${s.leadDays} gün önce',
                        style: AppText.subhead.copyWith(color: AppTokens.accentFg)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTokens.accent,
                    inactiveTrackColor: AppTokens.fill,
                    thumbColor: AppTokens.accentSoft,
                    overlayColor: const Color.fromRGBO(199, 162, 86, 0.18),
                  ),
                  child: Slider(
                    value: s.leadDays.toDouble(),
                    min: 0,
                    max: kMaxLeadDays.toDouble(),
                    divisions: kMaxLeadDays,
                    label: '${s.leadDays} gün',
                    onChanged: (v) => ref
                        .read(notificationSettingsControllerProvider)
                        .setLeadDays(s, v.round()),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _pickTime(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 20, color: AppTokens.muted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Bildirim saati',
                                style: AppText.body.copyWith(color: AppTokens.text)),
                          ),
                          Text(_fmtTime(s.hour, s.minute),
                              style: AppText.body.copyWith(
                                  color: AppTokens.text, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18, color: AppTokens.tertiary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        const _Label('Hakkında'),
        const SizedBox(height: 10),
        GlassSurface(
          radius: 18,
          fill: GlassFill.strong,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(Routes.onboarding),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTokens.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.slideshow_outlined,
                          size: 18, color: AppTokens.accentFg),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text('Tanıtımı Tekrar Göster',
                          style: AppText.body.copyWith(color: AppTokens.text)),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppTokens.tertiary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: AppText.footnote.copyWith(
                color: AppTokens.muted, fontWeight: FontWeight.w600)),
      );
}

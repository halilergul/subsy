import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/dashboard/domain/monthly_normalizer.dart';
import 'package:subsy/features/dashboard/domain/relative_date_label.dart';
import 'package:subsy/features/dashboard/domain/renewal_calculator.dart';
import 'package:subsy/features/dashboard/presentation/widgets/glass_renewal_list.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/add_form_sheet.dart';
import 'package:subsy/shared/constants/category_style.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass/glass_sheet.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// Opens the Liquid-Glass subscription detail sheet.
Future<void> showSubscriptionDetailSheet(BuildContext context, Subscription sub) {
  return showGlassSheet(context, builder: (_) => GlassDetailSheet(subscription: sub));
}

/// Subscription detail as a glass sheet: a category-tinted hero + info rows +
/// edit / delete actions.
class GlassDetailSheet extends ConsumerWidget {
  const GlassDetailSheet({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = subscription;
    final cat = s.category;
    final color = categoryColor(cat);
    final now = DateTime.now();
    final monthly = monthlyAmount(s);
    final yearly = monthly * 12;
    final renewal = effectiveNextRenewal(s, now);
    final when = relativeDateLabel(renewal, now);

    final reminders = ref.watch(notificationSettingsProvider).asData?.value;
    final String reminderDetail;
    if (reminders == null || !reminders.enabled) {
      reminderDetail = 'Kapalı';
    } else {
      reminderDetail =
          reminders.leadDays == 0 ? 'Yenileme günü' : '${reminders.leadDays} gün önce';
    }

    return GlassSheet(
      title: s.name,
      subtitle: periodLabel(s.billingPeriod),
      onClose: () => Navigator.of(context).pop(),
      contentHeight: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Category-tinted glass hero (lighter than the opaque sheet so it
          // reads as a raised card).
          GlassSurface(
            radius: 26,
            fill: GlassFill.soft,
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                  child: Column(
                    children: [
                      BrandAvatar(
                        serviceKey: s.serviceKey,
                        fallbackName: s.name,
                        size: 74,
                        circle: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(formatMoneyTr(s.amount, s.currency),
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -1,
                                  color: AppTokens.text)),
                          Text(' /${periodLabel(s.billingPeriod).toLowerCase()}',
                              style: const TextStyle(fontSize: 15, color: AppTokens.muted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatusPill(),
                          const SizedBox(width: 9),
                          _CategoryChip(color: color, label: categoryLabel(cat)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassSurface(
            radius: 20,
            fill: GlassFill.soft,
            child: Column(
              children: [
                _InfoRow(
                  label: 'Sonraki ödeme',
                  valueWidget: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: _dateLabel(renewal),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.text)),
                    TextSpan(
                        text: ' · $when',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.accentFg)),
                  ])),
                ),
                _InfoRow(label: 'Aylık maliyet', value: formatMoneyTr(monthly, s.currency)),
                _InfoRow(label: 'Yıllık maliyet', value: formatMoneyTr(yearly, s.currency)),
                _InfoRow(label: 'Bildirim', value: reminderDetail, last: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Düzenle',
                  color: AppTokens.text,
                  glass: true,
                  onTap: () => _edit(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Sil',
                  color: AppTokens.red,
                  glass: false,
                  onTap: () => _confirmDelete(context, ref),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Future<void> _edit(BuildContext context) async {
    final navigator = Navigator.of(context);
    final saved = await showAddFormSheet(context, editing: subscription);
    if (saved == true) navigator.pop();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface,
        title: const Text('Aboneliği Sil', style: TextStyle(color: AppTokens.text)),
        content: Text('${subscription.name} silinsin mi? Bu işlem geri alınamaz.',
            style: const TextStyle(color: AppTokens.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç', style: TextStyle(color: AppTokens.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil', style: TextStyle(color: AppTokens.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deleteSubscriptionProvider)(subscription.id!);
    navigator.pop();
    if (context.mounted) showGlassToast(context, 'Abonelik silindi');
  }
}

class _StatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppTokens.green.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTokens.green),
          ),
          const SizedBox(width: 6),
          const Text('Aktif',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppTokens.green)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget, this.last = false});
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppTokens.hair, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: AppTokens.muted)),
          valueWidget ??
              Text(value ?? '',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.text)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.glass,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool glass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (glass) {
      return GlassSurface(
        radius: 999,
        fill: GlassFill.soft,
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(label,
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: color)),
          ),
        ),
      );
    }
    final br = BorderRadius.circular(999);
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(label,
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: color)),
          ),
        ),
      ),
    );
  }
}
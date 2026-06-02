import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/currency/presentation/widgets/converted_amount_preview.dart';
import 'package:subsy/features/dashboard/domain/monthly_normalizer.dart';
import 'package:subsy/features/dashboard/domain/relative_date_label.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/add_form_sheet.dart';
import 'package:subsy/shared/constants/category_style.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass_app_bar.dart';

/// Read-only subscription detail with a category-tinted gradient hero, the
/// amount breakdown, metadata, and edit/delete. Edit opens the form sheet;
/// delete confirms then removes and pops back to the dashboard.
class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({super.key, required this.subscription});

  final Subscription subscription;

  static const _monthsShort = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  static const _periodLower = {
    'weekly': 'haftalık',
    'monthly': 'aylık',
    'yearly': 'yıllık',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = subscription;
    final now = DateTime.now();
    final payment = UpcomingPayment.from(s, now);
    final monthly = monthlyAmount(s);
    final yearly = monthly * 12;
    final catColor = categoryColor(s.category);
    final periodLabel = _periodLower[s.billingPeriod.name] ?? s.billingPeriod.name;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        context,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppTokens.text),
              label: const Text('Düzenle', style: TextStyle(color: AppTokens.text, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: AppTokens.fill,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, glassTopInset(context), 20, 32),
        children: [
          _hero(s, catColor, periodLabel),
          const SizedBox(height: 20),
          _card([
            _InfoRow(
              label: 'Tutar',
              valueWidget: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTokens.text),
                  children: [
                    TextSpan(text: formatMoneyTr(s.amount, s.currency)),
                    TextSpan(
                      text: ' / $periodLabel',
                      style: const TextStyle(fontSize: 13, color: AppTokens.muted, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
            _InfoRow(
              label: 'Sonraki ödeme',
              valueWidget: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTokens.text),
                  children: [
                    TextSpan(text: _shortDate(payment.effectiveRenewal)),
                    TextSpan(
                      text: ' · ${relativeDateLabel(payment.effectiveRenewal, now)}',
                      style: const TextStyle(color: AppTokens.accentFg, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            _InfoRow(label: 'Aylık maliyet', value: formatMoneyTr(monthly, s.currency)),
            _InfoRow(label: 'Yıllık maliyet', value: formatMoneyTr(yearly, s.currency), last: true),
          ]),
          // Premium ≈ converted monthly cost (gated + offline-safe internally).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ConvertedAmountPreview(amount: monthly, from: s.currency),
          ),
          const SizedBox(height: 14),
          _card([
            _InfoRow(
              label: 'Kategori',
              valueWidget: _categoryPill(s, catColor),
            ),
            _InfoRow(label: 'Para birimi', value: '${currencySymbol(s.currency)} ${s.currency.code}'),
            _NotificationRow(),
          ]),
          if ((s.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            _card([
              _InfoRow(label: 'Not', value: s.notes!, last: true),
            ]),
          ],
          const SizedBox(height: 24),
          _deleteButton(context, ref),
        ],
      ),
    );
  }

  Widget _hero(Subscription s, Color catColor, String periodLabel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [catColor.withValues(alpha: 0.34), catColor.withValues(alpha: 0.08), AppTokens.surface],
            stops: const [0, 0.6, 1],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: catColor.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          children: [
            BrandAvatar(serviceKey: s.serviceKey, fallbackName: s.name, size: 76, circle: true),
            const SizedBox(height: 16),
            Text(
              s.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: AppTokens.text, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTokens.green.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Aktif',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.green)),
                ),
                const SizedBox(width: 9),
                Text(_periodTitle(periodLabel),
                    style: const TextStyle(fontSize: 13, color: AppTokens.muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryPill(Subscription s, Color catColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(kCategoryLabels[s.category]!,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: catColor)),
        ],
      ),
    );
  }

  Widget _card(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTokens.hair, width: 0.5),
        ),
        child: Column(children: rows),
      );

  Widget _deleteButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppTokens.red.withValues(alpha: 0.1),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTokens.red.withValues(alpha: 0.2), width: 0.5),
        ),
        child: InkWell(
          onTap: () => _confirmDelete(context, ref),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppTokens.red),
              SizedBox(width: 8),
              Text('Aboneliği sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.red)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await showAddFormSheet(context, editing: subscription);
    if (saved == true && context.mounted) context.pop();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aboneliği sil?'),
        content: const Text('Bu abonelik kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true || subscription.id == null) return;
    await ref.read(deleteSubscriptionProvider)(subscription.id!);
    if (context.mounted) context.pop();
  }

  String _shortDate(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]}';

  String _periodTitle(String lower) => '${lower[0].toUpperCase()}${lower.substring(1)}';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppTokens.hair, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15.5, color: AppTokens.muted)),
          const Spacer(),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(
                    value ?? '',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTokens.text),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Bildirim" row reflecting the current reminder settings.
class _NotificationRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider).asData?.value;
    final String value;
    if (settings == null || !settings.enabled) {
      value = 'Kapalı';
    } else {
      final t = '${settings.hour.toString().padLeft(2, '0')}:${settings.minute.toString().padLeft(2, '0')}';
      value = settings.leadDays == 0 ? 'Yenileme günü · $t' : '${settings.leadDays} gün önce · $t';
    }
    return _InfoRow(label: 'Bildirim', value: value, last: true);
  }
}

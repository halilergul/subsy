import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/subscription_import/domain/recognized_draft.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/currency_selector.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/period_selector.dart';
import 'package:subsy/shared/constants/category_style.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// An editable recognized-subscription card for the review screen (US2).
/// Every field is editable; low-confidence fields get a "kontrol et" hint and
/// possible duplicates show a badge. Pushes edits up via [onChanged].
class ImportDraftCard extends StatefulWidget {
  const ImportDraftCard({
    super.key,
    required this.draft,
    required this.error,
    required this.onChanged,
    required this.onDiscard,
  });

  final RecognizedDraft draft;
  final String? error;
  final ValueChanged<RecognizedDraft> onChanged;
  final VoidCallback onDiscard;

  @override
  State<ImportDraftCard> createState() => _ImportDraftCardState();
}

class _ImportDraftCardState extends State<ImportDraftCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.draft.name);
    _amountCtrl = TextEditingController(
      text: widget.draft.amount == null ? '' : _formatAmount(widget.draft.amount!),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  RecognizedDraft get _d => widget.draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _d.confidence;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        radius: 18,
        fill: GlassFill.soft,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BrandAvatar(serviceKey: _d.serviceKey, fallbackName: _d.name, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Servis',
                      isDense: true,
                    ),
                    onChanged: (v) => widget.onChanged(_d.copyWith(name: v)),
                  ),
                ),
                IconButton(
                  tooltip: 'Vazgeç',
                  icon: const Icon(Icons.close),
                  onPressed: widget.onDiscard,
                ),
              ],
            ),
            if (_d.duplicateOf != null) ...[
              const SizedBox(height: 8),
              _Badge(
                icon: Icons.copy_all_outlined,
                color: AppTokens.amber,
                text: 'Zaten ekli olabilir: ${_d.duplicateOf}',
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Tutar',
                      isDense: true,
                      helperText: c.amountRecognized ? null : 'kontrol et',
                    ),
                    onChanged: (v) =>
                        widget.onChanged(_d.copyWith(amount: _parseAmount(v))),
                  ),
                ),
                const SizedBox(width: 12),
                CurrencySelector(
                  value: _d.currency ?? Currency.tryl,
                  onChanged: (v) => widget.onChanged(_d.copyWith(currency: v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PeriodSelector(
              value: _d.billingPeriod ?? BillingPeriod.monthly,
              onChanged: (v) => widget.onChanged(_d.copyWith(billingPeriod: v)),
            ),
            const SizedBox(height: 12),
            _DateRow(
              date: _d.nextRenewalDate,
              recognized: c.dateRecognized,
              onPick: _pickDate,
            ),
            const SizedBox(height: 8),
            _CategoryDropdown(
              value: _d.category,
              onChanged: (v) => widget.onChanged(
                v == null ? _d.copyWith(clearCategory: true) : _d.copyWith(category: v),
              ),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 8),
              Text(widget.error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _d.nextRenewalDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) widget.onChanged(_d.copyWith(nextRenewalDate: picked));
  }

  static double? _parseAmount(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  static String _formatAmount(double a) =>
      a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toString();
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.recognized, required this.onPick});

  final DateTime? date;
  final bool recognized;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? 'Tarih seç'
        : '${date!.day.toString().padLeft(2, '0')}.'
            '${date!.month.toString().padLeft(2, '0')}.${date!.year}';
    return Row(
      children: [
        const Icon(Icons.event_outlined, size: 20),
        const SizedBox(width: 8),
        const Text('Sonraki ödeme'),
        const Spacer(),
        TextButton(onPressed: onPick, child: Text(label)),
        if (date == null || !recognized)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.error_outline, size: 18, color: Colors.amber),
          ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final SubscriptionCategory? value;
  final ValueChanged<SubscriptionCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.category_outlined, size: 20),
        const SizedBox(width: 8),
        const Text('Kategori'),
        const Spacer(),
        DropdownButton<SubscriptionCategory?>(
          value: value,
          hint: const Text('Otomatik'),
          underline: const SizedBox.shrink(),
          items: [
            const DropdownMenuItem(value: null, child: Text('Otomatik')),
            for (final cat in SubscriptionCategory.values)
              DropdownMenuItem(
                value: cat,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: categoryColor(cat),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(categoryLabel(cat)),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}

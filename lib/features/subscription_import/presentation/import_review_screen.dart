import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/subscription_import/application/import_controller.dart';
import 'package:subsy/features/subscription_import/domain/recognized_draft.dart';
import 'package:subsy/features/subscription_import/presentation/widgets/import_draft_card.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// Hybrid review (US2): a selectable list of recognized drafts. Each row has a
/// checkbox (possible duplicates start unchecked) and expands on tap into the
/// full editor. Only checked drafts are saved via "Seçilenleri kaydet".
class ImportReviewView extends StatefulWidget {
  const ImportReviewView({
    super.key,
    required this.state,
    required this.onChanged,
    required this.onDiscard,
    required this.onToggleSelected,
    required this.onToggleAll,
    required this.onConfirm,
  });

  final ImportState state;
  final void Function(int index, RecognizedDraft draft) onChanged;
  final void Function(int index) onDiscard;
  final void Function(int index) onToggleSelected;
  final void Function(bool value) onToggleAll;
  final VoidCallback onConfirm;

  @override
  State<ImportReviewView> createState() => _ImportReviewViewState();
}

class _ImportReviewViewState extends State<ImportReviewView> {
  final Set<int> _expanded = {};

  static const _periodLabels = {
    BillingPeriod.weekly: 'Haftalık',
    BillingPeriod.monthly: 'Aylık',
    BillingPeriod.yearly: 'Yıllık',
  };

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final saving = s.status == ImportStatus.saving;
    final count = s.drafts.length;

    return Column(
      children: [
        _header(count, s.allSelected),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: count,
            itemBuilder: (context, index) {
              final selected = index < s.selected.length && s.selected[index];
              final error = index < s.draftErrors.length
                  ? s.draftErrors[index]
                  : null;
              if (_expanded.contains(index)) {
                return ImportDraftCard(
                  key: ValueKey('draft_$index'),
                  draft: s.drafts[index],
                  error: error,
                  onChanged: (d) => widget.onChanged(index, d),
                  onDiscard: () {
                    setState(() => _expanded.remove(index));
                    widget.onDiscard(index);
                  },
                );
              }
              return _ResultRow(
                draft: s.drafts[index],
                selected: selected,
                error: error,
                periodLabel: _periodLabels[s.drafts[index].billingPeriod] ?? '',
                onToggle: () => widget.onToggleSelected(index),
                onTapEdit: () => setState(() => _expanded.add(index)),
              );
            },
          ),
        ),
        _footer(saving, s.selectedCount),
      ],
    );
  }

  Widget _header(int count, bool allSelected) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count abonelik bulundu',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTokens.text,
              ),
            ),
          ),
          TextButton(
            onPressed: count == 0
                ? null
                : () => widget.onToggleAll(!allSelected),
            child: Text(
              allSelected ? 'Hiçbiri' : 'Tümünü seç',
              style: const TextStyle(
                color: AppTokens.accentFg,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(bool saving, int selectedCount) {
    final enabled = !saving && selectedCount > 0;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onConfirm : null,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              decoration: BoxDecoration(
                gradient: enabled ? AppTokens.accentGradient : null,
                color: enabled ? null : AppTokens.fill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTokens.onAccent,
                        ),
                      )
                    : Text(
                        'Seçilenleri Kaydet ($selectedCount)',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? AppTokens.onAccent
                              : AppTokens.tertiary,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapsed selectable row: checkbox + logo + name/amount + flags. Tapping the
/// body (not the checkbox) expands into the editor.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.draft,
    required this.selected,
    required this.error,
    required this.periodLabel,
    required this.onToggle,
    required this.onTapEdit,
  });

  final RecognizedDraft draft;
  final bool selected;
  final String? error;
  final String periodLabel;
  final VoidCallback onToggle;
  final VoidCallback onTapEdit;

  @override
  Widget build(BuildContext context) {
    final amount = draft.amount;
    final amountText = amount == null || draft.currency == null
        ? 'Tutar eksik'
        : '${formatMoneyTr(amount, draft.currency!)} · $periodLabel';
    final needsCheck = !draft.isComplete;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        radius: 16,
        fill: GlassFill.soft,
        child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppTokens.green : Colors.transparent,
                  border: selected
                      ? null
                      : Border.all(color: AppTokens.hair2, width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),
          ),
          BrandAvatar(
            serviceKey: draft.serviceKey,
            fallbackName: draft.name,
            size: 40,
            circle: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.name.isEmpty ? 'İsimsiz' : draft.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amountText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTokens.muted,
                      ),
                    ),
                    if (draft.duplicateOf != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Zaten ekli olabilir: ${draft.duplicateOf}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.amberText,
                          ),
                        ),
                      )
                    else if (needsCheck)
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 12,
                              color: AppTokens.amber,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'kontrol et',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTokens.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTokens.tertiary,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

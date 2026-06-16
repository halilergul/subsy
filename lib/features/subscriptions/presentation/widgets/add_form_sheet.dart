import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/currency/presentation/widgets/converted_amount_preview.dart';
import 'package:subsy/features/subscriptions/application/subscription_form_controller.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog_entry.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass_app_bar.dart';
import 'package:subsy/shared/constants/category_style.dart';

/// Turkish category labels (shared with the legacy form screen).
const Map<SubscriptionCategory, String> kCategoryLabels = {
  SubscriptionCategory.streaming: 'Yayın',
  SubscriptionCategory.music: 'Müzik',
  SubscriptionCategory.cloud: 'Bulut',
  SubscriptionCategory.ai: 'Yapay zeka',
  SubscriptionCategory.productivity: 'Üretkenlik',
  SubscriptionCategory.gaming: 'Oyun',
  SubscriptionCategory.education: 'Eğitim',
  SubscriptionCategory.health: 'Sağlık',
  SubscriptionCategory.books: 'Kitap',
  SubscriptionCategory.security: 'Güvenlik',
  SubscriptionCategory.connectivity: 'İnternet & Mobil',
  SubscriptionCategory.shopping: 'Alışveriş',
  SubscriptionCategory.other: 'Diğer',
};

/// Opens the subscription detail form as a keyboard-aware bottom sheet.
/// Returns true when saved. For ADD: pass [entry] (picked brand; null = custom)
/// and optionally [initialName]. For EDIT: pass [editing].
Future<bool?> showAddFormSheet(
  BuildContext context, {
  BrandCatalogEntry? entry,
  String? initialName,
  Subscription? editing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppTokens.scrim,
    builder: (ctx) => AddFormSheetShell(
      child: AddSubscriptionForm(
        editing: editing,
        entry: entry,
        initialName: initialName,
        onClose: () => Navigator.of(ctx).pop(false),
        onSaved: () => Navigator.of(ctx).pop(true),
      ),
    ),
  );
}

/// Keyboard-aware sheet container (grabber + rounded top + grows with the
/// keyboard) that hosts an [AddSubscriptionForm]. Reused by the standalone edit
/// sheet and the add-flow's form step.
class AddFormSheetShell extends StatelessWidget {
  const AddFormSheetShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppTokens.sheetSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: AppTokens.glassInnerHighlight, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 9, bottom: 4),
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTokens.grabber,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Flexible(child: child),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

/// The subscription detail form content (no sheet chrome of its own). For ADD:
/// pass [entry]/[initialName] and [onBack] to return to the picker step. For
/// EDIT: pass [editing]. Calls [onSaved] once a save succeeds.
class AddSubscriptionForm extends ConsumerStatefulWidget {
  const AddSubscriptionForm({
    super.key,
    this.entry,
    this.initialName,
    this.editing,
    this.onBack,
    required this.onClose,
    required this.onSaved,
  });

  final BrandCatalogEntry? entry;
  final String? initialName;
  final Subscription? editing;
  final VoidCallback? onBack;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  @override
  ConsumerState<AddSubscriptionForm> createState() =>
      _AddSubscriptionFormState();
}

class _AddSubscriptionFormState extends ConsumerState<AddSubscriptionForm> {
  late final SubscriptionFormController _controller;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;

  /// Show an editable name field for custom-add and all edits; hide it for a
  /// picked brand (the name is fixed by the brand preview header).
  bool get _showNameField => widget.editing != null || widget.entry == null;

  String? get _previewServiceKey =>
      widget.editing?.serviceKey ?? widget.entry?.serviceKey;

  @override
  void initState() {
    super.initState();
    _controller = SubscriptionFormController(
      add: ref.read(addSubscriptionProvider),
      update: ref.read(updateSubscriptionProvider),
      delete: ref.read(deleteSubscriptionProvider),
      now: DateTime.now(),
      editing: widget.editing,
    );
    final entry = widget.entry;
    if (widget.editing == null && entry != null) {
      _controller.setName(entry.displayName);
      _controller.setCategory(entry.defaultCategory);
    } else if (widget.editing == null &&
        (widget.initialName ?? '').isNotEmpty) {
      _controller.setName(widget.initialName!);
    }
    final s = _controller.state;
    _amountCtrl = TextEditingController(text: s.amountText);
    _nameCtrl = TextEditingController(text: s.name);
    _notesCtrl = TextEditingController(text: s.notes ?? '');
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (_controller.state.saved && mounted) {
      widget.onSaved();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.state.nextRenewalDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) _controller.setNextRenewalDate(picked);
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<_CategoryChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPicker(selected: _controller.state.category),
    );
    if (picked != null) _controller.setCategory(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final s = _controller.state;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  _brandPreview(s),
                  if (_showNameField) ...[
                    const SizedBox(height: 16),
                    _NameField(
                      controller: _nameCtrl,
                      onChanged: _controller.setName,
                    ),
                  ],
                  const SizedBox(height: 20),
                  const _Label('Tutar'),
                  const SizedBox(height: 10),
                  _amountRow(s),
                  ConvertedAmountPreview(
                    amount: double.tryParse(
                      s.amountText.trim().replaceAll(',', '.'),
                    ),
                    from: s.currency,
                  ),
                  const SizedBox(height: 20),
                  const _Label('Periyot'),
                  const SizedBox(height: 10),
                  _PeriodSegment(
                    value: s.billingPeriod,
                    onChanged: _controller.setBillingPeriod,
                  ),
                  const SizedBox(height: 16),
                  _infoCard([
                    _InfoRow(
                      label: 'Sonraki yenileme',
                      value: _formatDate(s.nextRenewalDate),
                      onTap: _pickDate,
                    ),
                    _InfoRow(
                      label: 'Kategori',
                      value: s.category == null
                          ? 'Otomatik'
                          : kCategoryLabels[s.category]!,
                      dotColor: s.category == null
                          ? null
                          : categoryColor(s.category!),
                      onTap: _pickCategory,
                      last: true,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _notesCard(),
                  if (s.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _errorBox(s.errorMessage!),
                  ],
                ],
              ),
            ),
            _footer(s),
          ],
        );
      },
    );
  }

  Widget _header() {
    final name = _controller.state.name;
    final title = name.isEmpty ? 'Yeni Abonelik' : name;
    return GlassSheetHeader(
      title: title,
      onBack: widget.onBack,
      onClose: widget.onClose,
    );
  }

  Widget _brandPreview(SubscriptionFormState s) {
    final cat = s.category;
    final catColor = cat != null ? categoryColor(cat) : AppTokens.tertiary;
    final name = s.name.isEmpty ? 'Yeni Abonelik' : s.name;
    final catLabel = cat != null ? kCategoryLabels[cat]! : 'Diğer';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [catColor.withValues(alpha: 0.20), AppTokens.surface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: catColor.withValues(alpha: 0.22), width: 0.5),
      ),
      child: Row(
        children: [
          BrandAvatar(
            serviceKey: _previewServiceKey,
            fallbackName: name,
            size: 52,
            circle: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: catColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      catLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTokens.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(SubscriptionFormState s) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: s.errorMessage != null ? AppTokens.red : AppTokens.hair,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  currencySymbol(s.currency),
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppTokens.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    onChanged: _controller.setAmountText,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.text,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '0,00',
                      hintStyle: TextStyle(
                        color: AppTokens.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _CurrencySegment(value: s.currency, onChanged: _controller.setCurrency),
      ],
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.hair, width: 0.5),
      ),
      child: Column(children: rows),
    );
  }

  Widget _notesCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.hair, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notlar',
            style: TextStyle(fontSize: 13, color: AppTokens.tertiary),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _notesCtrl,
            onChanged: _controller.setNotes,
            maxLines: 2,
            style: const TextStyle(fontSize: 15.5, color: AppTokens.text),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'İsteğe bağlı not ekle',
              hintStyle: TextStyle(color: AppTokens.tertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTokens.red.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppTokens.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTokens.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(SubscriptionFormState s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: s.isSubmitting ? null : _controller.submit,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppTokens.accentGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: s.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTokens.onAccent,
                        ),
                      )
                    : const Text(
                        'Kaydet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.onAccent,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppTokens.muted,
        letterSpacing: 0.3,
      ),
    ),
  );
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.hair, width: 1),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(fontSize: 16, color: AppTokens.text),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: 'Servis adı',
          hintStyle: TextStyle(color: AppTokens.tertiary),
        ),
      ),
    );
  }
}

class _CurrencySegment extends StatelessWidget {
  const _CurrencySegment({required this.value, required this.onChanged});
  final Currency value;
  final ValueChanged<Currency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.hair, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in Currency.values)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(c),
              child: Container(
                width: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c == value ? AppTokens.surface2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  currencySymbol(c),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c == value ? AppTokens.accentFg : AppTokens.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({required this.value, required this.onChanged});
  final BillingPeriod value;
  final ValueChanged<BillingPeriod> onChanged;

  static const _labels = {
    BillingPeriod.weekly: 'Haftalık',
    BillingPeriod.monthly: 'Aylık',
    BillingPeriod.yearly: 'Yıllık',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTokens.fillSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTokens.hair, width: 0.5),
      ),
      child: Row(
        children: [
          for (final p in BillingPeriod.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(p),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p == value ? AppTokens.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: p == value ? AppTokens.segShadow : null,
                  ),
                  child: Text(
                    _labels[p]!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p == value ? AppTokens.text : AppTokens.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.dotColor,
    this.onTap,
    this.last = false,
  });

  final String label;
  final String value;
  final Color? dotColor;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: AppTokens.hair, width: 0.5),
                ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15.5, color: AppTokens.muted),
            ),
            const Spacer(),
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              value,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppTokens.text,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTokens.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a category value (null = "Otomatik") for the picker result.
class _CategoryChoice {
  const _CategoryChoice(this.value);
  final SubscriptionCategory? value;
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({this.selected});
  final SubscriptionCategory? selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTokens.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTokens.hair2, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 9, bottom: 8),
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: AppTokens.grabber,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.text,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  _tile(context, const _CategoryChoice(null), 'Otomatik', null),
                  for (final c in SubscriptionCategory.values)
                    _tile(
                      context,
                      _CategoryChoice(c),
                      kCategoryLabels[c]!,
                      categoryColor(c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    _CategoryChoice choice,
    String label,
    Color? color,
  ) {
    final isSel = choice.value == selected;
    return ListTile(
      leading: color == null
          ? const Icon(Icons.auto_awesome, size: 18, color: AppTokens.tertiary)
          : Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
      title: Text(label, style: const TextStyle(color: AppTokens.text)),
      trailing: isSel
          ? const Icon(Icons.check, color: AppTokens.accentFg)
          : null,
      onTap: () => Navigator.of(context).pop(choice),
    );
  }
}

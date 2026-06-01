import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/currency/presentation/widgets/converted_amount_preview.dart';
import 'package:subsy/features/subscriptions/application/subscription_form_controller.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/brand_preview.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/currency_selector.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/period_selector.dart';

/// Add/edit subscription form. [subscription] null = add mode, else edit mode.
class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({super.key, this.subscription});

  final Subscription? subscription;

  @override
  ConsumerState<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends ConsumerState<SubscriptionFormScreen> {
  late final SubscriptionFormController _controller;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;

  static const Map<SubscriptionCategory, String> _categoryLabels = {
    SubscriptionCategory.streaming: 'Yayın',
    SubscriptionCategory.music: 'Müzik',
    SubscriptionCategory.cloud: 'Bulut',
    SubscriptionCategory.ai: 'Yapay zeka',
    SubscriptionCategory.productivity: 'Üretkenlik',
    SubscriptionCategory.shopping: 'Alışveriş',
    SubscriptionCategory.other: 'Diğer',
  };

  @override
  void initState() {
    super.initState();
    _controller = SubscriptionFormController(
      add: ref.read(addSubscriptionProvider),
      update: ref.read(updateSubscriptionProvider),
      delete: ref.read(deleteSubscriptionProvider),
      now: DateTime.now(),
      editing: widget.subscription,
    );
    final s = _controller.state;
    _nameCtrl = TextEditingController(text: s.name);
    _amountCtrl = TextEditingController(text: s.amountText);
    _notesCtrl = TextEditingController(text: s.notes ?? '');
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (_controller.state.saved && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
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

  Future<void> _confirmDelete() async {
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
    if (ok == true) await _controller.delete();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_controller.isEditing ? 'Aboneliği düzenle' : 'Abonelik ekle'),
        actions: [
          if (_controller.isEditing)
            IconButton(
              tooltip: 'Sil',
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final s = _controller.state;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              BrandPreview(name: s.name),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                onChanged: _controller.setName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Servis adı',
                  hintText: 'Netflix, Spotify…',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      onChanged: _controller.setAmountText,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Tutar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CurrencySelector(value: s.currency, onChanged: _controller.setCurrency),
                ],
              ),
              ConvertedAmountPreview(
                amount: double.tryParse(s.amountText.trim().replaceAll(',', '.')),
                from: s.currency,
              ),
              const SizedBox(height: 20),
              Text('Dönem', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              PeriodSelector(value: s.billingPeriod, onChanged: _controller.setBillingPeriod),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Sonraki yenileme'),
                subtitle: Text(_formatDate(s.nextRenewalDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SubscriptionCategory?>(
                initialValue: s.category,
                decoration: const InputDecoration(labelText: 'Kategori (opsiyonel)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Otomatik')),
                  for (final c in SubscriptionCategory.values)
                    DropdownMenuItem(value: c, child: Text(_categoryLabels[c]!)),
                ],
                onChanged: _controller.setCategory,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                onChanged: _controller.setNotes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
              ),
              if (s.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: s.isSubmitting ? null : _controller.submit,
                child: s.isSubmitting
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }
}

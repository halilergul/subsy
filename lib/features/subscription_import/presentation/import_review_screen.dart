import 'package:flutter/material.dart';
import 'package:subsy/features/subscription_import/application/import_controller.dart';
import 'package:subsy/features/subscription_import/domain/recognized_draft.dart';
import 'package:subsy/features/subscription_import/presentation/widgets/import_draft_card.dart';

/// Review/correct view (US2). Shows each recognized draft as an editable card;
/// nothing is saved until "Hepsini kaydet". Discarding a card removes only it.
class ImportReviewView extends StatelessWidget {
  const ImportReviewView({
    super.key,
    required this.state,
    required this.onChanged,
    required this.onDiscard,
    required this.onConfirm,
  });

  final ImportState state;
  final void Function(int index, RecognizedDraft draft) onChanged;
  final void Function(int index) onDiscard;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final saving = state.status == ImportStatus.saving;
    final count = state.drafts.length;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: count + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$count abonelik bulundu. Kontrol edip kaydet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final index = i - 1;
              return ImportDraftCard(
                key: ValueKey('draft_$index'),
                draft: state.drafts[index],
                error: index < state.draftErrors.length ? state.draftErrors[index] : null,
                onChanged: (d) => onChanged(index, d),
                onDiscard: () => onDiscard(index),
              );
            },
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving || count == 0 ? null : onConfirm,
              child: saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(count == 1 ? 'Kaydet' : 'Hepsini kaydet ($count)'),
            ),
          ),
        ),
      ],
    );
  }
}

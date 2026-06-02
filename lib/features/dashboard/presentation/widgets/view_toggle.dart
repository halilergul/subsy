import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';

/// The two dashboard content modes, selected by [ViewToggle].
enum DashboardView { list, calendar }

/// List ⇄ Calendar segmented control. Sits directly under the summary panel so
/// the total stays visible in both modes; only the content below it swaps.
class ViewToggle extends StatelessWidget {
  const ViewToggle({super.key, required this.view, required this.onChanged});

  final DashboardView view;
  final ValueChanged<DashboardView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTokens.fillSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.hair, width: 0.5),
      ),
      child: Row(
        children: [
          _tab(DashboardView.list, Icons.format_list_bulleted, 'Liste'),
          const SizedBox(width: 4),
          _tab(DashboardView.calendar, Icons.calendar_today_outlined, 'Takvim'),
        ],
      ),
    );
  }

  Widget _tab(DashboardView key, IconData icon, String label) {
    final active = view == key;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          decoration: BoxDecoration(
            color: active ? AppTokens.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? AppTokens.segShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? AppTokens.accent : AppTokens.muted),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? AppTokens.text : AppTokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

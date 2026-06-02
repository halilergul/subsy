import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';

/// Gold "Abonelik ekle" action that collapses to an icon-only circle while the
/// user scrolls down and re-extends when they scroll up or stop — the primary
/// action never fully disappears (discoverability), but it stops covering the
/// last list rows during a scroll.
class DashboardFab extends StatelessWidget {
  const DashboardFab({super.key, required this.extended, required this.onPressed});

  final bool extended;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 58,
          padding: EdgeInsets.symmetric(horizontal: extended ? 22 : 16),
          decoration: BoxDecoration(
            gradient: AppTokens.accentGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTokens.fabShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 26, color: AppTokens.onAccent),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: extended
                    ? const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Abonelik ekle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.onAccent,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

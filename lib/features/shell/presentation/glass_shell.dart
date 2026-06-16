import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/dashboard/presentation/glass_calendar.dart';
import 'package:subsy/features/dashboard/presentation/glass_dashboard.dart';
import 'package:subsy/features/settings/presentation/glass_settings.dart';
import 'package:subsy/features/statistics/presentation/glass_statistics.dart';
import 'package:subsy/features/subscriptions/presentation/glass_paywall_sheet.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/add_sheet.dart';
import 'package:subsy/shared/widgets/glass/ambient_background.dart';
import 'package:subsy/shared/widgets/glass/glass_nav_bar.dart';

/// The Liquid-Glass app shell: an ambient colour field behind four glass tab
/// screens (Pano · Takvim · Özet · Ayarlar) with a floating glass nav bar and
/// the gold `+` action. Tab bodies cross-fade; each keeps its own scroll state.
///
/// Screens start as glass placeholders and are filled in phase by phase
/// (dashboard, calendar, statistics, settings).
class GlassShell extends ConsumerStatefulWidget {
  const GlassShell({super.key});

  @override
  ConsumerState<GlassShell> createState() => _GlassShellState();
}

class _GlassShellState extends ConsumerState<GlassShell> {
  int _tab = 0;

  static const _items = [
    GlassNavItem(Icons.space_dashboard_rounded, 'Pano'),
    GlassNavItem(Icons.calendar_month_rounded, 'Takvim'),
    GlassNavItem(Icons.donut_large_rounded, 'Özet'),
    GlassNavItem(Icons.settings_rounded, 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    final bodies = <Widget>[
      GlassDashboard(onUpgrade: () => showPaywallSheet(context)),
      const GlassCalendar(),
      const GlassStatistics(),
      GlassSettings(onPaywall: () => showPaywallSheet(context)),
    ];

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),

          // Cross-fading tab bodies — each retains its state.
          Positioned.fill(
            child: Stack(
              children: [
                for (var i = 0; i < bodies.length; i++)
                  _CrossFade(active: _tab == i, child: bodies[i]),
              ],
            ),
          ),

          // Status-bar legibility fade.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70,
            child: IgnorePointer(
              child: DecoratedBox(decoration: BoxDecoration(gradient: AppTokens.topFade)),
            ),
          ),

          // Floating glass nav bar + gold action.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassNavBar(
              items: _items,
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              onAdd: () => showAddSheet(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tab body fades + lifts slightly when activated; inert when hidden.
class _CrossFade extends StatelessWidget {
  const _CrossFade({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        child: AnimatedSlide(
          offset: active ? Offset.zero : const Offset(0, 0.012),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          child: child,
        ),
      ),
    );
  }
}

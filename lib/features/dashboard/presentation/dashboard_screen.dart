import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/features/dashboard/application/dashboard_providers.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/dashboard/presentation/widgets/calendar_view.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_chrome.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_empty_state.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_fab.dart';
import 'package:subsy/features/dashboard/presentation/widgets/summary_panel.dart';
import 'package:subsy/features/dashboard/presentation/widgets/sub_row.dart';
import 'package:subsy/features/dashboard/presentation/widgets/view_toggle.dart';

/// Home screen: a persistent hero summary panel above a List ⇄ Calendar toggle.
/// The total card stays visible in both modes; only the content below it swaps.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardView _view = DashboardView.list;
  bool _fabExtended = true;

  /// Collapse the FAB while scrolling down, re-extend on scroll-up / idle.
  bool _onScroll(UserScrollNotification n) {
    final extend = switch (n.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => true,
    };
    if (extend != _fabExtended) setState(() => _fabExtended = extend);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = ref.watch(upcomingPaymentsProvider);
    final hasItems = upcoming.asData?.value.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        bottom: false,
        child: upcoming.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            message: error is AppError ? error.message : 'Abonelikler yüklenemedi.',
          ),
          data: (items) => items.isEmpty
              ? Column(
                  children: [
                    const _TopBar(),
                    Expanded(child: DashboardEmptyState(onAdd: () => _onAdd(context))),
                  ],
                )
              : NotificationListener<UserScrollNotification>(
                  onNotification: _onScroll,
                  child: _Content(
                    items: items,
                    view: _view,
                    onViewChanged: (v) => setState(() => _view = v),
                    onAdd: () => _onAdd(context),
                    onOpenSub: (p) => _onOpenSub(context, p),
                    onUpgrade: () => _onUpgrade(context),
                  ),
                ),
        ),
      ),
      floatingActionButton: hasItems
          ? DashboardFab(extended: _fabExtended, onPressed: () => _onAdd(context))
          : null,
    );
  }

  void _onAdd(BuildContext context) => context.push(Routes.addSubscription);

  void _onOpenSub(BuildContext context, UpcomingPayment payment) =>
      context.push(Routes.editSubscription, extra: payment.subscription);

  void _onUpgrade(BuildContext context) {
    // RevenueCat paywall ships last; honest placeholder until then.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium yakında geliyor.')),
    );
  }
}

/// Scrollable dashboard body: top bar, persistent summary panel, view toggle,
/// then the selected view's content — all in one scroll view so the FAB's
/// scroll-aware behavior fires and the panel scrolls with the content.
class _Content extends StatelessWidget {
  const _Content({
    required this.items,
    required this.view,
    required this.onViewChanged,
    required this.onAdd,
    required this.onOpenSub,
    required this.onUpgrade,
  });

  final List<UpcomingPayment> items;
  final DashboardView view;
  final ValueChanged<DashboardView> onViewChanged;
  final VoidCallback onAdd;
  final void Function(UpcomingPayment payment) onOpenSub;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        const _TopBar(),
        const SizedBox(height: 18),
        SummaryPanel(onUpgrade: onUpgrade),
        const SizedBox(height: 14),
        ViewToggle(view: view, onChanged: onViewChanged),
        const SizedBox(height: 18),
        if (view == DashboardView.list)
          ..._listContent(now)
        else
          CalendarView(payments: items, now: now, onOpenSub: onOpenSub),
      ],
    );
  }

  List<Widget> _listContent(DateTime now) {
    return [
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 11),
        child: SectionLabel('Yaklaşan ödemeler'),
      ),
      SubscriptionListCard(payments: items, now: now, onTap: onOpenSub),
    ];
  }
}

/// Title + icon cluster. Filter/search are deferred; the wired icons are
/// statistics and notifications (the screens that exist today).
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Abonelikler',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: AppTokens.text,
            ),
          ),
          Row(
            children: [
              _IconBtn(
                icon: Icons.bar_chart_rounded,
                tooltip: 'İstatistikler',
                onTap: () => context.push(Routes.statistics),
              ),
              const SizedBox(width: 8),
              _IconBtn(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Bildirimler',
                onTap: () => context.push(Routes.notificationSettings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTokens.fill,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: AppTokens.muted),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

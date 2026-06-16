import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';
import 'package:subsy/app/theme/app_text.dart';
import 'package:subsy/app/theme/app_tokens.dart';

/// Transparent nav bar carrying only the title + glass buttons. The actual
/// frosted material is a [glassScrollBlur] applied to the scroll body, so the
/// title/buttons float above content that dissolves under them — there is no
/// blurred panel with a hard bottom edge. Use with `extendBodyBehindAppBar:
/// true`, wrap the body in [glassScrollBlur], and pad the scroll body by
/// [glassTopInset].
PreferredSizeWidget glassAppBar(
  BuildContext context, {
  String? title,
  List<Widget>? actions,
  ValueListenable<double>? titleOpacity,
}) {
  final canPop = Navigator.of(context).canPop();

  Widget? titleWidget;
  if (title != null) {
    // iOS inline nav-bar title: Headline (17 / Semibold).
    final text = Text(
      title,
      style: AppText.headline.copyWith(color: AppTokens.text),
    );
    // When [titleOpacity] is supplied, the inline title fades in only once the
    // large in-content title has scrolled up under the bar (iOS collapse).
    titleWidget = titleOpacity == null
        ? text
        : ValueListenableBuilder<double>(
            valueListenable: titleOpacity,
            builder: (_, v, child) => Opacity(opacity: v, child: child),
            child: text,
          );
  }

  return AppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    centerTitle: true,
    automaticallyImplyLeading: false,
    leadingWidth: 60,
    leading: canPop
        ? Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GlassCircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          )
        : null,
    title: titleWidget,
    actions: actions,
  );
}

/// Maps a scroll [offset] to the inline-title opacity for a collapsing large
/// title. Stays 0 while the large title is still visible and only ramps to 1 as
/// the large title finishes tucking up under the nav bar / back button — so the
/// inline title appears once the large one is gone, like iOS (not the moment it
/// touches the bar). The large [glassLargeTitle] is ~55pt tall and sits ~8pt
/// below the bar, so it clears the bar around 60–66pt of scroll.
double collapsedTitleOpacity(
  double offset, {
  double start = 48,
  double end = 68,
}) => ((offset - start) / (end - start)).clamp(0.0, 1.0);

/// Wraps a scroll body so its top edge — the band under the nav bar — gets a
/// true iOS-26 progressive blur: content is snapshotted and the blur is masked
/// by a vertical gradient that fades to clear just below the bar, so scrolling
/// content dissolves smoothly underneath instead of being cut by a hard line.
///
/// Pass [bandHeight] to match the bar height (defaults to status bar + toolbar).
/// The child is backed by an opaque [AppTokens.bg] so the snapshot is fully
/// opaque — nothing from a route behind can bleed through during transitions.
Widget glassScrollBlur(
  BuildContext context, {
  required Widget child,
  double? bandHeight,
  Color backgroundColor = AppTokens.bg,
  double sigma = 24,
}) {
  final band = bandHeight ?? MediaQuery.paddingOf(context).top + kToolbarHeight;
  return SoftEdgeBlur(
    edges: [
      EdgeBlur(
        type: EdgeType.topEdge,
        size: band,
        sigma: sigma,
        tintColor: const Color.fromRGBO(14, 14, 18, 0.34),
        controlPoints: [
          // Full blur from the top down to ~85% of the band, then fade to clear
          // over the last 15% — the smooth falloff that kills the cut line.
          ControlPoint(position: 0.85, type: ControlPointType.visible),
          ControlPoint(position: 1.0, type: ControlPointType.transparent),
        ],
      ),
    ],
    child: ColoredBox(color: backgroundColor, child: child),
  );
}

/// Top padding a scroll body needs so its first item clears the glass bar.
double glassTopInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

/// iOS large-title header (34 / Bold) for the top of a screen's scroll body —
/// the prominent header that reads as a title, with the small inline bar title
/// reserved for the scrolled-up state.
Widget glassLargeTitle(String text) => Padding(
  padding: const EdgeInsets.only(left: 4, top: 4, bottom: 10),
  child: Text(text, style: AppText.largeTitle.copyWith(color: AppTokens.text)),
);

/// Circular glass-chip icon button for every back/close affordance. Uses a
/// solid translucent dark fill (NOT a backdrop blur) with a top sheen and a
/// hairline rim — so it reads cleanly over any content without the blurred
/// "halo disc" a per-button BackdropFilter produces over sharp pixels.
///
/// The visible chip is [size]; the tappable area is [hitSize] (iOS minimum
/// 44pt) so the touch target meets HIG even though the chip looks compact.
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 36,
    this.hitSize = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double hitSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: hitSize,
      height: hitSize,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Slightly lighter at the top — a subtle glass sheen.
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(64, 64, 72, 0.82),
                    Color.fromRGBO(34, 34, 40, 0.78),
                  ],
                ),
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.16),
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.28),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: size * 0.5, color: AppTokens.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard bottom-sheet header: a truly-centered title flanked by equal-width
/// slots so the optional glass back (left) and close (right) buttons never push
/// the title off-center. Reused by every sheet for one consistent look.
class GlassSheetHeader extends StatelessWidget {
  const GlassSheetHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onClose,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    const slot = 44.0; // matches GlassCircleButton's 44pt hit target
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
      child: Row(
        children: [
          SizedBox(
            width: slot,
            child: onBack != null
                ? GlassCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack!,
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Prominent sheet title: Title 3 size (20) at Semibold.
              style: AppText.title3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.text,
              ),
            ),
          ),
          SizedBox(
            width: slot,
            child: onClose != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: GlassCircleButton(
                      icon: Icons.close_rounded,
                      onTap: onClose!,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

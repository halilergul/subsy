import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// One destination in the floating [GlassNavBar].
class GlassNavItem {
  const GlassNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// The floating Liquid-Glass tab bar + gold action button. Sits over the
/// ambient background; a brighter "lens" springs to the active destination, and
/// the gold `+` FAB rides alongside it.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _bar(context)),
          const SizedBox(width: 10),
          _fab(),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context) {
    return GlassSurface(
      radius: 999,
      fill: GlassFill.strong,
      // Live backdrop blur: the scrolling tab content frosts behind the bar —
      // the authentic iOS-26 floating glass. (The crash that prompted disabling
      // this was a debug-JIT/codesign issue, not the filter; release is fine.)
      blur: true,
      shadow: AppTokens.glassShadow,
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        height: 52,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  left: segWidth * currentIndex,
                  top: 0,
                  bottom: 0,
                  width: segWidth,
                  child: const GlassSurface(
                    radius: 999,
                    fill: GlassFill.lens,
                    shadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.4),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(child: _tab(items[i], i == currentIndex, () => onTap(i))),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tab(GlassNavItem item, bool active, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            size: 21,
            color: active ? AppTokens.accentFg : AppTokens.muted,
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: active ? AppTokens.text : AppTokens.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fab() {
    final br = BorderRadius.circular(999);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: br, boxShadow: AppTokens.fabShadow),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTokens.accentGradient,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onAdd,
            child: const SizedBox(
              width: 62,
              height: 62,
              child: Icon(Icons.add_rounded, size: 28, color: AppTokens.onAccent),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// One choice in a [GlassSegmented].
class GlassSegment<T> {
  const GlassSegment(this.value, this.label);
  final T value;
  final String label;
}

/// iOS-26 glass segmented control: a glass track with a brighter "lens" that
/// springs to the selected segment. Used for period (Haftalık/Aylık/Yıllık) and
/// currency (₺/$/€) pickers.
class GlassSegmented<T> extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    this.height = 38,
  });

  final T value;
  final List<GlassSegment<T>> segments;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    var index = segments.indexWhere((s) => s.value == value);
    if (index < 0) index = 0;

    return GlassSurface(
      radius: 999,
      fill: GlassFill.soft,
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segWidth = constraints.maxWidth / segments.length;
            return Stack(
              children: [
                // Sliding lens.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  left: segWidth * index,
                  top: 0,
                  bottom: 0,
                  width: segWidth,
                  child: const GlassSurface(
                    radius: 999,
                    fill: GlassFill.lens,
                    shadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.35),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (final s in segments)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(s.value),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: s.value == value
                                    ? AppTokens.text
                                    : AppTokens.muted,
                              ),
                              child: Text(s.label),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

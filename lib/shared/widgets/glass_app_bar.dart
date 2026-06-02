import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';

/// iOS-style frosted nav bar: translucent + blurred so content scrolls under it
/// (no abrupt scrolled-under color), with a glass circular back button. Use on
/// pushed screens together with `Scaffold(extendBodyBehindAppBar: true)` and a
/// scroll body padded by [glassTopInset].
PreferredSizeWidget glassAppBar(
  BuildContext context, {
  String? title,
  List<Widget>? actions,
}) {
  final canPop = Navigator.of(context).canPop();
  return AppBar(
    backgroundColor: const Color.fromRGBO(14, 14, 18, 0.55), // AppTokens.bg @55%
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
    title: title == null
        ? null
        : Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTokens.text)),
    actions: actions,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

/// Top padding a scroll body needs so its first item clears the glass bar.
double glassTopInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

/// Circular translucent + blurred icon button (iOS "glass" affordance).
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({super.key, required this.icon, required this.onTap, this.size = 34});

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: const Color.fromRGBO(255, 255, 255, 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: size * 0.46, color: AppTokens.text),
            ),
          ),
        ),
      ),
    );
  }
}

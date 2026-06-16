import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/shared/widgets/glass/glass_buttons.dart';

/// Presents [builder] as a Liquid-Glass modal bottom sheet over a dimmed scrim.
/// The content manages its own scrolling; wrap it in a [GlassSheet] for the
/// grabber + frosted material + standard header.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: AppTokens.scrimStrong,
    builder: builder,
  );
}

/// The frosted sheet shell: a top-rounded glass panel with a grabber and an
/// optional standard header (centered title/subtitle, glass close button, and
/// an optional left action). Keyboard-aware. [heightFactor] caps the sheet to a
/// fraction of the screen (default 0.92 for keyboard/large content); pass a
/// smaller value, or leave the content short, for a content-height sheet.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    this.title,
    this.subtitle,
    this.onClose,
    this.leading,
    this.heightFactor = 0.92,
    this.contentHeight = false,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback? onClose;
  final Widget? leading;
  final double heightFactor;

  /// When true the sheet hugs its content height instead of filling
  /// [heightFactor] of the screen.
  final bool contentHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height * heightFactor;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        // Grabber.
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: AppTokens.grabber,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 5),
        if (title != null)
          GlassSheetHeader(title: title!, subtitle: subtitle, onClose: onClose, leading: leading),
        contentHeight ? child : Flexible(child: child),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppTokens.sheetSurface,
              border: Border(
                top: BorderSide(color: AppTokens.glassInnerHighlight, width: 1),
              ),
            ),
            child: column,
          ),
        ),
      ),
    );
  }
}

/// Standard sheet header: a truly-centered title (+ optional subtitle) flanked
/// by an optional left action and a glass close button on the right.
class GlassSheetHeader extends StatelessWidget {
  const GlassSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.text,
                      letterSpacing: -0.2),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(subtitle!,
                        style: const TextStyle(fontSize: 12.5, color: AppTokens.muted)),
                  ),
              ],
            ),
            if (leading != null) Align(alignment: Alignment.centerLeft, child: leading),
            if (onClose != null)
              Align(
                alignment: Alignment.centerRight,
                child: GlassIconButton(
                  icon: Icons.close_rounded,
                  size: 32,
                  onTap: onClose!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows a transient glass "toast" pill at the bottom of the screen.
void showGlassToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(milliseconds: 2100),
      margin: const EdgeInsets.only(bottom: 96, left: 40, right: 40),
      padding: EdgeInsets.zero,
      content: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTokens.glassFillStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTokens.hair2, width: 0.8),
            boxShadow: AppTokens.glassShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.text),
            ),
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';

/// Optional "carry premium to another platform" surface (spec US3 / FR-012).
/// Content-height modal that grows with the keyboard. It links only the store
/// entitlement, never subscription data. The actual store sign-in ships with
/// the paywall feature; until then the actions present an honest "coming with
/// Premium" state rather than a broken auth flow (FR-016).
Future<void> showCrossPlatformSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppTokens.scrim,
    builder: (_) => const _CrossPlatformSheet(),
  );
}

class _CrossPlatformSheet extends StatelessWidget {
  const _CrossPlatformSheet();

  void _comingSoon(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Çapraz platform aktarımı Premium ile birlikte gelecek.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      // grow with the keyboard; sheet height otherwise hugs its content
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTokens.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTokens.hair2, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // grabber
              Container(
                margin: const EdgeInsets.only(top: 9, bottom: 4),
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTokens.grabber,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Premium'u başka platforma taşı",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTokens.text, letterSpacing: -0.2),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        gradient: AppTokens.accentGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color.fromRGBO(199, 162, 86, 0.36), blurRadius: 26, offset: Offset(0, 10)),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, size: 30, color: AppTokens.onAccent),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Apple veya Google ile giriş yaparak premium’unu başka bir telefonda da kullanabilirsin. Bu yalnızca satın alımını bağlar — aboneliklerin yine sadece cihazında kalır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.5, height: 1.5, color: AppTokens.muted),
                    ),
                    const SizedBox(height: 20),
                    _authButton(
                      context,
                      icon: Icons.apple,
                      label: 'Apple ile giriş yap',
                      background: Colors.black,
                      foreground: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    _authButton(
                      context,
                      icon: Icons.g_mobiledata,
                      label: 'Google ile devam et',
                      background: AppTokens.surface,
                      foreground: AppTokens.text,
                      border: true,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Belki sonra', style: TextStyle(color: AppTokens.muted, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    bool border = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border ? const BorderSide(color: AppTokens.hair2, width: 1) : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _comingSoon(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

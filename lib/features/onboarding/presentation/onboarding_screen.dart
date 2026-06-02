import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/onboarding/application/onboarding_providers.dart';
import 'package:subsy/features/onboarding/presentation/widgets/cross_platform_sheet.dart';
import 'package:subsy/features/onboarding/presentation/widgets/slide_visuals.dart';

/// First-run onboarding carousel: four differentiated slides, a progress
/// indicator, skip-from-anywhere, an in-context notification pre-prompt on the
/// last slide, and an optional cross-platform purchase surface. Completing or
/// skipping persists the flag and routes into the app (spec US1/US2/US3).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  /// On the last slide, the primary CTA first reveals the notification
  /// pre-prompt (enable / skip) instead of finishing immediately.
  bool _priming = false;

  static const _slides = <_SlideData>[
    _SlideData(
      visual: ValueVisual(),
      headline: 'Aboneliklerini tek yerde topla',
      sub: 'Her yenileme, her tutar, her tarih — sürprizsiz.',
    ),
    _SlideData(
      visual: PrivacyVisual(),
      headline: 'Verilerin cihazında kalır',
      sub: 'Hesap yok, sunucu yok, takip yok. Subsy internet olmadan da çalışır.',
      footnote:
          'Premium, App Store / Google Play hesabına bağlı — yeni cihazında tek dokunuşla geri yükle.',
      showCrossPlatformLink: true,
    ),
    _SlideData(
      visual: ScanVisual(),
      tag: 'Premium',
      headline: 'Saniyede ekle',
      sub: 'Makbuz, ekran görüntüsü ya da App Store aboneliklerini tara — Subsy otomatik tanısın.',
    ),
    _SlideData(
      visual: RemindVisual(),
      headline: 'Zamanında haberdar ol',
      sub: 'Yenilemeden önce hatırlatma al, harcamanı tek bakışta gör.',
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      setState(() => _priming = true); // reveal the notification pre-prompt
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// Requests OS notification permission (also enables reminders when granted),
  /// then finishes — never blocks on the result (FR-010).
  Future<void> _enableNotificationsThenFinish() async {
    final current = ref.read(notificationSettingsProvider).asData?.value;
    if (current != null) {
      try {
        await ref
            .read(notificationSettingsControllerProvider)
            .setEnabled(current, true);
      } catch (_) {
        // Permission denied / unavailable — onboarding still completes.
      }
    }
    await _finish();
  }

  /// Persists completion and routes into the app (or back, when re-opened).
  Future<void> _finish() async {
    await ref.read(onboardingRepositoryProvider).markCompleted();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            _skipRow(),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() {
                  _index = i;
                  _priming = false;
                }),
                itemBuilder: (_, i) => _Slide(
                  data: _slides[i],
                  onCrossPlatform: () => showCrossPlatformSheet(context),
                ),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _skipRow() {
    return SizedBox(
      height: 44,
      child: Align(
        alignment: Alignment.centerRight,
        child: _isLast
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 18),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Atla',
                    style: TextStyle(color: AppTokens.accentFg, fontSize: 15.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 14, 26, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dots(),
          const SizedBox(height: 22),
          if (_isLast && _priming)
            Column(
              children: [
                _PrimaryButton(label: 'Bildirimleri aç', onTap: _enableNotificationsThenFinish),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _finish,
                  child: const Text('Şimdilik geç',
                      style: TextStyle(color: AppTokens.muted, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            )
          else
            _PrimaryButton(label: _isLast ? 'Başla' : 'İleri', onTap: _next),
        ],
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _slides.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            height: 7,
            width: i == _index ? 22 : 7,
            decoration: BoxDecoration(
              color: i == _index ? AppTokens.accent : AppTokens.fillSoft,
              borderRadius: BorderRadius.circular(999),
              border: i == _index ? null : Border.all(color: AppTokens.hair2, width: 0.5),
            ),
          ),
      ],
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.visual,
    required this.headline,
    required this.sub,
    this.tag,
    this.footnote,
    this.showCrossPlatformLink = false,
  });

  final Widget visual;
  final String headline;
  final String sub;
  final String? tag;
  final String? footnote;
  final bool showCrossPlatformLink;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data, required this.onCrossPlatform});

  final _SlideData data;
  final VoidCallback onCrossPlatform;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          data.visual,
          const SizedBox(height: 30),
          if (data.tag != null) ...[
            _Tag(data.tag!),
            const SizedBox(height: 14),
          ],
          Text(
            data.headline,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTokens.text,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.sub,
            style: const TextStyle(fontSize: 16, color: AppTokens.muted, height: 1.5),
          ),
          if (data.footnote != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: AppTokens.fillSoft,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppTokens.hair, width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 15, color: AppTokens.accentFg),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      data.footnote!,
                      style: const TextStyle(fontSize: 12.5, color: AppTokens.muted, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (data.showCrossPlatformLink) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onCrossPlatform,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                child: const Text(
                  'Premium’u başka platforma taşı →',
                  style: TextStyle(color: AppTokens.accentFg, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(199, 162, 86, 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color.fromRGBO(199, 162, 86, 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 13, color: AppTokens.accentFg),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.accentFg, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppTokens.accentGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color.fromRGBO(199, 162, 86, 0.3), blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTokens.onAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

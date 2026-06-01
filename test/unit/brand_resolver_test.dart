import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// US2 acceptance: offline brand recognition, Turkish-tolerant (maps SC-003).
void main() {
  const resolver = BrandResolver();

  test('all mandatory services are present with color and logo', () {
    const mandatory = [
      'spotify', 'netflix', 'youtube_premium', 'apple_tv_plus', 'icloud_plus',
      'chatgpt', 'claude_pro', 'exxen', 'gain', 'blutv',
      'trendyol_premium', 'amazon_prime',
    ];
    final keys = kBrandCatalog.map((e) => e.serviceKey).toSet();
    for (final key in mandatory) {
      expect(keys, contains(key), reason: '$key missing from catalog');
    }
    for (final entry in kBrandCatalog) {
      expect(entry.brandColor, isNonZero);
      expect(entry.logoAsset, startsWith('assets/logos/'));
    }
  });

  test('resolves canonical display names', () {
    expect(resolver.resolve('Netflix')?.serviceKey, 'netflix');
    expect(resolver.resolve('Spotify')?.defaultCategory, SubscriptionCategory.music);
    expect(resolver.resolve('Claude Pro')?.serviceKey, 'claude_pro');
  });

  group('case-insensitive and Turkish-character tolerant', () {
    final cases = {
      'exxen': 'exxen',
      'BLUTV': 'blutv',
      'İcloud': 'icloud_plus', // dotted capital I
      'NETFLIX': 'netflix',
      'sPoTiFy': 'spotify',
    };
    cases.forEach((input, expectedKey) {
      test('"$input" → $expectedKey', () {
        expect(resolver.resolve(input)?.serviceKey, expectedKey);
      });
    });
  });

  group('alias matching', () {
    final cases = {
      'YT Premium': 'youtube_premium',
      'youtube': 'youtube_premium',
      'chatgpt': 'chatgpt',
      'openai': 'chatgpt',
      'chatgpt pro': 'chatgpt',
      'prime video': 'amazon_prime',
      'trendyol': 'trendyol_premium',
      'icloud': 'icloud_plus',
    };
    cases.forEach((input, expectedKey) {
      test('"$input" → $expectedKey', () {
        expect(resolver.resolve(input)?.serviceKey, expectedKey);
      });
    });
  });

  test('trims and collapses whitespace', () {
    expect(resolver.resolve('  youtube   premium  ')?.serviceKey, 'youtube_premium');
  });

  test('unknown service returns null without throwing', () {
    expect(resolver.resolve('SomeRandomService'), isNull);
    expect(resolver.resolve(''), isNull);
    expect(resolver.resolve('   '), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscription_import/domain/brand_text_matcher.dart';

void main() {
  const matcher = BrandTextMatcher();

  test('matches a catalog brand in free text', () {
    final m = matcher.findIn('Spotify Premium ₺59,99');
    expect(m, isNotEmpty);
    expect(m.first.serviceKey, 'spotify');
  });

  test('Turkish-character normalization: İCLOUD+ → icloud_plus', () {
    final m = matcher.findIn('İCLOUD+ 19,99');
    expect(m.first.serviceKey, 'icloud_plus');
  });

  test('prefers the longer brand name (YouTube Premium, not a bare token)', () {
    final m = matcher.findIn('YouTube Premium ₺79,99');
    expect(m.first.serviceKey, 'youtube_premium');
  });

  test('returns matches in reading order for multiple brands', () {
    final m = matcher.findIn('Netflix Spotify');
    expect(m.map((e) => e.serviceKey), ['netflix', 'spotify']);
  });

  test('no word-boundary false positive (gain inside "again")', () {
    final keys = matcher.findIn('again and again').map((e) => e.serviceKey);
    expect(keys, isNot(contains('gain')));
  });

  test('unknown text → empty', () {
    expect(matcher.findIn('totally unknown service'), isEmpty);
  });
}

import 'package:subsy/features/subscriptions/domain/brand_catalog_entry.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// The bundled, offline brand catalog. The 12 Turkey-focused services below
/// are mandatory at launch (FR-011); the list may be extended over time.
/// Brand colors are the implementation starting point per data-model.md.
const List<BrandCatalogEntry> kBrandCatalog = [
  BrandCatalogEntry(
    serviceKey: 'spotify',
    displayName: 'Spotify',
    brandColor: 0xFF1DB954,
    logoAsset: 'assets/logos/spotify.svg',
    defaultCategory: SubscriptionCategory.music,
    aliases: ['spotify premium'],
  ),
  BrandCatalogEntry(
    serviceKey: 'netflix',
    displayName: 'Netflix',
    brandColor: 0xFFE50914,
    logoAsset: 'assets/logos/netflix.svg',
    defaultCategory: SubscriptionCategory.streaming,
  ),
  BrandCatalogEntry(
    serviceKey: 'youtube_premium',
    displayName: 'YouTube Premium',
    brandColor: 0xFFFF0000,
    logoAsset: 'assets/logos/youtube_premium.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['youtube', 'yt premium', 'youtube music'],
  ),
  BrandCatalogEntry(
    serviceKey: 'apple_tv_plus',
    displayName: 'Apple TV+',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/apple_tv_plus.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['apple tv', 'appletv', 'apple tv plus'],
  ),
  BrandCatalogEntry(
    serviceKey: 'icloud_plus',
    displayName: 'iCloud+',
    brandColor: 0xFF3693F3,
    logoAsset: 'assets/logos/icloud_plus.svg',
    defaultCategory: SubscriptionCategory.cloud,
    aliases: ['icloud', 'icloud plus'],
  ),
  BrandCatalogEntry(
    serviceKey: 'chatgpt_plus',
    displayName: 'ChatGPT Plus',
    brandColor: 0xFF10A37F,
    logoAsset: 'assets/logos/chatgpt_plus.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['chatgpt', 'openai', 'gpt plus', 'chat gpt'],
  ),
  BrandCatalogEntry(
    serviceKey: 'claude_pro',
    displayName: 'Claude Pro',
    brandColor: 0xFFD97757,
    logoAsset: 'assets/logos/claude_pro.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['claude', 'anthropic'],
  ),
  BrandCatalogEntry(
    serviceKey: 'exxen',
    displayName: 'Exxen',
    brandColor: 0xFFF9D616,
    logoAsset: 'assets/logos/exxen.svg',
    defaultCategory: SubscriptionCategory.streaming,
  ),
  BrandCatalogEntry(
    serviceKey: 'gain',
    displayName: 'Gain',
    brandColor: 0xFFE6007E,
    logoAsset: 'assets/logos/gain.svg',
    defaultCategory: SubscriptionCategory.streaming,
  ),
  BrandCatalogEntry(
    serviceKey: 'blutv',
    displayName: 'BluTV',
    brandColor: 0xFF00A0E3,
    logoAsset: 'assets/logos/blutv.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['blu tv', 'blu'],
  ),
  BrandCatalogEntry(
    serviceKey: 'trendyol_premium',
    displayName: 'Trendyol Premium',
    brandColor: 0xFFF27A1A,
    logoAsset: 'assets/logos/trendyol_premium.svg',
    defaultCategory: SubscriptionCategory.shopping,
    aliases: ['trendyol', 'ty premium'],
  ),
  BrandCatalogEntry(
    serviceKey: 'amazon_prime',
    displayName: 'Amazon Prime',
    brandColor: 0xFF00A8E1,
    logoAsset: 'assets/logos/amazon_prime.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['prime', 'amazon prime video', 'prime video'],
  ),
];

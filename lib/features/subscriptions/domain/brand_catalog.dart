import 'package:subsy/features/subscriptions/domain/brand_catalog_entry.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Looks up a catalog entry by its exact service key (the value stored on a
/// subscription). Returns null for null/unknown keys.
BrandCatalogEntry? brandByKey(String? serviceKey) {
  if (serviceKey == null) return null;
  for (final entry in kBrandCatalog) {
    if (entry.serviceKey == serviceKey) return entry;
  }
  return null;
}

/// The bundled, offline brand catalog. The Turkey-focused core set is mandatory
/// at launch (FR-011); the list is extended over time. Brand colors are
/// best-effort references; entries whose logo is a letter placeholder (TR/niche
/// brands not in the bundled icon set) are marked in the catalog notes and get
/// a real SVG when one is supplied.
const List<BrandCatalogEntry> kBrandCatalog = [
  // --- Music ---
  BrandCatalogEntry(
    serviceKey: 'spotify',
    displayName: 'Spotify',
    brandColor: 0xFF1DB954,
    logoAsset: 'assets/logos/spotify.svg',
    defaultCategory: SubscriptionCategory.music,
    aliases: ['spotify premium'],
  ),
  BrandCatalogEntry(
    serviceKey: 'apple_music',
    displayName: 'Apple Music',
    brandColor: 0xFFFA243C,
    logoAsset: 'assets/logos/apple_music.svg',
    defaultCategory: SubscriptionCategory.music,
    aliases: ['apple music'],
  ),
  BrandCatalogEntry(
    serviceKey: 'youtube_music',
    displayName: 'YouTube Music',
    brandColor: 0xFFFF0000,
    logoAsset: 'assets/logos/youtube_music.svg',
    defaultCategory: SubscriptionCategory.music,
    aliases: ['youtube music', 'yt music'],
  ),
  BrandCatalogEntry(
    serviceKey: 'deezer',
    displayName: 'Deezer',
    brandColor: 0xFFA238FF,
    logoAsset: 'assets/logos/deezer.svg',
    defaultCategory: SubscriptionCategory.music,
    aliases: ['deezer'],
  ),
  BrandCatalogEntry(
    serviceKey: 'fizy',
    displayName: 'fizy',
    brandColor: 0xFFB4009E, // verify
    logoAsset: 'assets/logos/fizy.svg',
    defaultCategory: SubscriptionCategory.music,
    aliases: ['fizy'],
  ),

  // --- Streaming ---
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
    aliases: ['youtube', 'yt premium'],
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
    serviceKey: 'disney_plus',
    displayName: 'Disney+',
    brandColor: 0xFF0E47BA,
    logoAsset: 'assets/logos/disney_plus.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['disney', 'disney plus', 'disney+'],
  ),
  BrandCatalogEntry(
    serviceKey: 'amazon_prime',
    displayName: 'Amazon Prime',
    brandColor: 0xFF00A8E1,
    logoAsset: 'assets/logos/amazon_prime.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['prime', 'amazon prime video', 'prime video'],
  ),
  BrandCatalogEntry(
    serviceKey: 'mubi',
    displayName: 'MUBI',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/mubi.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['mubi'],
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
    serviceKey: 'tabii',
    displayName: 'tabii',
    brandColor: 0xFF14B8A6, // verify
    logoAsset: 'assets/logos/tabii.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['tabii', 'trt tabii'],
  ),
  BrandCatalogEntry(
    serviceKey: 'bein_connect',
    displayName: 'beIN CONNECT',
    brandColor: 0xFF6D2077, // verify
    logoAsset: 'assets/logos/bein_connect.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['bein', 'bein connect', 'bein sports'],
  ),
  BrandCatalogEntry(
    serviceKey: 'tod',
    displayName: 'TOD',
    brandColor: 0xFF101820, // verify
    logoAsset: 'assets/logos/tod.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['tod', 'tod tv'],
  ),
  BrandCatalogEntry(
    serviceKey: 'hbo_max',
    displayName: 'HBO Max',
    brandColor: 0xFF002BE7,
    logoAsset: 'assets/logos/hbo_max.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['hbo max', 'hbo', 'max'],
  ),
  BrandCatalogEntry(
    serviceKey: 'crunchyroll',
    displayName: 'Crunchyroll',
    brandColor: 0xFFF47521,
    logoAsset: 'assets/logos/crunchyroll.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['crunchyroll', 'crunchy roll'],
  ),
  BrandCatalogEntry(
    serviceKey: 'paramount_plus',
    displayName: 'Paramount+',
    brandColor: 0xFF0064FF,
    logoAsset: 'assets/logos/paramount_plus.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['paramount', 'paramount plus', 'paramount+'],
  ),
  BrandCatalogEntry(
    serviceKey: 'tivibu_go',
    displayName: 'Tivibu GO',
    brandColor: 0xFF00A3E0, // verify
    logoAsset: 'assets/logos/tivibu_go.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['tivibu', 'tivibu go'],
  ),
  BrandCatalogEntry(
    serviceKey: 'dsmart_go',
    displayName: 'D-Smart GO',
    brandColor: 0xFFE2001A, // verify
    logoAsset: 'assets/logos/dsmart_go.svg',
    defaultCategory: SubscriptionCategory.streaming,
    aliases: ['dsmart', 'd-smart', 'd smart', 'dsmart go', 'd-smart go'],
  ),

  // --- Cloud ---
  BrandCatalogEntry(
    serviceKey: 'icloud_plus',
    displayName: 'iCloud+',
    brandColor: 0xFF3693F3,
    logoAsset: 'assets/logos/icloud_plus.svg',
    defaultCategory: SubscriptionCategory.cloud,
    aliases: ['icloud', 'icloud plus'],
  ),
  BrandCatalogEntry(
    serviceKey: 'google_one',
    displayName: 'Google One',
    brandColor: 0xFF4285F4,
    logoAsset: 'assets/logos/google_one.svg',
    defaultCategory: SubscriptionCategory.cloud,
    aliases: ['google one', 'google drive', 'google storage'],
  ),
  BrandCatalogEntry(
    serviceKey: 'dropbox',
    displayName: 'Dropbox',
    brandColor: 0xFF0061FF,
    logoAsset: 'assets/logos/dropbox.svg',
    defaultCategory: SubscriptionCategory.cloud,
    aliases: ['dropbox'],
  ),
  BrandCatalogEntry(
    serviceKey: 'onedrive',
    displayName: 'OneDrive',
    brandColor: 0xFF0078D4,
    logoAsset: 'assets/logos/onedrive.svg',
    defaultCategory: SubscriptionCategory.cloud,
    aliases: ['onedrive', 'one drive', 'microsoft onedrive'],
  ),

  // --- AI ---
  BrandCatalogEntry(
    serviceKey: 'chatgpt',
    displayName: 'ChatGPT',
    brandColor: 0xFF10A37F,
    logoAsset: 'assets/logos/chatgpt.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['chatgpt', 'chatgpt plus', 'chatgpt pro', 'gpt plus', 'gpt pro', 'openai', 'chat gpt'],
  ),
  BrandCatalogEntry(
    serviceKey: 'claude_pro',
    displayName: 'Claude Pro',
    brandColor: 0xFFD97757,
    logoAsset: 'assets/logos/claude_pro.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['claude', 'anthropic', 'claude pro'],
  ),
  BrandCatalogEntry(
    serviceKey: 'gemini',
    displayName: 'Gemini',
    brandColor: 0xFF1C69FF,
    logoAsset: 'assets/logos/gemini.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['gemini', 'google gemini', 'gemini advanced', 'bard'],
  ),
  BrandCatalogEntry(
    serviceKey: 'perplexity',
    displayName: 'Perplexity',
    brandColor: 0xFF20808D,
    logoAsset: 'assets/logos/perplexity.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['perplexity', 'perplexity ai', 'perplexity pro'],
  ),
  BrandCatalogEntry(
    serviceKey: 'midjourney',
    displayName: 'Midjourney',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/midjourney.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['midjourney', 'mj'],
  ),
  BrandCatalogEntry(
    serviceKey: 'elevenlabs',
    displayName: 'ElevenLabs',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/elevenlabs.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['elevenlabs', 'eleven labs', '11labs'],
  ),
  BrandCatalogEntry(
    serviceKey: 'suno',
    displayName: 'Suno',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/suno.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['suno', 'suno ai'],
  ),
  BrandCatalogEntry(
    serviceKey: 'cursor',
    displayName: 'Cursor',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/cursor.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['cursor', 'cursor ai', 'cursor pro'],
  ),
  BrandCatalogEntry(
    serviceKey: 'github_copilot',
    displayName: 'GitHub Copilot',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/github_copilot.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['github copilot', 'copilot', 'gh copilot'],
  ),
  BrandCatalogEntry(
    serviceKey: 'deepl',
    displayName: 'DeepL',
    brandColor: 0xFF0F2B46,
    logoAsset: 'assets/logos/deepl.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['deepl', 'deepl pro'],
  ),
  BrandCatalogEntry(
    serviceKey: 'runway',
    displayName: 'Runway',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/runway.svg',
    defaultCategory: SubscriptionCategory.ai,
    aliases: ['runway', 'runwayml', 'runway ml'],
  ),

  // --- Productivity ---
  BrandCatalogEntry(
    serviceKey: 'microsoft_365',
    displayName: 'Microsoft 365',
    brandColor: 0xFFD83B01,
    logoAsset: 'assets/logos/microsoft_365.svg',
    defaultCategory: SubscriptionCategory.productivity,
    aliases: ['microsoft 365', 'office 365', 'office', 'm365', 'ms365'],
  ),
  BrandCatalogEntry(
    serviceKey: 'notion',
    displayName: 'Notion',
    brandColor: 0xFF000000,
    logoAsset: 'assets/logos/notion.svg',
    defaultCategory: SubscriptionCategory.productivity,
    aliases: ['notion', 'notion plus', 'notion pro'],
  ),
  BrandCatalogEntry(
    serviceKey: 'linkedin',
    displayName: 'LinkedIn Premium',
    brandColor: 0xFF0A66C2,
    logoAsset: 'assets/logos/linkedin.svg',
    defaultCategory: SubscriptionCategory.productivity,
    aliases: ['linkedin', 'linkedin premium'],
  ),

  // --- Shopping ---
  BrandCatalogEntry(
    serviceKey: 'trendyol_premium',
    displayName: 'Trendyol Premium',
    brandColor: 0xFFF27A1A,
    logoAsset: 'assets/logos/trendyol_premium.svg',
    defaultCategory: SubscriptionCategory.shopping,
    aliases: ['trendyol', 'ty premium'],
  ),
  BrandCatalogEntry(
    serviceKey: 'hepsiburada_premium',
    displayName: 'Hepsiburada Premium',
    brandColor: 0xFFFF6000, // verify
    logoAsset: 'assets/logos/hepsiburada_premium.svg',
    defaultCategory: SubscriptionCategory.shopping,
    aliases: ['hepsiburada', 'hepsiburada premium', 'premium hepsiburada'],
  ),
  BrandCatalogEntry(
    serviceKey: 'pazarama_premium',
    displayName: 'Pazarama Premium',
    brandColor: 0xFF6D28D9, // verify
    logoAsset: 'assets/logos/pazarama_premium.svg',
    defaultCategory: SubscriptionCategory.shopping,
    aliases: ['pazarama', 'pazarama premium'],
  ),

  // --- Connectivity (internet & mobile) ---
  BrandCatalogEntry(
    serviceKey: 'turkcell',
    displayName: 'Turkcell',
    brandColor: 0xFFFFC900, // verify
    logoAsset: 'assets/logos/turkcell.svg',
    defaultCategory: SubscriptionCategory.connectivity,
    aliases: ['turkcell'],
  ),
  BrandCatalogEntry(
    serviceKey: 'vodafone',
    displayName: 'Vodafone',
    brandColor: 0xFFE60000,
    logoAsset: 'assets/logos/vodafone.svg',
    defaultCategory: SubscriptionCategory.connectivity,
    aliases: ['vodafone', 'vodafone red'],
  ),
  BrandCatalogEntry(
    serviceKey: 'turk_telekom',
    displayName: 'Türk Telekom',
    brandColor: 0xFF005AAB, // verify
    logoAsset: 'assets/logos/turk_telekom.svg',
    defaultCategory: SubscriptionCategory.connectivity,
    aliases: ['turk telekom', 'türk telekom', 'ttnet', 'tt'],
  ),
  BrandCatalogEntry(
    serviceKey: 'superonline',
    displayName: 'Turkcell Superonline',
    brandColor: 0xFF1BA0E2, // verify
    logoAsset: 'assets/logos/superonline.svg',
    defaultCategory: SubscriptionCategory.connectivity,
    aliases: ['superonline', 'turkcell superonline'],
  ),
  BrandCatalogEntry(
    serviceKey: 'turknet',
    displayName: 'TurkNet',
    brandColor: 0xFFEC1C24, // verify
    logoAsset: 'assets/logos/turknet.svg',
    defaultCategory: SubscriptionCategory.connectivity,
    aliases: ['turknet', 'turk net'],
  ),
  BrandCatalogEntry(
    serviceKey: 'millenicom',
    displayName: 'Millenicom',
    brandColor: 0xFF00529B, // verify
    logoAsset: 'assets/logos/millenicom.svg',
    defaultCategory: SubscriptionCategory.connectivity,
    aliases: ['millenicom'],
  ),

  // --- Gaming ---
  BrandCatalogEntry(
    serviceKey: 'steam',
    displayName: 'Steam',
    brandColor: 0xFF1B2838,
    logoAsset: 'assets/logos/steam.svg',
    defaultCategory: SubscriptionCategory.gaming,
    aliases: ['steam'],
  ),
  BrandCatalogEntry(
    serviceKey: 'xbox_game_pass',
    displayName: 'Xbox Game Pass',
    brandColor: 0xFF107C10,
    logoAsset: 'assets/logos/xbox_game_pass.svg',
    defaultCategory: SubscriptionCategory.gaming,
    aliases: ['xbox', 'game pass', 'xbox game pass', 'gamepass'],
  ),
  BrandCatalogEntry(
    serviceKey: 'playstation_plus',
    displayName: 'PlayStation Plus',
    brandColor: 0xFF0070D1,
    logoAsset: 'assets/logos/playstation_plus.svg',
    defaultCategory: SubscriptionCategory.gaming,
    aliases: ['playstation', 'ps plus', 'playstation plus', 'ps+'],
  ),

  // --- Education ---
  BrandCatalogEntry(
    serviceKey: 'duolingo',
    displayName: 'Duolingo',
    brandColor: 0xFF58CC02,
    logoAsset: 'assets/logos/duolingo.svg',
    defaultCategory: SubscriptionCategory.education,
    aliases: ['duolingo', 'duolingo super', 'duolingo max'],
  ),

  // --- Health (wellness / fitness) ---
  BrandCatalogEntry(
    serviceKey: 'headspace',
    displayName: 'Headspace',
    brandColor: 0xFFF47D31,
    logoAsset: 'assets/logos/headspace.svg',
    defaultCategory: SubscriptionCategory.health,
    aliases: ['headspace'],
  ),
  BrandCatalogEntry(
    serviceKey: 'strava',
    displayName: 'Strava',
    brandColor: 0xFFFC4C02,
    logoAsset: 'assets/logos/strava.svg',
    defaultCategory: SubscriptionCategory.health,
    aliases: ['strava', 'strava premium'],
  ),
  BrandCatalogEntry(
    serviceKey: 'calm',
    displayName: 'Calm',
    brandColor: 0xFF2A6FB6, // verify
    logoAsset: 'assets/logos/calm.svg',
    defaultCategory: SubscriptionCategory.health,
    aliases: ['calm'],
  ),

  // --- Books / audio ---
  BrandCatalogEntry(
    serviceKey: 'audible',
    displayName: 'Audible',
    brandColor: 0xFFF8991C,
    logoAsset: 'assets/logos/audible.svg',
    defaultCategory: SubscriptionCategory.books,
    aliases: ['audible'],
  ),
  BrandCatalogEntry(
    serviceKey: 'storytel',
    displayName: 'Storytel',
    brandColor: 0xFFEF3E42, // verify
    logoAsset: 'assets/logos/storytel.svg',
    defaultCategory: SubscriptionCategory.books,
    aliases: ['storytel'],
  ),

  // --- Security ---
  BrandCatalogEntry(
    serviceKey: 'nordvpn',
    displayName: 'NordVPN',
    brandColor: 0xFF4687FF,
    logoAsset: 'assets/logos/nordvpn.svg',
    defaultCategory: SubscriptionCategory.security,
    aliases: ['nordvpn', 'nord vpn'],
  ),

  // --- Other (creator / misc) ---
  BrandCatalogEntry(
    serviceKey: 'twitch',
    displayName: 'Twitch',
    brandColor: 0xFF9146FF,
    logoAsset: 'assets/logos/twitch.svg',
    defaultCategory: SubscriptionCategory.other,
    aliases: ['twitch', 'twitch turbo'],
  ),
  BrandCatalogEntry(
    serviceKey: 'patreon',
    displayName: 'Patreon',
    brandColor: 0xFFF96854,
    logoAsset: 'assets/logos/patreon.svg',
    defaultCategory: SubscriptionCategory.other,
    aliases: ['patreon'],
  ),
];

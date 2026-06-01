import 'package:subsy/features/subscriptions/domain/enums.dart';

/// frankfurter rate endpoint. The legacy `api.frankfurter.app` host 301-redirects
/// to `.dev`; we call `.dev` directly to avoid the extra hop (research.md D1).
const String kFrankfurterLatestUrl = 'https://api.frankfurter.dev/v1/latest';

/// Base the rates are fetched relative to. ECB-native → EUR (no pivot rounding).
const Currency kRateBaseCurrency = Currency.eur;

/// Non-base symbols requested from the API. The base is implicitly 1.0 and is
/// injected client-side (the API omits the base from its `rates` map).
const List<Currency> kRateSymbols = [Currency.usd, Currency.tryl];

/// Target currency the unified total is expressed in when the user has not
/// chosen one (FR-008).
const Currency kDefaultTargetCurrency = Currency.tryl;

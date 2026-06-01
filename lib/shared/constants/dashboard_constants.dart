// Constants for dashboard derived calculations (no magic numbers).

/// Weeks per year, for weekly→monthly normalization.
const int kWeeksPerYear = 52;

/// Months per year, for yearly→monthly normalization.
const int kMonthsPerYear = 12;

/// Beyond this many days, the upcoming-payment label shows an absolute date
/// instead of "N gün sonra".
const int kRelativeDayThreshold = 30;

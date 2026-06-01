import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/data/isar_subscription_repository.dart';
import 'package:subsy/features/subscriptions/data/subscription_entity.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// US1 acceptance: durable, offline, on-device CRUD. Runs against a real Isar
/// instance in a temp directory (maps SC-001/SC-002/SC-006).
void main() {
  late Directory tempDir;
  var counter = 0;

  setUpAll(() async {
    // Downloads the Isar binary for the test VM (one-time on the dev machine).
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('subsy_test_');
  });

  tearDown(() async {
    for (final name in Isar.instanceNames.toList()) {
      await Isar.getInstance(name)?.close(deleteFromDisk: true);
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<Isar> openIsar() {
    final name = 'subsy_test_${counter++}';
    return Isar.open([SubscriptionEntitySchema], directory: tempDir.path, name: name);
  }

  Subscription sample({String name = 'Netflix', double amount = 149.99}) {
    final now = DateTime.utc(2026, 6, 1, 12);
    return Subscription(
      name: name,
      amount: amount,
      currency: Currency.tryl,
      billingPeriod: BillingPeriod.monthly,
      nextRenewalDate: DateTime.utc(2026, 6, 15),
      category: SubscriptionCategory.streaming,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('adds and reads back a subscription with a stable id', () async {
    final isar = await openIsar();
    final repo = IsarSubscriptionRepository(isar);

    final added = await repo.add(sample());
    final saved = (added as Success<Subscription>).value;
    expect(saved.id, isNotNull);

    final fetched = await repo.getById(saved.id!);
    final got = (fetched as Success<Subscription?>).value;
    expect(got, equals(saved));
    expect(got!.name, 'Netflix');
    expect(got.currency, Currency.tryl);
    expect(got.billingPeriod, BillingPeriod.monthly);
  });

  test('persists across an app restart (close + reopen)', () async {
    final isar1 = await openIsar();
    final repo1 = IsarSubscriptionRepository(isar1);
    final added = await repo1.add(sample(name: 'Spotify'));
    final id = (added as Success<Subscription>).value.id!;
    await isar1.close();

    // Reopen the SAME directory + name → data survives.
    final isar2 = await Isar.open(
      [SubscriptionEntitySchema],
      directory: tempDir.path,
      name: isar1.name,
    );
    final repo2 = IsarSubscriptionRepository(isar2);
    final fetched = await repo2.getById(id);
    final got = (fetched as Success<Subscription?>).value;
    expect(got, isNotNull);
    expect(got!.name, 'Spotify');
  });

  test('update keeps the same id and persists changes', () async {
    final isar = await openIsar();
    final repo = IsarSubscriptionRepository(isar);
    final saved = (await repo.add(sample()) as Success<Subscription>).value;

    final edited = saved.copyWith(
      amount: 199.99,
      nextRenewalDate: DateTime.utc(2026, 7, 15),
    );
    final updated = (await repo.update(edited) as Success<Subscription>).value;
    expect(updated.id, saved.id);

    final got = (await repo.getById(saved.id!) as Success<Subscription?>).value;
    expect(got!.amount, 199.99);
    expect(got.nextRenewalDate, DateTime.utc(2026, 7, 15));
  });

  test('update of a missing record returns NotFoundError', () async {
    final isar = await openIsar();
    final repo = IsarSubscriptionRepository(isar);
    final res = await repo.update(sample().copyWith(id: 999));
    expect(res, isA<Failure<Subscription>>());
    expect((res as Failure<Subscription>).error, isA<NotFoundError>());
  });

  test('delete removes the record', () async {
    final isar = await openIsar();
    final repo = IsarSubscriptionRepository(isar);
    final saved = (await repo.add(sample()) as Success<Subscription>).value;

    await repo.delete(saved.id!);
    final got = (await repo.getById(saved.id!) as Success<Subscription?>).value;
    expect(got, isNull);

    final c = (await repo.count() as Success<int>).value;
    expect(c, 0);
  });

  test('count reflects stored records', () async {
    final isar = await openIsar();
    final repo = IsarSubscriptionRepository(isar);
    await repo.add(sample(name: 'A'));
    await repo.add(sample(name: 'B'));
    expect((await repo.count() as Success<int>).value, 2);
  });

  test('operations on a closed instance return a typed StorageError', () async {
    final isar = await openIsar();
    final repo = IsarSubscriptionRepository(isar);
    await isar.close();

    final res = await repo.getAll();
    expect(res, isA<Failure<List<Subscription>>>());
    expect((res as Failure<List<Subscription>>).error, isA<StorageError>());
  });
}

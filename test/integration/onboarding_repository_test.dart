import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:subsy/features/onboarding/data/isar_onboarding_repository.dart';
import 'package:subsy/features/onboarding/data/onboarding_state_entity.dart';

/// US1 — onboarding completion persistence (maps SC-002).
void main() {
  late Directory tempDir;
  var counter = 0;

  setUpAll(() => Isar.initializeIsarCore(download: true));

  setUp(() => tempDir = Directory.systemTemp.createTempSync('subsy_onb_'));

  tearDown(() async {
    for (final name in Isar.instanceNames.toList()) {
      await Isar.getInstance(name)?.close(deleteFromDisk: true);
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<Isar> openIsar() => Isar.open(
        [OnboardingStateEntitySchema],
        directory: tempDir.path,
        name: 'onb_${counter++}',
      );

  test('isCompleted is false when nothing is saved', () async {
    final repo = IsarOnboardingRepository(await openIsar());
    expect(await repo.isCompleted(), isFalse);
  });

  test('markCompleted flips the flag and is idempotent', () async {
    final repo = IsarOnboardingRepository(await openIsar());
    await repo.markCompleted();
    expect(await repo.isCompleted(), isTrue);
    await repo.markCompleted(); // no second row, still true
    expect(await repo.isCompleted(), isTrue);
  });

  test('completion survives a reopen of the same database', () async {
    final isar1 = await openIsar();
    final name = isar1.name;
    await IsarOnboardingRepository(isar1).markCompleted();
    await isar1.close();

    final isar2 = await Isar.open(
      [OnboardingStateEntitySchema],
      directory: tempDir.path,
      name: name,
    );
    expect(await IsarOnboardingRepository(isar2).isCompleted(), isTrue);
  });
}

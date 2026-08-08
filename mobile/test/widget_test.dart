import 'package:flutter_test/flutter_test.dart';
import 'package:screenguard/models.dart';

void main() {
  TodayStatus status({
    int? limitMinutes = 60,
    int adjustmentsMinutes = 0,
    int usedMinutes = 0,
    String enforce = 'allow',
    bool manualLocked = false,
  }) => TodayStatus(
        date: '2026-08-08',
        limitMinutes: limitMinutes,
        usedMinutes: usedMinutes,
        adjustmentsMinutes: adjustmentsMinutes,
        remainingMinutes: 999,
        enforce: enforce,
        manualLocked: manualLocked,
      );

  test('profile defaults preserve tasks on lock to false when absent', () {
    final profile = Profile.fromJson({
      'profile': {'id': 'profile-id', 'display_name': 'Test'},
      'schedules': [],
      'daily_limits': [],
      'agent_users': [],
    });

    expect(profile.preserveTasksOnLock, isFalse);
    expect(profile.manualLocked, isFalse);
  });

  test('profile parses preserve tasks on lock when enabled', () {
    final profile = Profile.fromJson({
      'profile': {'id': 'profile-id', 'display_name': 'Test'},
      'preserve_tasks_on_lock': true,
      'schedules': [],
      'daily_limits': [],
      'agent_users': [],
    });

    expect(profile.preserveTasksOnLock, isTrue);
  });

  test('profile parses manual lock when enabled', () {
    final profile = Profile.fromJson({
      'profile': {'id': 'profile-id', 'display_name': 'Test'},
      'manual_locked': true,
      'schedules': [],
      'daily_limits': [],
      'agent_users': [],
    });

    expect(profile.manualLocked, isTrue);
  });

  test('status missing manual lock defaults to false', () {
    final status = TodayStatus.fromJson({
      'date': '2026-08-08',
      'adjustments_minutes': -90,
    });

    expect(status.manualLocked, isFalse);
    expect(status.canUnlock, isFalse);
  });

  test('unlock availability uses manual lock, not adjustments', () {
    final status = TodayStatus.fromJson({
      'date': '2026-08-08',
      'adjustments_minutes': 30,
      'manual_locked': true,
    });

    expect(status.manualLocked, isTrue);
    expect(status.canUnlock, isTrue);
  });

  test('positive adjustment is included in effective allowance', () {
    final today = status(
      limitMinutes: 14,
      adjustmentsMinutes: 210,
      usedMinutes: 211,
    );

    expect(today.effectiveAllowanceMinutes, 224);
    expect(today.displayRemainingMinutes, 13);
  });

  test('negative adjustment reduces effective allowance', () {
    final today = status(
      limitMinutes: 60,
      adjustmentsMinutes: -30,
      usedMinutes: 10,
    );

    expect(today.effectiveAllowanceMinutes, 30);
    expect(today.displayRemainingMinutes, 20);
  });

  test('effective allowance and remaining are clamped to zero', () {
    expect(
      status(limitMinutes: 60, adjustmentsMinutes: -90)
          .effectiveAllowanceMinutes,
      0,
    );
    expect(status(limitMinutes: 60, usedMinutes: 90).displayRemainingMinutes, 0);
  });

  test('manual lock does not affect displayed remaining', () {
    final today = status(
      limitMinutes: 60,
      usedMinutes: 15,
      manualLocked: true,
    );

    expect(today.displayRemainingMinutes, 45);
  });

  test('ordinary enforcement lock does not affect displayed remaining', () {
    final today = status(
      limitMinutes: 60,
      usedMinutes: 15,
      enforce: 'lock',
    );

    expect(today.displayRemainingMinutes, 45);
  });

  test('manual lock takes precedence in displayed lock state', () {
    final today = status(enforce: 'lock', manualLocked: true);

    expect(today.displayLockState, TodayLockState.manuallyLocked);
  });

  test('ordinary enforcement lock selects locked state', () {
    expect(status(enforce: 'lock').displayLockState, TodayLockState.locked);
    expect(status().displayLockState, isNull);
  });

  test('unlimited profile stays unlimited', () {
    final today = status(
      limitMinutes: null,
      adjustmentsMinutes: 210,
      usedMinutes: 211,
      manualLocked: true,
    );

    expect(today.effectiveAllowanceMinutes, isNull);
    expect(today.displayRemainingMinutes, isNull);
    expect(today.displayLockState, TodayLockState.manuallyLocked);
  });

  test('unlock availability follows only manual lock state', () {
    expect(status(adjustmentsMinutes: -90).canUnlock, isFalse);
    expect(status(enforce: 'lock').canUnlock, isFalse);
    expect(status(manualLocked: true).canUnlock, isTrue);
  });
}

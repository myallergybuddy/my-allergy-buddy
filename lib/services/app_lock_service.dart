import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

class PasscodeCheck {
  final bool success;
  final Duration? wait;
  final int attemptsRemaining;

  const PasscodeCheck({
    required this.success,
    this.wait,
    this.attemptsRemaining = 0,
  });
}

/// Gates app access when the Settings passcode lock is on.
class AppLockService {
  static const backgroundGrace = Duration(seconds: 15);
  static const _failKey = 'passcode_fail_count';
  static const _untilKey = 'passcode_lockout_until';

  /// True after a correct PIN in this process. A cold start starts locked.
  static bool sessionUnlocked = false;
  static DateTime? _backgroundedAt;

  static void noteBackground() {
    _backgroundedAt = DateTime.now();
  }

  static bool backgroundGraceElapsed() {
    final at = _backgroundedAt;
    _backgroundedAt = null;
    if (at == null) return false;
    return DateTime.now().difference(at) >= backgroundGrace;
  }

  static Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('passcode_lock_enabled') ?? false;
    final stored = prefs.getString('passcode') ?? '';
    return enabled && stored.isNotEmpty;
  }

  static Future<bool> shouldLockNow() async {
    if (sessionUnlocked) return false;
    return isLockEnabled();
  }

  static Future<void> clearFailures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_failKey, 0);
    await prefs.remove(_untilKey);
  }

  static Future<PasscodeCheck> unlock(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final until = prefs.getInt(_untilKey) ?? 0;
    if (until > now) {
      return PasscodeCheck(
        success: false,
        wait: Duration(milliseconds: until - now),
      );
    }

    final stored = prefs.getString('passcode') ?? '';
    if (stored.isEmpty || pin.length != 4) {
      return const PasscodeCheck(success: false);
    }

    final matched = await EncryptionService.passcodeMatches(stored, pin);
    if (matched) {
      await prefs.setInt(_failKey, 0);
      await prefs.remove(_untilKey);
      sessionUnlocked = true;
      return const PasscodeCheck(success: true);
    }

    final fails = (prefs.getInt(_failKey) ?? 0) + 1;
    await prefs.setInt(_failKey, fails);
    if (fails % 5 == 0) {
      final level = fails ~/ 5;
      final seconds = level <= 1 ? 30 : level == 2 ? 120 : 600;
      await prefs.setInt(
        _untilKey,
        DateTime.now().add(Duration(seconds: seconds)).millisecondsSinceEpoch,
      );
      return PasscodeCheck(
        success: false,
        wait: Duration(seconds: seconds),
      );
    }
    return PasscodeCheck(
      success: false,
      attemptsRemaining: 5 - (fails % 5),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_lock_service.dart';

/// Covers the app until the passcode is entered when the lock is on.
class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _ready = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final locked = await AppLockService.shouldLockNow();
    if (!mounted) return;
    setState(() {
      _locked = locked;
      _ready = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      AppLockService.noteBackground();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _relockIfNeeded();
    }
  }

  Future<void> _relockIfNeeded() async {
    if (!AppLockService.backgroundGraceElapsed()) return;
    final enabled = await AppLockService.isLockEnabled();
    if (!enabled || !mounted) return;
    AppLockService.sessionUnlocked = false;
    setState(() => _locked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const ColoredBox(color: Colors.white);
    }
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: AppLockScreen(
              onUnlocked: () {
                if (!mounted) return;
                setState(() => _locked = false);
              },
            ),
          ),
      ],
    );
  }
}

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _message;
  bool _checking = false;
  Timer? _lockoutTimer;
  Duration? _wait;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startLockoutCountdown(Duration wait) {
    _lockoutTimer?.cancel();
    var remaining = wait;
    setState(() => _wait = remaining);
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= const Duration(seconds: 1);
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remaining <= Duration.zero) {
        timer.cancel();
        setState(() {
          _wait = null;
          _message = null;
        });
        return;
      }
      setState(() => _wait = remaining);
    });
  }

  Future<void> _submit() async {
    if (_checking || _wait != null) return;
    final pin = _controller.text;
    if (pin.length != 4) {
      setState(() => _message = 'Enter your 4-digit passcode');
      return;
    }
    setState(() => _checking = true);
    final result = await AppLockService.unlock(pin);
    if (!mounted) return;
    if (result.success) {
      widget.onUnlocked();
      return;
    }
    _controller.clear();
    if (result.wait != null) {
      _startLockoutCountdown(result.wait!);
      setState(() {
        _checking = false;
        _message = 'Too many attempts. Try again in ${result.wait!.inSeconds} seconds.';
      });
      return;
    }
    final left = result.attemptsRemaining;
    setState(() {
      _checking = false;
      _message = left > 0
          ? 'Incorrect passcode. $left attempts left before a wait.'
          : 'Incorrect passcode';
    });
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _wait != null;
    return BackButtonListener(
      onBackButtonPressed: () async => true,
      child: Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, color: Color(0xFF4A9E9C), size: 48),
              const SizedBox(height: 16),
              Text(
                'My Allergy Buddy',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A9E9C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your passcode to open the app',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !waiting && !_checking,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.nunito(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  waiting
                      ? 'Too many attempts. Try again in ${_wait!.inSeconds} seconds.'
                      : _message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 14, color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: waiting || _checking ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9E9C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Unlock',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

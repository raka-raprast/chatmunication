import 'dart:async';

import 'package:chatmunication/features/auth/service/auth_service.dart';
import 'package:chatmunication/features/auth/widgets/auth_background.dart';
import 'package:chatmunication/features/auth/widgets/auth_header_logo.dart';
import 'package:chatmunication/features/users/user_list_screen.dart';
import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// How long the "Resend OTP" link stays disabled after an OTP is sent —
/// covers both the initial send that got the user here and every
/// subsequent resend, so it can't be spammed.
const _resendCooldown = Duration(seconds: 30);

class OtpScreen extends StatefulWidget {
  final String identifier;
  final String password;
  const OtpScreen({
    super.key,
    required this.identifier,
    required this.password,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final authService = AuthService();

  bool isLoading = false;
  bool isResending = false;
  String? error;

  Timer? _cooldownTimer;
  int _secondsLeft = _resendCooldown.inSeconds;

  final List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  String get _enteredOtp => controllers.map((c) => c.text).join();

  /// Normal single-digit typing/backspace just moves focus — pasted
  /// multi-digit content never reaches here since [_OtpDigitFormatter]
  /// intercepts it per field before Flutter's own input pipeline would
  /// otherwise clip it down to this field's single character.
  void _onOtpFieldChanged(int index, String value) {
    setState(() => error = null);
    if (value.length == 1 && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    _maybeAutoVerify();
  }

  /// Spreads a pasted code (or anything that put more than one digit into
  /// a single field at once) across [startIndex] and the fields after it.
  void _distributeDigits(int startIndex, String digits) {
    setState(() => error = null);
    for (var i = 0; i < digits.length && startIndex + i < 6; i++) {
      controllers[startIndex + i].text = digits[i];
    }
    final lastFilled = (startIndex + digits.length - 1).clamp(0, 5);
    focusNodes[lastFilled].requestFocus();
    _maybeAutoVerify();
  }

  void _maybeAutoVerify() {
    final otp = _enteredOtp;
    if (otp.length == 6 && !otp.contains(RegExp(r'\D'))) {
      _verifyOtp();
    }
  }

  void _verifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length != 6 || otp.contains(RegExp(r'\D'))) {
      setState(() => error = 'Enter the 6-digit OTP');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = await authService.verifyOtp(widget.identifier, otp);

      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                UserListScreen(token: user.token ?? '', userId: user.id),
          ),
        );
      } else {
        setState(() => error = 'Invalid OTP');
      }
    } catch (e) {
      setState(() => error = 'Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0 || isResending) return;

    setState(() {
      isResending = true;
      error = null;
    });
    try {
      final sent = await authService.sendOtp(
        widget.identifier,
        widget.password,
      );
      if (!mounted) return;
      if (sent) {
        for (final c in controllers) {
          c.clear();
        }
        focusNodes.first.requestFocus();
        _startCooldown();
      } else {
        setState(() => error = 'Failed to resend OTP');
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Error: $e');
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft == 0 && !isResending;

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            const Positioned.fill(child: AuthBackground()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BackButton(onTap: () => Navigator.pop(context)),
                    const SizedBox(height: 24),
                    const AuthHeaderLogo(
                      iconSize: 48,
                      fontSize: 26,
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF12213B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Check your email for 6 digits one time password',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 44,
                          height: 56,
                          child: TextField(
                            controller: controllers[index],
                            focusNode: focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              _OtpDigitFormatter(
                                onPaste: (digits) =>
                                    _distributeDigits(index + 1, digits),
                              ),
                            ],
                            onChanged: (value) =>
                                _onOtpFieldChanged(index, value),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF12213B),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: CMColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: canResend ? _resendOtp : null,
                      child: Row(
                        children: [
                          Text(
                            canResend
                                ? 'Resend OTP'
                                : 'Resend OTP in ${_secondsLeft}s',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: canResend
                                  ? CMColors.primaryVariant
                                  : CMColors.hint,
                            ),
                          ),
                          if (isResending) ...[
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CMColors.primaryVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    if (isLoading) ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: SpinKitFoldingCube(
                          color: CMColors.primaryVariant,
                          size: 32.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Caps each OTP box's own controller at one digit while surfacing
/// anything beyond that (i.e. a multi-digit paste) via [onPaste], instead
/// of relying on `TextField.maxLength`, which clips a paste down to a
/// single character *before* `onChanged` ever sees the rest of it.
class _OtpDigitFormatter extends TextInputFormatter {
  _OtpDigitFormatter({required this.onPaste});

  final void Function(String extraDigits) onPaste;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    if (digits.length > 1) {
      onPaste(digits.substring(1));
    }
    final first = digits.substring(0, 1);
    return TextEditingValue(
      text: first,
      selection: TextSelection.collapsed(offset: first.length),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          PhosphorIconsRegular.caretLeft,
          size: 18,
          color: Color(0xFF12213B),
        ),
      ),
    );
  }
}

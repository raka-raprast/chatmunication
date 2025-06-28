import 'package:chatmunication/shared/theme/colors.dart';
import 'package:chatmunication/shared/theme/textstyle.dart';
import 'package:chatmunication/shared/ui/components/scaffold.dart';
import 'package:chatmunication/shared/ui/components/textfield.dart';
import 'package:flutter/material.dart';
import 'package:chatmunication/features/auth/service/auth_service.dart';
import 'package:chatmunication/features/users/user_list_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class OtpScreen extends StatefulWidget {
  final String identifier;
  const OtpScreen({super.key, required this.identifier});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final authService = AuthService();

  bool isLoading = false;
  String? error;

  final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => controllers.map((c) => c.text).join();

  void _onOtpFieldChanged(int index, String value) {
    setState(() {
      error = null; // Clear error if not valid
    });
    if (value.length == 1 && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    // Auto trigger verify if all 6 digits are filled
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
            builder: (_) => UserListScreen(
              token: user.token ?? '',
              userId: user.id ?? '',
            ),
          ),
        );
      } else {
        setState(() => error = 'Invalid OTP');
      }
    } catch (e) {
      setState(() => error = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CMScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CMColors.primaryVariant,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: CMColors.surface,
              )),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              height: 100,
              width: 100,
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              "Verify OTP",
              style: CMTextStyle.title,
            ),
            Text(
              "Check your email for 6 digits one time password",
              style: CMTextStyle.text,
            ),
            SizedBox(
              height: 24,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  child: CMTextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (value) => _onOtpFieldChanged(index, value),
                  ),
                );
              }),
            ),
            Text("Resend OTP",
                style: CMTextStyle.text.copyWith(
                  color: CMColors.primaryVariant,
                  fontWeight: FontWeight.w600,
                )),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                  child: SpinKitFoldingCube(
                color: CMColors.surface,
                size: 40.0,
              ))
          ],
        ),
      ),
    );
  }
}

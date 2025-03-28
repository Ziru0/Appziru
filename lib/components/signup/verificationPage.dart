import 'package:flutter/material.dart';
import 'profilesetup.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String otp;

  const OTPVerificationPage({super.key, required this.email, required this.otp});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  TextEditingController otpController = TextEditingController();

  verifyOtp() {
    if (otpController.text.trim() == widget.otp) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Profilesetup()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Enter the OTP sent to your email'),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyOtp,
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

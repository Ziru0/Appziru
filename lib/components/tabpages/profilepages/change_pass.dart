import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPasswordController.text,
      );

      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );

      Navigator.pop(context); // Close the page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(labelText: "Current Password"),
                obscureText: true,
                validator: (value) => value!.isEmpty ? "Enter current password" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: "New Password"),
                obscureText: true,
                validator: (value) => value!.length < 6 ? "Password must be at least 6 characters" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: "Confirm New Password"),
                obscureText: true,
                validator: (value) =>
                value != _newPasswordController.text ? "Passwords do not match" : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _changePassword,
                child: const Text("Change Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

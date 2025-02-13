import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lage/components/signup/login_page.dart';
import 'package:lage/components/signup/signup_page.dart';
import 'package:lage/components/tabpagesDriver/homescreendriver.dart';
import 'package:lage/components/views/homescreen.dart';
import 'package:lage/dbHelper/monggodb.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              return FutureBuilder(
                future: MongoDatabase.getOne(user.uid),
                builder: (context, AsyncSnapshot<Map<String, dynamic>?> roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (roleSnapshot.hasError || roleSnapshot.data == null) {
                    // Navigate to LoginPage when an error occurs
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    });
                    return const SizedBox(); // Return an empty widget to avoid build errors
                  } else {
                    final role = roleSnapshot.data?['role'];

                    if (role == 'Passenger') {
                      return const HomeScreen();
                    } else if (role == 'Driver') {
                      return HomeScreenDriver();
                    } else {
                      return const SignupPage();
                    }
                  }
                },
              );
            } else {
              return const LoginPage();
            }
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

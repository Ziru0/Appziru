import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lage/components/signup/login_page.dart';
import 'package:lage/components/tabpages/home_tab.dart';
import 'package:lage/dbHelper/MongoDBModeluser.dart';
import '../dbHelper/monggodb.dart';
import 'drivers/driver_home.dart';

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
                    return const Center(child: Text('Error fetching user role'));
                  } else {
                    final role = roleSnapshot.data?['role'];
                    if (role == 'Passenger') {
                      return const HomeTabPage();
                    } else if (role == 'Driver') {
                      return const DriverHomePage();
                    } else {
                      return const Center(child: Text('Invalid role'));
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

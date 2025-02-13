import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy Policy"),

        backgroundColor: Colors.white, // You can change this to your desired color
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // This will take the user back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Privacy Policy",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "At Omoda, we value your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information. Please read it carefully.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 16),
              Text(
                "1. Information Collection",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8),
              Text(
                "We collect personal information such as your name, email, and other necessary data when you use our app. This information is used to provide services, enhance user experience, and for security purposes.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 16),
              Text(
                "2. Data Usage",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8),
              Text(
                "Your data is used to process transactions, personalize content, and communicate with you regarding updates and offers. We will not share your data with third parties without your consent, except when required by law.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 16),
              Text(
                "3. Security",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8),
              Text(
                "We take the protection of your personal data seriously and implement a variety of security measures to prevent unauthorized access and data breaches.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 16),
              Text(
                "4. Changes to This Privacy Policy",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8),
              Text(
                "We may update this privacy policy periodically. We encourage you to review this policy regularly to stay informed about how we are protecting your data.",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 16),
              Text(
                "5. Contact Us",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8),
              Text(
                "If you have any questions about this privacy policy, please contact us at [email address].",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing Policy',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              '1. Pricing Structure',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5.0),
            const Text(
              'Our pricing is calculated based on the distance of the ride and demand at the time of booking. Additional charges may apply for peak hours or special services.',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 15.0),
            const Text(
              '2. Payment Methods',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5.0),
            const Text(
              'We accept payments through credit cards, debit cards, and digital wallets. All transactions are secure and encrypted.',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 15.0),
            const Text(
              '3. Refund Policy',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5.0),
            const Text(
              'Cancellations made within a specified timeframe are eligible for a full refund. No refunds will be provided for last-minute cancellations or no-shows.',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 15.0),
            const Text(
              '4. Price Changes',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5.0),
            const Text(
              'We reserve the right to modify pricing at any time without prior notice. Updated prices will be reflected in the app at the time of booking.',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 30.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('I Agree'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

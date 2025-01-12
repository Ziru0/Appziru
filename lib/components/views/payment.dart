import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Payment History",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white, // Change text color for contrast
          ),
        ),
        backgroundColor: Color(0xFF181C14), // Change AppBar background color to white
        iconTheme: IconThemeData(color: Colors.white), // Change icon color (e.g., back button)
      ),

      body: Column(
        children: [
          // Payment Summary Section
          _buildPaymentSummary(),

          // Payment History Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Transaction History",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Transaction List
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  // Widget for Payment Summary
  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Color(0xFF181C14),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryTile(
            title: "Total Paid",
            value: "\$1,245",
            icon: Icons.payment,
            color: Colors.green,
          ),
          _buildSummaryTile(
            title: "Pending Payments",
            value: "\$200",
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
          _buildSummaryTile(
            title: "Refunds",
            value: "\$50",
            icon: Icons.money_off,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // Helper for Summary Tiles
  Widget _buildSummaryTile(
      {required String title,
        required String value,
        required IconData icon,
        required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  // Widget for Transaction List
  Widget _buildTransactionList() {
    final transactions = [
      {"date": "Dec 1, 2024", "amount": "\$150", "status": "Completed"},
      {"date": "Nov 29, 2024", "amount": "\$200", "status": "Pending"},
      {"date": "Nov 20, 2024", "amount": "\$50", "status": "Refunded"},
    ];

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              transaction['status'] == "Completed"
                  ? Icons.check_circle
                  : transaction['status'] == "Pending"
                  ? Icons.hourglass_empty
                  : Icons.cancel,
              color: transaction['status'] == "Completed"
                  ? Colors.green
                  : transaction['status'] == "Pending"
                  ? Colors.orange
                  : Colors.red,
            ),
            title: Text(
              transaction['amount']!,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            subtitle: Text(
              transaction['date']!,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            trailing: Text(
              transaction['status']!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: transaction['status'] == "Completed"
                    ? Colors.green
                    : transaction['status'] == "Pending"
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}

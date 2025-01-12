import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Support",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF181C14), // Dark theme background
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Container(
        color: const Color(0xFF181C14), // Dark theme background
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // FAQ Section
            _buildFAQSection(),

            const SizedBox(height: 20),

            // Contact Us Section
            _buildContactUsSection(),

            const SizedBox(height: 20),

            // Submit Inquiry Section
            _buildSubmitInquirySection(),
          ],
        ),
      ),
    );
  }

  // Widget for FAQ Section
  Widget _buildFAQSection() {
    return Card(
      color: const Color(0xFF282C21), // Dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.question_answer, color: Colors.white),
        title: Text(
          "FAQ",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward, color: Colors.white),
        onTap: () {
          // Navigate to FAQ page (implement as needed)
        },
      ),
    );
  }

  // Widget for Contact Us Section
  Widget _buildContactUsSection() {
    return Card(
      color: const Color(0xFF282C21), // Dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.contact_support, color: Colors.white),
        title: Text(
          "Contact Support",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward, color: Colors.white),
        onTap: () {
          // Navigate to Contact Support page (implement as needed)
        },
      ),
    );
  }

  // Widget for Submit Inquiry Section
  Widget _buildSubmitInquirySection() {
    return Card(
      color: const Color(0xFF282C21), // Dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.mail, color: Colors.white),
        title: Text(
          "Submit Inquiry",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward, color: Colors.white),
        onTap: () {
          // Navigate to Submit Inquiry page (implement as needed)
        },
      ),
    );
  }
}

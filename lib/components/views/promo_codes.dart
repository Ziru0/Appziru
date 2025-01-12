import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoCodePage extends StatefulWidget {
  const PromoCodePage({super.key});

  @override
  _PromoCodePageState createState() => _PromoCodePageState();
}

class _PromoCodePageState extends State<PromoCodePage> {
  final _promoCodeController = TextEditingController();
  String _promoStatus = ""; // To hold the promo code status (valid/invalid)
  double _discountAmount = 0.0; // To hold the discount value

  // Function to check the promo code
  void _applyPromoCode() {
    setState(() {
      if (_promoCodeController.text == "SAVE20") {
        _promoStatus = "Promo code applied!";
        _discountAmount = 20.0; // For example, 20% discount
      } else {
        _promoStatus = "Invalid promo code";
        _discountAmount = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Apply Promo Code",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF181C14), // Dark theme
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: const Color(0xFF181C14), // Dark theme background
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Text(
              "Enter Promo Code",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Promo Code Text Field
            TextField(
              controller: _promoCodeController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF282C21), // Dark text field background
                labelText: "Promo Code",
                labelStyle: GoogleFonts.poppins(color: Colors.grey),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Apply Button
            ElevatedButton(
              onPressed: _applyPromoCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3C2F), // Dark button color
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Apply Promo Code",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // Promo Code Status
            Text(
              _promoStatus,
              style: GoogleFonts.poppins(fontSize: 16, color: _promoStatus == "Promo code applied!" ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 10),

            // Discount Amount
            if (_promoStatus == "Promo code applied!") ...[
              Text(
                "Discount: \$$_discountAmount",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

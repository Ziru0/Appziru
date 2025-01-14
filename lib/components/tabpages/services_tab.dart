import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServicesTabPage extends StatelessWidget {
  const ServicesTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Our Services",
          style: GoogleFonts.poppins(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF181C14),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Explore Our Services",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We offer a variety of services to meet your needs.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // List of Services
            Expanded(
              child: ListView(
                children: [
                  buildServiceItem(
                    icon: Icons.local_taxi,
                    title: "Ride Sharing",
                    description: "Affordable rides for your daily commute.",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Navigate to Ride Sharing"),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  buildServiceItem(
                    icon: Icons.shopping_bag,
                    title: "Package Delivery",
                    description: "Deliver your packages with ease.",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Navigate to Package Delivery"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for creating service items
  Widget buildServiceItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 40,
        color: Color(0xFF3C3D37),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      onTap: onPressed,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}

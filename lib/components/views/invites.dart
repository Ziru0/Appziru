import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white, // Back button color
          onPressed: () {
            Navigator.pop(context); // Pops the current screen from the navigation stack
          },
        ),
        title: Text(
          "Invite Friends",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF181C14), // Dark theme background color
      ),
      body: Column(
        children: [
          // Invite Message Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Invite your friends to join us and enjoy amazing rewards!",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
              ),
            ),
          ),

          // Contact List
          Expanded(
            child: _buildContactList(),
          ),

          // Invite Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Implement share or invitation logic here
                _showInviteDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Invite button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 40.0),
              ),
              child: Text(
                "Invite Now",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE8E7E7), // Dark theme background color
    );
  }

  // Widget to build the contact list for inviting
  Widget _buildContactList() {
    final contacts = [
      {"name": "John Doe", "status": "Invite via WhatsApp"},
      {"name": "Jane Smith", "status": "Invite via SMS"},
      {"name": "Mike Johnson", "status": "Invite via Email"},
    ];

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF282C21), // Dark card background color
          child: ListTile(
            leading: Icon(
              Icons.person,
              color: Colors.white,
            ),
            title: Text(
              contact['name']!,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
            ),
            subtitle: Text(
              contact['status']!,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.send,
                color: Colors.green, // Send icon color
              ),
              onPressed: () {
                // Logic to send invite to this contact
                _sendInvite(contact['name']!);
              },
            ),
          ),
        );
      },
    );
  }

  // Function to handle sending the invite
  void _sendInvite(String contactName) {
    // Show a confirmation dialog or perform any logic to send the invite
    print('Invite sent to $contactName!');
  }

  // Show a dialog when the invite button is clicked
  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Invite Sent"),
        content: Text("Your invite has been sent successfully."),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}

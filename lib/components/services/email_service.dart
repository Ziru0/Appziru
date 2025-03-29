import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<bool> sendOtpEmail(String recipientEmail, String otp) async {
  String username = 'ruizharoldandrie@gmail.com'; // Your Gmail
  String password = 'tdsu xrfp aplr ajcp';   // App Password (NOT your Gmail password)

  final smtpServer = gmail(username, password);

  final message = Message()
    ..from = Address(username, 'Omoda App')
    ..recipients.add(recipientEmail)
    ..subject = 'Your OTP Code'
    ..text = 'Your OTP code is: $otp';

  try {
    final sendReport = await send(message, smtpServer);
    print('Email sent: $sendReport');
    return true;
  } catch (e) {
    print('Error sending email: $e');
    return false;
  }
}

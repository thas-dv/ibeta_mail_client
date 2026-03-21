import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../../accounts/models/mail_account.dart';

class SmtpService {
  Future<void> sendMail({
    required MailAccount account,
    required String to,
    required String subject,
    required String body,
  }) async {
    final smtpServer = SmtpServer(
      account.smtpHost,
      port: account.smtpPort,
      username: account.email,
      password: account.password,
      ssl: false,
      allowInsecure: false,
      ignoreBadCertificate: false,
    );

    final message = Message()
      ..from = Address(account.email, account.displayName)
      ..recipients.add(to)
      ..subject = subject
      ..text = body;

    await send(message, smtpServer);
  }
}

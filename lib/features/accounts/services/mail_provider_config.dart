import '../models/mail_account.dart';

class MailProviderConfig {
  const MailProviderConfig({
    required this.imapHost,
    required this.imapPort,
    required this.smtpHost,
    required this.smtpPort,
    this.useSsl = true,
  });

  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;
  final bool useSsl;
}

class MailProviderResolver {
  static MailProviderConfig fromEmail(String email) {
    final domain = email.split('@').last.toLowerCase();
    if (domain.contains('gmail.')) {
      return const MailProviderConfig(
        imapHost: 'imap.gmail.com',
        imapPort: 993,
        smtpHost: 'smtp.gmail.com',
        smtpPort: 587,
      );
    }
    if (domain.contains('outlook.') || domain.contains('hotmail.') || domain.contains('live.')) {
      return const MailProviderConfig(
        imapHost: 'outlook.office365.com',
        imapPort: 993,
        smtpHost: 'smtp.office365.com',
        smtpPort: 587,
      );
    }
    if (domain.contains('yahoo.')) {
      return const MailProviderConfig(
        imapHost: 'imap.mail.yahoo.com',
        imapPort: 993,
        smtpHost: 'smtp.mail.yahoo.com',
        smtpPort: 587,
      );
    }

    return MailProviderConfig(
      imapHost: 'imap.$domain',
      imapPort: 993,
      smtpHost: 'smtp.$domain',
      smtpPort: 587,
    );
  }

  static MailAccount buildAccount({
    required String email,
    required String displayName,
    required String password,
  }) {
    final config = fromEmail(email);
    return MailAccount(
      id: email,
      email: email,
      displayName: displayName.isEmpty ? email.split('@').first : displayName,
      imapHost: config.imapHost,
      imapPort: config.imapPort,
      smtpHost: config.smtpHost,
      smtpPort: config.smtpPort,
      password: password,
      useSsl: config.useSsl,
    );
  }
}

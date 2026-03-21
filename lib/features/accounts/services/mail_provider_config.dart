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
   static MailProviderConfig gmail() {
    return const MailProviderConfig(
      imapHost: 'imap.gmail.com',
      imapPort: 993,
      smtpHost: 'smtp.gmail.com',
      smtpPort: 587,
    );
  }

   static MailAccount buildGmailAccount({
     required String email,
    required String displayName,
   required String accessToken,
    required String? refreshToken,
    String? photoUrl,
    String? serverAuthCode,
  }) {
    final config = gmail();
    return MailAccount(
      id: email.toLowerCase(),
      email: email,
      displayName: displayName.isEmpty ? email.split('@').first : displayName,
      imapHost: config.imapHost,
      imapPort: config.imapPort,
      smtpHost: config.smtpHost,
      smtpPort: config.smtpPort,
    accessToken: accessToken,
      refreshToken: refreshToken,
      photoUrl: photoUrl,
      serverAuthCode: serverAuthCode,
      useSsl: config.useSsl,
    );
  }
}

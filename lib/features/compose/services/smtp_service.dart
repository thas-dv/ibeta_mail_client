import 'package:ibeta_mail_client/features/accounts/models/mail_account.dart';

import '../../mail/services/mail_service.dart';


class SmtpService {
    SmtpService(this._mailService);

  final MailService _mailService;
  Future<void> sendMail({
    required MailAccount account,
    required String to,
    required String subject,
    required String body,
}) {
    return _mailService.sendMessage(
      account: account,
      to: to,
      subject: subject,
      body: body,
    );


  }
}

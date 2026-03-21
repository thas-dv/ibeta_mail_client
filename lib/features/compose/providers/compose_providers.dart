import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibeta_mail_client/features/accounts/provider/account_providers.dart';
import 'package:ibeta_mail_client/features/compose/services/smtp_service.dart';
import 'package:ibeta_mail_client/features/mail/providers/mail_providers.dart';



final smtpServiceProvider = Provider(
  (ref) => SmtpService(ref.watch(mailServiceProvider)),
);
final composeControllerProvider = AsyncNotifierProvider<ComposeController, void>(
  ComposeController.new,
);

class ComposeController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> send({
    required String to,
    required String subject,
    required String body,
  }) async {
    final account = ref.read(selectedAccountProvider);
    if (account == null) {
      throw StateError('Aucun compte actif.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
 await ref.read(smtpServiceProvider).sendMail(
            account: account,
            to: to,
            subject: subject,
            body: body,
          );
    });
  }
}

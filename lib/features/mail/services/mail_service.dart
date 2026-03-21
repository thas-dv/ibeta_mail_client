import "dart:async";
import "package:enough_mail/enough_mail.dart" as em;

import "../../accounts/models/mail_account.dart";
import "../models/mail_message.dart";

class MailService {
  em.MailClient? _client;
  MailAccount? _connectedAccount;

  Future<em.MailClient> _connect(MailAccount account) async {
    if (_client != null && _connectedAccount?.id == account.id) {
      return _client!;
    }

    final discovered = await em.Discover.discover(account.email);

    final mailAccount = discovered != null && discovered.isValid
        ? em.MailAccount.fromDiscoveredSettings(
            name: account.displayName,
            email: account.email,
            password: account.password,
            config: discovered,
            userName: account.email,
          )
        : em.MailAccount(
            name: account.displayName,
            email: account.email,
            userName: account.email,

            // ✅ INCOMING (IMAP)
            incoming: em.MailServerConfig(
              serverConfig: em.ServerConfig(
                type: em.ServerType.imap,
                hostname: account.imapHost,
                port: account.imapPort,
                socketType: account.useSsl
                    ? em.SocketType.ssl
                    : em.SocketType.starttls,
                authentication: em.Authentication.plain,
                usernameType: em.UsernameType.emailAddress,
              ),
              authentication: em.PlainAuthentication(
                account.email,
                account.password,
              ),
            ),

            // ✅ OUTGOING (SMTP)
            outgoing: em.MailServerConfig(
              serverConfig: em.ServerConfig(
                type: em.ServerType.smtp,
                hostname: account.smtpHost,
                port: account.smtpPort,
                socketType: em.SocketType.starttls,
                authentication: em.Authentication.plain,
                usernameType: em.UsernameType.emailAddress,
              ),
              authentication: em.PlainAuthentication(
                account.email,
                account.password,
              ),
            ),
          );

    final client = em.MailClient(mailAccount);
    await client.connect();

    _client = client;
    _connectedAccount = account;

    return client;
  }

  Future<List<MailMessage>> fetchInbox(
    MailAccount account, {
    required int page,
    int pageSize = 20,
  }) async {
    final client = await _connect(account);
    await client.selectInbox();

    final messages = await client.fetchMessages(
      count: pageSize,
      page: page + 1,
    );

    return messages.map((message) {
      final from = message.from?.isNotEmpty == true
          ? (message.from!.first.email.isNotEmpty == true
                ? message.from!.first.email
                : message.from!.first.toString())
          : "Expéditeur inconnu";

      return MailMessage(
        uid: message.uid ?? message.sequenceId ?? 0,
        subject: (message.decodeSubject() ?? "").trim().isEmpty
            ? "(Sans sujet)"
            : message.decodeSubject()!.trim(),
        from: from,
        preview:
            (message.decodeTextPlainPart() ??
                    message.decodeTextHtmlPart() ??
                    "")
                .replaceAll(RegExp(r"<[^>]*>"), " ")
                .replaceAll(RegExp(r"\s+"), " ")
                .trim(),
        date: message.decodeDate() ?? DateTime.now(),
        isRead: message.isSeen,
      );
    }).toList();
  }

  Future<void> markAsRead(
    MailAccount account,
    int uid, {
    required bool read,
  }) async {
    final client = await _connect(account);
    await client.selectInbox();

    final sequence = em.MessageSequence.fromId(uid, isUid: true);

    await client.store(sequence, const [
      em.MessageFlags.seen,
    ], action: read ? em.StoreAction.add : em.StoreAction.remove);
  }

  Future<void> deleteMessage(MailAccount account, int uid) async {
    final client = await _connect(account);
    await client.selectInbox();

    final sequence = em.MessageSequence.fromId(uid, isUid: true);

    await client.deleteMessages(sequence, expunge: true);
  }

  Stream<void> watchInbox(MailAccount account) async* {
    final client = await _connect(account);

    await client.startPolling(const Duration(minutes: 2));

    while (true) {
      await Future<void>.delayed(const Duration(minutes: 2));
      yield null;
    }
  }
}

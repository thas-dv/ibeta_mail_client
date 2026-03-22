import 'dart:async';

import 'package:enough_mail/enough_mail.dart' as em;

import '../../../accounts/models/mail_account.dart';
import '../../models/mail_message.dart';

class MailService {
  MailService({
    required Future<MailAccount> Function(MailAccount account) refreshToken,
  }) : _refreshToken = refreshToken;

  final Future<MailAccount> Function(MailAccount account) _refreshToken;

  em.MailClient? _client;
  MailAccount? _connectedAccount;

  Future<em.MailClient> _connect(MailAccount account) async {
    if (_client != null && _connectedAccount?.id == account.id) {
      return _client!;
    }

    final mailAccount = _buildMailAccount(account);

    final client = em.MailClient(
      mailAccount,
      refresh: (_, expiredToken) async {
        final refreshedAccount = await _refreshToken(account);
        _connectedAccount = refreshedAccount;
        return _buildOauthToken(
          refreshedAccount,
          expiresIn: expiredToken.expiresIn,
        );
      },
      onConfigChanged: (updatedAccount) async {
        final incomingAuth = updatedAccount.incoming.authentication;
        if (incomingAuth is em.OauthAuthentication) {
          _connectedAccount = account.copyWith(
            accessToken: incomingAuth.token.accessToken,
          );
        }
      },
    );

    await client.connect();
    _client = client;
    _connectedAccount = account;
    return client;
  }

  em.MailAccount _buildMailAccount(MailAccount account) {
    final oauth = em.OauthAuthentication(
      account.email,
      _buildOauthToken(account),
    );

    return em.MailAccount(
      name: account.displayName,
      email: account.email,
      userName: account.email,
      incoming: em.MailServerConfig(
        serverConfig: em.ServerConfig(
          type: em.ServerType.imap,
          hostname: account.imapHost,
          port: account.imapPort,
          socketType: account.useSsl ? em.SocketType.ssl : em.SocketType.starttls,
          authentication: em.Authentication.plain,
          usernameType: em.UsernameType.emailAddress,
        ),
        authentication: oauth,
      ),
      outgoing: em.MailServerConfig(
        serverConfig: em.ServerConfig(
          type: em.ServerType.smtp,
          hostname: account.smtpHost,
          port: account.smtpPort,
          socketType: em.SocketType.starttls,
          authentication: em.Authentication.plain,
          usernameType: em.UsernameType.emailAddress,
        ),
        authentication: oauth,
      ),
    );
  }

  em.OauthToken _buildOauthToken(
    MailAccount account, {
    int expiresIn = 3600,
  }) {
    return em.OauthToken(
      accessToken: account.accessToken,
      refreshToken: account.refreshToken ?? '',
      expiresIn: expiresIn,
      scope: 'https://mail.google.com/',
      tokenType: 'Bearer',
      created: DateTime.now().toUtc(),
      provider: 'google',
    );
  }

  Future<List<MailMessage>> fetchInbox(
    MailAccount account, {
    required int page,
    int pageSize = 20,
  }) async {
    final client = await _connect(account);
    await client.selectInbox();

    final messages = await client.fetchMessages(count: pageSize, page: page + 1);

    return messages.map((message) {
      final from = message.from?.isNotEmpty == true
          ? (message.from!.first.email.isNotEmpty
                ? message.from!.first.email
                : message.from!.first.toString())
          : 'Expéditeur inconnu';

      final decodedSubject = (message.decodeSubject() ?? '').trim();
      return MailMessage(
        uid: (message.uid ?? message.sequenceId ?? 0).toString(),
        subject: decodedSubject.isEmpty ? '(Sans sujet)' : decodedSubject,
        from: from,
        preview: (message.decodeTextPlainPart() ?? message.decodeTextHtmlPart() ?? '')
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
        date: message.decodeDate() ?? DateTime.now(),
        isRead: message.isSeen,
      );
    }).toList();
  }

  Future<void> markAsRead(
    MailAccount account,
    String uid, {
    required bool read,
  }) async {
    final client = await _connect(account);
    await client.selectInbox();

    final parsedUid = int.tryParse(uid);
    if (parsedUid == null) {
      throw StateError('UID IMAP invalide : $uid');
    }

    final sequence = em.MessageSequence.fromId(parsedUid, isUid: true);
    await client.store(
      sequence,
      <String>[em.MessageFlags.seen],
      action: read ? em.StoreAction.add : em.StoreAction.remove,
    );
  }

  Future<void> deleteMessage(MailAccount account, String uid) async {
    final client = await _connect(account);
    await client.selectInbox();

    final parsedUid = int.tryParse(uid);
    if (parsedUid == null) {
      throw StateError('UID IMAP invalide : $uid');
    }

    final sequence = em.MessageSequence.fromId(parsedUid, isUid: true);
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

  Future<void> sendMessage({
    required MailAccount account,
    required String to,
    required String subject,
    required String body,
  }) async {
    final client = await _connect(account);

    final builder = em.MessageBuilder()
      ..from = <em.MailAddress>[em.MailAddress(account.displayName, account.email)]
      ..to = <em.MailAddress>[em.MailAddress('', to)]
      ..subject = subject
      ..text = body;

    await client.sendMessage(builder.buildMimeMessage());
  }
}

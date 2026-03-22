import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../accounts/models/mail_account.dart';
import '../../models/mail_message.dart';

class MailServiceException implements Exception {
  const MailServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MailService {
  MailService({
    required Future<MailAccount> Function(MailAccount account) refreshToken,
    http.Client? httpClient,
  }) : _refreshToken = refreshToken,
       _httpClient = httpClient ?? http.Client();

  final Future<MailAccount> Function(MailAccount account) _refreshToken;
  final http.Client _httpClient;
  final Map<String, List<String?>> _pageTokens = <String, List<String?>>{};

  Future<List<MailMessage>> fetchInbox(
    MailAccount account, {
    required int page,
    int pageSize = 20,
  }) async {
    final tokens = _pageTokens.putIfAbsent(account.id, () => <String?>[null]);
    if (page == 0) {
      tokens
        ..clear()
        ..add(null);
    }

    if (page >= tokens.length) {
      throw const MailServiceException(
        'Pagination Gmail invalide. Rechargez la boîte de réception avant de continuer.',
      );
    }

    final query = <String, String>{
      'maxResults': '$pageSize',
      'labelIds': 'INBOX',
    };
    final pageToken = tokens[page];
    if (pageToken != null && pageToken.isNotEmpty) {
      query['pageToken'] = pageToken;
    }

    final response = await _authorizedRequest(
      account,
      (authorizedAccount) => _httpClient.get(
        Uri.https(
          'gmail.googleapis.com',
          '/gmail/v1/users/me/messages',
          query,
        ),
        headers: _headers(authorizedAccount.accessToken),
      ),
    );

    final data = _decodeJsonMap(response.body);
    final messages = (data['messages'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final nextPageToken = data['nextPageToken'] as String?;

    if (tokens.length == page + 1) {
      tokens.add(nextPageToken);
    } else {
      tokens[page + 1] = nextPageToken;
    }

    final detailedMessages = await Future.wait(
       messages.map((entry) => _fetchMessage(account, entry['id'] as String, format: 'full')),
    );
    return detailedMessages;
  }
 Future<MailMessage> fetchMessageDetail(
    MailAccount account,
    String uid, {
    MailMessage? fallback,
  }) async {
    return _fetchMessage(account, uid, format: 'full', fallback: fallback);
  }
  Future<void> markAsRead(
    MailAccount account,
    String uid, {
    required bool read,
  }) async {
    await _authorizedRequest(
      account,
      (authorizedAccount) => _httpClient.post(
        Uri.https(
          'gmail.googleapis.com',
          '/gmail/v1/users/me/messages/$uid/modify',
        ),
        headers: _headers(authorizedAccount.accessToken),
        body: jsonEncode(<String, dynamic>{
          if (read) 'removeLabelIds': <String>['UNREAD'] else 'addLabelIds': <String>['UNREAD'],
        }),
      ),
    );
  }

  Future<void> deleteMessage(MailAccount account, String uid) async {
    await _authorizedRequest(
      account,
      (authorizedAccount) => _httpClient.delete(
        Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/$uid'),
        headers: _headers(authorizedAccount.accessToken),
      ),
    );
  }

  Stream<void> watchInbox(MailAccount account) async* {
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
    final mime = _buildMimeMessage(account: account, to: to, subject: subject, body: body);
    final encodedMessage = base64Url.encode(utf8.encode(mime)).replaceAll('=', '');

    await _authorizedRequest(
      account,
      (authorizedAccount) => _httpClient.post(
        Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/send'),
        headers: _headers(authorizedAccount.accessToken),
        body: jsonEncode(<String, dynamic>{'raw': encodedMessage}),
      ),
    );
  }

  Future<MailMessage> _fetchMessage(
    MailAccount account,
    String messageId, {
    String format = 'full',
    MailMessage? fallback,
  }) async {
    final response = await _authorizedRequest(
      account,
      (authorizedAccount) => _httpClient.get(
        Uri.https(
          'gmail.googleapis.com',
          '/gmail/v1/users/me/messages/$messageId',
         <String, String>{'format': format},
        ),
        headers: _headers(authorizedAccount.accessToken),
      ),
    );

    final data = _decodeJsonMap(response.body);
    final payload = data['payload'] as Map<String, dynamic>? ?? const {};
    final headers = (payload['headers'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final labelIds = (data['labelIds'] as List<dynamic>? ?? const []).cast<String>();

    String headerValue(String name) {
      for (final header in headers) {
        if ((header['name'] as String?)?.toLowerCase() == name.toLowerCase()) {
          return header['value'] as String? ?? '';
        }
      }
      return '';
    }
 final body = _extractBody(payload).trim();
    final preview = (data['snippet'] as String? ?? '').trim();
    return MailMessage(
      uid: data['id'] as String? ?? messageId,
       subject: headerValue('Subject').trim().isEmpty
          ? (fallback?.subject ?? '(Sans sujet)')
          : headerValue('Subject').trim(),
      from: headerValue('From').trim().isEmpty
          ? (fallback?.from ?? 'Expéditeur inconnu')
          : headerValue('From').trim(),
      to: headerValue('To').trim(),
      preview: preview.isEmpty ? (fallback?.preview ?? '') : preview,
      body: body.isEmpty ? (fallback?.body ?? preview) : body,
      date: (() {
        final millis = int.tryParse(data['internalDate'] as String? ?? '');
        return millis == null
           ? (fallback?.date ?? DateTime.now())
            : DateTime.fromMillisecondsSinceEpoch(millis);
      })(),
      isRead: !labelIds.contains('UNREAD'),
    );
  }
  String _extractBody(Map<String, dynamic> payload) {
    final body = payload['body'] as Map<String, dynamic>?;
    final data = body?['data'] as String?;
    if (data != null && data.isNotEmpty) {
      return utf8.decode(base64Url.decode(base64Url.normalize(data)))
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final parts = (payload['parts'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    for (final part in parts) {
      final mimeType = part['mimeType'] as String? ?? '';
      if (mimeType == 'text/plain' || mimeType == 'text/html') {
        final nestedBody = _extractBody(part);
        if (nestedBody.isNotEmpty) {
          return nestedBody;
        }
      }
      final nestedParts = (part['parts'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
      for (final nested in nestedParts) {
        final nestedBody = _extractBody(nested);
        if (nestedBody.isNotEmpty) {
          return nestedBody;
        }
      }
    }
    return '';
  }
  Future<http.Response> _authorizedRequest(
    MailAccount account,
    Future<http.Response> Function(MailAccount authorizedAccount) request,
  ) async {
    var activeAccount = account;
    var response = await request(activeAccount);

    if (response.statusCode == 401 || response.statusCode == 403) {
      activeAccount = await _refreshToken(account);
      response = await request(activeAccount);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MailServiceException(_extractErrorMessage(response));
    }

    return response;
  }

  Map<String, String> _headers(String accessToken) => <String, String>{
    'Authorization': 'Bearer $accessToken',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeJsonMap(String source) =>
      jsonDecode(source) as Map<String, dynamic>;

  String _extractErrorMessage(http.Response response) {
    try {
      final data = _decodeJsonMap(response.body);
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        return error['message'] as String? ?? 'Erreur Gmail API (${response.statusCode}).';
      }
    } catch (_) {
      // Ignore JSON parsing failures and return the raw fallback below.
    }
    return 'Erreur Gmail API (${response.statusCode}).';
  }

  String _buildMimeMessage({
    required MailAccount account,
    required String to,
    required String subject,
    required String body,
  }) {
    final safeSubject = subject.replaceAll('\n', ' ').replaceAll('\r', ' ');
    return [
      'From: ${account.displayName} <${account.email}>',
      'To: $to',
      'Subject: $safeSubject',
      'MIME-Version: 1.0',
      'Content-Type: text/plain; charset=utf-8',
      'Content-Transfer-Encoding: 8bit',
      '',
      body,
    ].join('\r\n');
  }
}

import 'package:google_sign_in/google_sign_in.dart';

import '../models/mail_account.dart';
import 'mail_provider_config.dart';

class GoogleOAuthException implements Exception {
  const GoogleOAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleOAuthService {
  GoogleOAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const List<String> scopes = <String>[
    'email',
    'profile',
    'openid',
    'https://mail.google.com/',
  ];

  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    await _googleSignIn.initialize(
      clientId: const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID'),
      serverClientId: const String.fromEnvironment(
        'GOOGLE_OAUTH_SERVER_CLIENT_ID',
      ),
    );
    _isInitialized = true;
  }

  Future<MailAccount> authenticate() async {
    await initialize();

    final user = await _googleSignIn.authenticate();
    final authorization = await user.authorizationClient.authorizeScopes(
      scopes,
    );
    final headers = await user.authorizationClient.authorizationHeaders(scopes);
    final accessToken = _extractAccessToken(headers);
    final serverAuthorization = await user.authorizationClient.authorizeServer(
      scopes,
    );

    return MailProviderResolver.buildGmailAccount(
      email: user.email,
      displayName: user.displayName ?? user.email.split('@').first,
      photoUrl: user.photoUrl,
      accessToken: accessToken,
      refreshToken: null,
      serverAuthCode: serverAuthorization?.serverAuthCode,
    );
  }

Future<MailAccount> refreshAccount(MailAccount account) async {
  await initialize();

  final googleSignIn = _googleSignIn;

  final currentUser = await googleSignIn.authenticate();

  if (currentUser == null ||
      currentUser.email.toLowerCase() != account.email.toLowerCase()) {
    throw const GoogleOAuthException(
      'La session Google n’est plus disponible. Reconnectez le compte pour renouveler le token.',
    );
  }

  GoogleSignInClientAuthorization? authorization =
      await currentUser.authorizationClient.authorizationForScopes(scopes);

  authorization ??= await currentUser.authorizationClient.authorizeScopes(
    scopes,
  );

  final headers =
      await currentUser.authorizationClient.authorizationHeaders(scopes);

  final accessToken = _extractAccessToken(headers);

  return account.copyWith(accessToken: accessToken);
}

  Future<void> signOut() => _googleSignIn.disconnect();

  String _extractAccessToken(Map<String, String>? headers) {
    final bearer = headers?['Authorization'];
    if (bearer == null || !bearer.startsWith('Bearer ')) {
      throw const GoogleOAuthException('Token OAuth2 Google introuvable.');
    }
    return bearer.substring('Bearer '.length);
  }
}

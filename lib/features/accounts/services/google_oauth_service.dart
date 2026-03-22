import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
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
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _googleSignIn.authenticationEvents;

  GoogleSignInAccount? get currentUser => _currentUser;

  bool get requiresWebButton => kIsWeb && !_googleSignIn.supportsAuthenticate();

  Future<void> initialize() async {
    if (_isInitialized) return;

    const serverClientId =
        '481455632993-7k0dloq7vehnhr0am5hj4dkas1qvs9tl.apps.googleusercontent.com';

    _authSubscription = _googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
      }
    });

    if (kIsWeb) {
      await _googleSignIn.initialize();
    } else {
      // ✅ ANDROID → SEULEMENT serverClientId
      await _googleSignIn.initialize(serverClientId: serverClientId);
    }

    _isInitialized = true;

    await _googleSignIn.attemptLightweightAuthentication();
  }

  Future<MailAccount> authenticate() async {
    await initialize();

    if (requiresWebButton) {
      throw const GoogleOAuthException(
        'Sur le Web, utilisez le bouton Google officiel affiché dans la fenêtre d’ajout de compte.',
      );
    }

    final user = await _googleSignIn.authenticate();

    _currentUser = user;
    return _buildAccountForUser(user);
  }

  Future<MailAccount> completeWebAuthentication() async {
    await initialize();

    final user = _currentUser;
    if (user == null) {
      throw const GoogleOAuthException(
        'Aucune session Google active n’a été détectée sur le Web.',
      );
    }

    return _buildAccountForUser(user);
  }

  Future<MailAccount> refreshAccount(MailAccount account) async {
    await initialize();
    final user = _currentUser;
    if (user == null ||
        user.email.toLowerCase() != account.email.toLowerCase()) {
      throw const GoogleOAuthException(
        'La session Google n’est plus disponible. Reconnectez le compte pour renouveler le token.',
      );
    }

    final existingAuthorization = await user.authorizationClient
        .authorizationForScopes(scopes);
    if (existingAuthorization == null) {
      await user.authorizationClient.authorizeScopes(scopes);
    }

    final headers = await user.authorizationClient.authorizationHeaders(scopes);
    final accessToken = _extractAccessToken(headers);

    return account.copyWith(accessToken: accessToken);
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
  }

  Future<MailAccount> _buildAccountForUser(GoogleSignInAccount user) async {
    final auth =
        await user.authorizationClient.authorizationForScopes(scopes) ??
        await user.authorizationClient.authorizeScopes(scopes);

    final headers = await user.authorizationClient.authorizationHeaders(scopes);

    final accessToken = _extractAccessToken(headers);

    print("USER: ${user.email}");
    print("TOKEN: $accessToken");

    return MailProviderResolver.buildGmailAccount(
      email: user.email,
      displayName: user.displayName ?? user.email.split('@').first,
      photoUrl: user.photoUrl,
      accessToken: accessToken,
      refreshToken: null,
      serverAuthCode: null,
    );
  }

  String _extractAccessToken(Map<String, String>? headers) {
    final bearer = headers?['Authorization'] ?? headers?['authorization'];
    if (bearer == null || !bearer.startsWith('Bearer ')) {
      throw const GoogleOAuthException('Token OAuth2 Google introuvable.');
    }
    return bearer.substring('Bearer '.length);
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}

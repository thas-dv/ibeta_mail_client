# iBeta Mail Client

Client mail Flutter modernisé autour de Gmail OAuth2, IMAP/SMTP et `enough_mail`.

## Ce qui a changé

- ajout de comptes Gmail via Google Sign-In OAuth2
- stockage local sécurisé des comptes et tokens avec `flutter_secure_storage`
- authentification IMAP/SMTP via XOAUTH2 avec `enough_mail`
- suppression locale d’un compte sans impact sur le compte Gmail réel
- architecture conservée par features (`accounts`, `mail`, `compose`) avec Riverpod

## Configuration OAuth Google

L’application attend des identifiants OAuth Google injectés au runtime :

```bash
flutter run \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=your_client_id.apps.googleusercontent.com \
  --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=your_server_client_id.apps.googleusercontent.com
```

## Scopes Google

- `email`
- `profile`
- `openid`
- `https://mail.google.com/`

## Notes importantes

- aucun mot de passe utilisateur n’est demandé dans l’application
- les comptes retirés depuis l’UI sont supprimés **localement uniquement**
- avec `google_sign_in`, le `refreshToken` n’est généralement pas exposé côté client mobile ; le modèle le conserve nullable pour compatibilité future, tandis que le renouvellement du token s’appuie sur la session Google Sign-In en cours
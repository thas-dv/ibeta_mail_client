diff --git a/README.md b/README.md
index a53dbad609ff8a8af168e521681056277c0d97a8..f5b63aa81c81c7fd064cd88ac820072ba645a433 100644
--- a/README.md
+++ b/README.md
@@ -1,16 +1,30 @@
-# ibeta_mail_client
+# iBeta Mail Client
 
-A new Flutter project.
+Client mail Flutter orienté mobile avec Riverpod, enough_mail (IMAP), mailer (SMTP), stockage sécurisé des mots de passe et cache local léger.
 
-## Getting Started
+## Fonctionnalités
 
-This project is a starting point for a Flutter application.
+- Multi-comptes avec sélection rapide via drawer.
+- Configuration automatique Gmail / Outlook / Yahoo + fallback IMAP/SMTP basé sur le domaine.
+- Inbox paginée avec pull-to-refresh, cache local, marquage lu/non lu, suppression.
+- Compose moderne avec gestion d'état, loading et erreurs.
+- Thème clair / sombre inspiré des apps mail modernes.
 
-A few resources to get you started if this is your first Flutter project:
+## Structure
 
-- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
-- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
+- `lib/features/accounts`: comptes, stockage, configuration fournisseurs.
+- `lib/features/mail`: inbox, cache, services IMAP.
+- `lib/features/compose`: envoi SMTP.
+- `lib/core`: thème et utilitaires transverses.
 
-For help getting started with Flutter development, view the
-[online documentation](https://docs.flutter.dev/), which offers tutorials,
-samples, guidance on mobile development, and a full API reference.
+## Notes d'intégration
+
+- Pour Gmail, Outlook et Yahoo, utilisez un mot de passe applicatif si le fournisseur l'exige.
+- L'app n'active pas de synchronisation système ni d'accès aux contacts.
+- Le support temps réel repose sur l'IDLE IMAP quand le serveur le permet.
+
+## Démarrage
+
+1. Installer Flutter sur la machine.
+2. Lancer `flutter pub get`.
+3. Lancer `flutter run`.

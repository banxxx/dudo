/// Public links used by the about page. They point at the project's git remote
/// (`github.com/banxxx/dudo`) so the repository and issue tracker stay in sync
/// with where the app actually lives.
class AboutLinks {
  AboutLinks._();

  /// Project home. Used by the repository button and the changelog sheet.
  static final Uri repository = Uri.parse('https://github.com/banxxx/dudo');

  /// Where the feedback entry sends users. GitHub Issues is the only channel
  /// the project exposes today; swap this if an email or form is added.
  static final Uri feedback =
      Uri.parse('https://github.com/banxxx/dudo/issues/new');

  /// Feedback mailbox shown on the feedback page. Readers copy it and send
  /// mail from their own client; the app never opens a mail client for them.
  static const String email = 'posoovo@gmail.com';

  /// Human-readable form, for messages that cannot open a browser.
  static String display(Uri uri) => uri.toString();
}

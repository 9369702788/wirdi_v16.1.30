import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Thrown by [AuthService]'s Google sign-in flow. [message] is always safe
/// to show a user. [debugDetails] additionally contains non-sensitive
/// configuration diagnostics (package name, Firebase project id, error
/// code) -- appended to [toString] only in debug builds, so it shows up
/// directly wherever the UI displays this exception's text (no adb/logcat
/// needed), while release builds only ever show the clean [message].
class AuthServiceException implements Exception {
  AuthServiceException(this.message, {this.cause, this.debugDetails});
  final String message;
  final Object? cause;
  final String? debugDetails;
  @override
  String toString() {
    if (kDebugMode && debugDetails != null) {
      return "$message\n\n[Diagnostics -- debug builds only]\n$debugDetails";
    }
    return message;
  }
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// IMPORTANT: this must be the Firebase project's WEB OAuth client ID
  /// (Google Cloud Console > APIs & Services > Credentials > "Web client
  /// (auto created by Google Service)"), NOT the Android client ID.
  /// Without a serverClientId, Android Google Sign-In on some devices/OS
  /// versions fails with ApiException: 10 even when the Android OAuth
  /// client itself is registered correctly, because the plugin cannot
  /// resolve an ID token audience. If this project's Firebase config ever
  /// changes (new Firebase project, project deleted/recreated), this value
  /// MUST be updated from Google Cloud Console -- it must never be a
  /// placeholder or guessed value.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '391561027779-fq8t9eo47aubj7to6c84es8vbbdald8n.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// FIX: registration previously only checked that the email matched a
  /// generic FORMAT (name@domain.tld) and the password met Firebase's own
  /// minimum length -- it never verified the email actually belongs to
  /// the person registering. That is exactly what produced the "any
  /// email and any password gets accepted" report: format-valid but
  /// completely fake/unowned addresses (and very weak but
  /// length-legal passwords) were indistinguishable from real ones at
  /// registration time. This does not block registration (a hard block
  /// risks locking someone out if a verification email is delayed or
  /// lost), but it does send Firebase's real verification link so the
  /// UI can tell the user to confirm ownership of the address, and so
  /// [User.emailVerified] is available for any future gating decision.
  Future<UserCredential> registerWithEmail(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(displayName);
    try {
      await cred.user?.sendEmailVerification();
    } catch (e) {
      // Non-fatal: registration itself already succeeded. A verification
      // email failing to send (rate limiting, transient network error)
      // should never be treated as a registration failure.
      debugPrint('[AuthService] sendEmailVerification failed (non-fatal): $e');
    }
    return cred;
  }

  /// Re-sends the verification email to the currently signed-in user.
  /// Exposed so the UI can offer a "resend verification email" action
  /// (e.g. if the first one was missed, went to spam, or expired).
  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  /// Whether the currently signed-in user's email address has been
  /// confirmed via the verification link. Always reflects Firebase's
  /// last-known state for this session -- call [User.reload] first
  /// (e.g. via [resendEmailVerification] or a manual refresh) to check
  /// for a just-completed verification.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? true;

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled the picker
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      final details = await _buildGoogleSignInDiagnostics(e);
      throw AuthServiceException(_friendlyGoogleSignInMessage(e), cause: e, debugDetails: details);
    } catch (e) {
      debugPrint('[AuthService] Google: ' + e.toString());
      rethrow;
    }
  }

  /// Extracts the numeric Android GoogleSignIn status code (e.g. 10 =
  /// DEVELOPER_ERROR, 7 = NETWORK_ERROR, 12501 = SIGN_IN_CANCELLED) from
  /// the raw platform exception message, if present.
  int? _extractApiExceptionCode(PlatformException e) {
    final match = RegExp(r'ApiException:\s*(\d+)').firstMatch(e.message ?? '');
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Maps known Google Sign-In failure codes to a message that is safe and
  /// useful to show a user -- never the raw "PlatformException(...)" text.
  String _friendlyGoogleSignInMessage(PlatformException e) {
    switch (_extractApiExceptionCode(e)) {
      case 10:
        return 'Google Sign-In configuration error. Please check Google/Firebase configuration.';
      case 7:
        return 'No internet connection. Please check your network and try again.';
      case 12501:
        return 'Sign-in was cancelled.';
      default:
        return 'Google Sign-In failed. Please try again, or use email sign-in instead.';
    }
  }

  /// Builds a non-sensitive diagnostics string (package name, Firebase
  /// project id, error code) to help debug Google Sign-In failures without
  /// needing adb/logcat access. Never includes access tokens, ID tokens,
  /// or any other credential material. Only meant to be shown in debug
  /// builds (see [AuthServiceException.toString]).
  Future<String> _buildGoogleSignInDiagnostics(PlatformException e) async {
    try {
      final apiCode = _extractApiExceptionCode(e);
      final packageInfo = await PackageInfo.fromPlatform();
      final projectId = Firebase.apps.isNotEmpty ? Firebase.app().options.projectId : 'no Firebase app initialized';
      return "package: ${packageInfo.packageName}\n"
          "firebase project: $projectId\n"
          "platform error code: ${e.code}\n"
          'ApiException status: ${apiCode?.toString() ?? "n/a (not an ApiException)"}';
    } catch (diagError) {
      return "(diagnostics unavailable: $diagError)";
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final provider = AppleAuthProvider()..addScope('email')..addScope('fullName');
      return await _auth.signInWithProvider(provider);
    } catch (e) { debugPrint('[AuthService] Apple: ' + e.toString()); rethrow; }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }

  /// Deletes the signed-in user's Firebase Auth account. Callers should
  /// delete the user's Firestore data first (see SyncService.deleteAllCloudData)
  /// since this only removes the auth record itself. Firebase may require
  /// a recent sign-in for this sensitive operation -- if it throws, the
  /// caller's error handling surfaces that to the user.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.delete();
    try { await _googleSignIn.signOut(); } catch (_) {}
    notifyListeners();
  }

  List<String> get currentUserProviderIds =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ?? const [];

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw AuthServiceException('No signed-in email account to re-authenticate.');
    }
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> reauthenticateWithApple() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final provider = AppleAuthProvider()..addScope('email')..addScope('fullName');
    await user.reauthenticateWithProvider(provider);
  }
}

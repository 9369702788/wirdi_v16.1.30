import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

final RegExp _kEmailRegex = RegExp(r'^[\w\.\-\+]+@[\w\-]+(\.[\w\-]+)*\.[a-zA-Z]{2,}$');

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}
/// True only if [v] is at least 8 characters AND contains at least one
/// letter AND at least one digit. Deliberately does not require a
/// symbol/uppercase -- the goal is closing the "any 6 identical
/// characters passes" gap, not maximal strictness that would frustrate
/// real users right before launch.
bool _validatePassword(String? v) {
  if (v == null || v.length < 8) return false;
  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
  final hasDigit = RegExp(r'[0-9]').hasMatch(v);
  return hasLetter && hasDigit;
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fk = GlobalKey<FormState>();
  final _nc = TextEditingController(), _ec = TextEditingController(), _pc = TextEditingController();
  bool _loading = false, _obscure = true;
  String? _error;
  @override void dispose() { _nc.dispose(); _ec.dispose(); _pc.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_fk.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.registerWithEmail(_ec.text.trim(), _pc.text, _nc.text.trim());

      // Hard verification: never proceed to /home unless Firebase
      // itself now reports a real signed-in user. Closes any path
      // where a swallowed/miscategorized error could otherwise let
      // navigation continue as if registration had succeeded.
      final user = AuthService.instance.currentUser;
      if (user == null) {
        throw Exception('Registration did not throw, but no signed-in user exists afterwards (unexpected state).');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green.shade800,
          duration: const Duration(seconds: 6),
          content: Text('Account created. Firebase UID: ${user.uid}\nEmail: ${user.email}\nA verification link was sent to your email -- please confirm it.'),
        ));
      }

      try {
        await SyncService.instance.uploadAll();
      } catch (syncError) {
        // A sync failure after a genuinely successful registration
        // should not block getting into the app -- just surface it.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.orange.shade800,
            content: Text('Signed up, but initial sync failed: $syncError'),
          ));
        }
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'Account already exists with this email.',
        'weak-password' => 'This password is too weak. Please use at least 6 characters.',
        'invalid-email' => 'This email address is not valid.',
        _ => 'Registration failed (${e.code}). Please try again.',
      };
      setState(() { _error = msg; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade900,
          duration: const Duration(seconds: 6),
          content: Text('REJECTED (FirebaseAuthException ${e.code}): $msg'),
        ));
      }
    } catch (e) {
      // Anything that is NOT a FirebaseAuthException (network error,
      // Firebase misconfiguration, etc.) used to be swallowed silently
      // by the app's global error zone. Now it is always shown.
      setState(() { _error = 'Registration failed: \$e'; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red.shade900,
          duration: const Duration(seconds: 8),
          content: Text('UNEXPECTED ERROR (not a FirebaseAuthException): $e'),
        ));
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primaryEmerald, foregroundColor: Colors.white, title: Text(l.authCreateAccount), elevation: 0),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryEmerald, Color(0xFF064E3B)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(28, 28, 28, 28 + MediaQuery.of(context).padding.bottom),
          child: Form(key: _fk, autovalidateMode: AutovalidateMode.onUserInteraction, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error != null) Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade900.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: Colors.white))),
            _Fld(ctrl: _nc, label: l.authDisplayName, icon: Icons.person_outline, validator: (v) => (v==null||v.trim().isEmpty) ? l.authNameRequired : null),
            const SizedBox(height: 14),
            _Fld(ctrl: _ec, label: l.authEmail, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => (v==null||!_kEmailRegex.hasMatch(v.trim())) ? l.authInvalidEmail : null),
            const SizedBox(height: 14),
            _Fld(ctrl: _pc, label: l.authPassword, icon: Icons.lock_outline, obscure: _obscure,
              suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white70), onPressed: () => setState(() => _obscure = !_obscure)),
              // FIX: was "length >= 6" only, which accepted things like
              // "111111" or "aaaaaa" -- functionally "any password" as
              // far as real-world security goes. Now requires 8+
              // characters AND at least one letter AND at least one
              // digit. Reuses the existing l.authPasswordTooShort string
              // for every failure case (deliberately, to avoid adding a
              // new localization key that would need translating into
              // all 7 supported languages right before a release build;
              // the validation itself is what changed, not just its
              // wording).
              validator: (v) => _validatePassword(v) ? null : l.authPasswordTooShort),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.goldAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _loading ? null : _register,
              child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l.authCreateAccount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ]))))));
  }
}
class _Fld extends StatelessWidget {
  final TextEditingController ctrl; final String label; final IconData icon;
  final TextInputType? keyboardType; final bool obscure; final Widget? suffixIcon; final String? Function(String?)? validator;
  const _Fld({required this.ctrl, required this.label, required this.icon, this.keyboardType, this.obscure=false, this.suffixIcon, this.validator});
  @override Widget build(BuildContext context) => TextFormField(controller: ctrl, keyboardType: keyboardType, obscureText: obscure, style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70), prefixIcon: Icon(icon, color: Colors.white70), suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.goldAccent)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      errorStyle: const TextStyle(color: Colors.redAccent)), validator: validator);
}

import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false, _sent = false;
  String? _error;
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (!email.contains('@')) { setState(() => _error = 'Please enter a valid email address.'); return; }
    setState(() { _loading = true; _error = null; });
    try { await AuthService.instance.sendPasswordReset(email); setState(() => _sent = true); }
    catch (e) { setState(() => _error = 'Could not send reset email. Check the address and try again.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primaryEmerald, foregroundColor: Colors.white, title: Text(l.authForgotPassword), elevation: 0),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryEmerald, Color(0xFF064E3B)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Padding(padding: const EdgeInsets.all(28),
          child: _sent
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.mark_email_read_rounded, size: 80, color: AppColors.goldAccent),
                  const SizedBox(height: 24),
                  Text(l.authResetEmailSent, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(l.authResetEmailSentSubtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 28),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(l.authBackToLogin, style: TextStyle(color: AppColors.goldAccent))),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 24),
                  Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.goldAccent),
                  const SizedBox(height: 16),
                  Text(l.authResetPasswordSubtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 28),
                  if (_error != null) Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade900.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: Colors.white))),
                  TextFormField(controller: _ctrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: l.authEmail, labelStyle: const TextStyle(color: Colors.white70), prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.goldAccent)))),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.goldAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: _loading ? null : _send,
                    child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l.authSendResetEmail, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ])),
      ),
    );
  }
}

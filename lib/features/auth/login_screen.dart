import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _go(Future<void> Function() fn) async {
    setState(() { _loading = true; _error = null; });
    try { await fn(); if (mounted) Navigator.pushReplacementNamed(context, '/home'); }
    catch (e) { setState(() { _error = e.toString(); }); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _skip() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.authSkipConfirmTitle),
        content: Text(l.authSkipConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.authSkipConfirmAction)),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryEmerald, const Color(0xFF064E3B)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 32), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Icon(Icons.auto_stories_rounded, size: 80, color: AppColors.goldAccent),
          const SizedBox(height: 24),
          Text(l.appTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(l.authWelcomeBack, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 48),
          if (_error != null) Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade900.withOpacity(0.6), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13))),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _loading ? null : () => _go(() async {
              final user = await AuthService.instance.signInWithGoogle();
              if (user != null) await SyncService.instance.syncOnSignIn();
            }),
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
            label: Text(l.authSignInWithGoogle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          TextButton(onPressed: _loading ? null : _skip, child: Text(l.authSkipForNow, style: const TextStyle(color: Colors.white54, fontSize: 14))),
        ]))))),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _SocialButton({required this.label, required this.icon, this.onPressed});
  @override Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}

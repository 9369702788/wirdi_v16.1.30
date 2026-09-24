import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import 'login_screen.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override State<AccountScreen> createState() => _AccountScreenState();
}
class _AccountScreenState extends State<AccountScreen> {
  bool _syncing = false; String? _msg; bool _ok = false;

  Future<void> _sync() async {
    setState(() { _syncing = true; _msg = null; });
    final l = AppLocalizations.of(context);
    try {
      await SyncService.instance.syncNow();
      setState(() { _ok = true; _msg = l.authSyncSuccess; });
    } on FirestoreRulesNotPublishedException catch (e) {
      // The single most actionable failure message this screen can
      // show -- see FirestoreRulesNotPublishedException's doc comment.
      setState(() { _ok = false; _msg = e.toString(); });
    } on PartialSyncException catch (e) {
      // Some sections failed but others succeeded -- tell the user
      // plainly instead of the previous behavior of either claiming
      // full success or (worse) a single failure aborting everything
      // silently with no visibility into what actually made it through.
      setState(() { _ok = false; _msg = 'Sync partially failed: ' + e.failedSections.join(', '); });
    } on NotSignedInException {
      // Not a real failure -- there's simply no account to sync yet
      // (the app is fully usable without signing in). Make that state
      // explicit instead of a scary generic error, and definitely
      // never claim success when nothing was actually synced.
      setState(() { _ok = false; _msg = l.authSyncNoAccount; });
    } catch (e) {
      setState(() { _ok = false; _msg = l.authSyncFailed(e.toString()); });
    } finally { setState(() => _syncing = false); }
  }

  Future<void> _signOut() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(l.authSignOutTitle), content: Text(l.authSignOutMessage),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.authSignOut))]));
    if (ok != true) return;
    await AuthService.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _deleteAccountWithReauth(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      await _performDeletion();
      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.authDeleteAccountFailed(e.toString()))));
        }
        return;
      }
      if (!context.mounted) return;
      final reauthOk = await _reauthenticate(context);
      if (!reauthOk || !context.mounted) return;
      try {
        await _performDeletion();
        if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.authDeleteAccountFailed(e2.toString()))));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.authDeleteAccountFailed(e.toString()))));
      }
    }
  }

  Future<void> _performDeletion() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid != null) {
      await SyncService.instance.deleteAllCloudData();
    }
    await AuthService.instance.deleteAccount();
  }

  Future<bool> _reauthenticate(BuildContext context) async {
    final providers = AuthService.instance.currentUserProviderIds;
    try {
      if (providers.contains('google.com')) {
        await AuthService.instance.reauthenticateWithGoogle();
        return true;
      }
      if (providers.contains('apple.com')) {
        await AuthService.instance.reauthenticateWithApple();
        return true;
      }
      if (!context.mounted) return false;
      final password = await _promptForPassword(context);
      if (password == null) return false;
      await AuthService.instance.reauthenticateWithPassword(password);
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Re-authentication failed: $e')));
      }
      return false;
    }
  }

  Future<String?> _promptForPassword(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.authPassword),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(labelText: l.authPassword),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, null), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: Text(l.authSignIn)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = AuthService.instance.currentUser;
    final lastSync = SyncService.instance.lastSyncAt;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.authAccount),
        foregroundColor: Colors.white,
        flexibleSpace: _MosaicBg(col: 2, row: 0, opacity: 0.35),
      ),
      body: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom), children: [
        if (user == null)
          // Previously this card still rendered with a blank email and a
          // generic 'U' avatar when nobody was signed in -- indistinguishable
          // at a glance from a real signed-in account with no display name.
          // That ambiguity directly caused confusion about whether sign-in
          // was actually happening. Now the signed-out state is explicit.
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 32, backgroundColor: Colors.grey.shade400,
                child: const Icon(Icons.person_outline, color: Colors.white, size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Not signed in', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 4),
                Text('Your data is stored on this device only -- sign in to back it up and sync across devices.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ])),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryEmerald),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Sign in or create an account'),
            )),
          ])))
        else
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
            CircleAvatar(radius: 32, backgroundColor: AppColors.primaryEmerald,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? Text((user.displayName ?? user.email ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)) : null),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (user.displayName?.isNotEmpty == true) Text(user.displayName!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text(user.email ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.primaryEmerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(l.authCloudSyncEnabled, style: TextStyle(fontSize: 11, color: AppColors.primaryEmerald, fontWeight: FontWeight.w600))),
            ])),
          ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.authCloudSync, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(lastSync != null ? l.authLastSynced(lastSync.toLocal().toString().substring(0, 16)) : l.authNeverSynced, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          if (_msg != null) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _ok ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Text(_msg!, style: TextStyle(fontSize: 12, color: _ok ? Colors.green.shade800 : Colors.red.shade800))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: AppColors.primaryEmerald), onPressed: _syncing ? null : _sync,
            icon: _syncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_sync_rounded),
            label: Text(_syncing ? l.authSyncing : l.authSyncNow))),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.authWhatsSynced, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...[
            (Icons.menu_book_rounded, l.authSyncQuran), (Icons.timeline_rounded, l.authSyncKhatma),
            (Icons.favorite_rounded, l.authSyncFavorites), (Icons.bookmark_rounded, l.authSyncBookmarks),
            (Icons.radio_button_checked_rounded, l.authSyncTasbeeh), (Icons.self_improvement_rounded, l.authSyncAzkar),
            (Icons.access_time_rounded, l.authSyncPrayers), (Icons.military_tech_rounded, l.authSyncAchievements),
            (Icons.settings_rounded, l.authSyncSettings),
          ].map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(item.$1, size: 16, color: AppColors.primaryEmerald), const SizedBox(width: 10), Text(item.$2, style: const TextStyle(fontSize: 13))]))),
        ]))),
        const SizedBox(height: 16),
        
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            title: Text(l.authDeleteAccountTitle,
                style: const TextStyle(color: Colors.red)),
            subtitle: Text(
                l.authDeleteAccountSubtitle,
                style: const TextStyle(fontSize: 12)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l.authDeleteAccountConfirmTitle),
                  content: Text(l.authDeleteAccountConfirmMessage),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l.commonCancel)),
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l.authDeleteEverything)),
                  ],
                ),
              );
              if (confirmed != true) return;
              await _deleteAccountWithReauth(context);
            },
          ),
        ),
        Card(child: ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.red), title: Text(l.authSignOut, style: const TextStyle(color: Colors.red)), onTap: _signOut)),
      ]),
    );
  }
}


class _MosaicBg extends StatefulWidget {
  final int col; // 0-indexed, 0..4
  final int row; // 0-indexed, 0..1
  final double opacity;
  const _MosaicBg({required this.col, required this.row, this.opacity = 0.4});

  @override
  State<_MosaicBg> createState() => _MosaicBgState();
}

class _MosaicBgState extends State<_MosaicBg> {
  static ui.Image? _cachedImage;
  ui.Image? _image;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    if (_cachedImage != null) {
      _image = _cachedImage;
    } else {
      final stream = const AssetImage('assets/images/wirdi_mosaic.webp')
          .resolve(const ImageConfiguration());
      _listener = ImageStreamListener((info, _) {
        _cachedImage = info.image;
        if (mounted) setState(() => _image = info.image);
      });
      stream.addListener(_listener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (img != null)
            CustomPaint(painter: _MosaicCellPainter(image: img, col: widget.col, row: widget.row))
          else
            Container(color: const Color(0xFF0F766E)),
          Container(color: Colors.black.withValues(alpha: widget.opacity)),
        ],
      ),
    );
  }
}

class _MosaicCellPainter extends CustomPainter {
  final ui.Image image;
  final int col;
  final int row;
  static const int cols = 5;
  static const int rows = 2;
  _MosaicCellPainter({required this.image, required this.col, required this.row});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = image.width / cols;
    final cellH = image.height / rows;
    final srcAspect = cellW / cellH;
    final dstAspect = size.width / size.height;
    Rect src;
    if (srcAspect > dstAspect) {
      final visW = cellH * dstAspect;
      final dx = (cellW - visW) / 2;
      src = Rect.fromLTWH(col * cellW + dx, row * cellH, visW, cellH);
    } else {
      final visH = cellW / dstAspect;
      final dy = (cellH - visH) / 2;
      src = Rect.fromLTWH(col * cellW, row * cellH + dy, cellW, visH);
    }
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _MosaicCellPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.col != col || oldDelegate.row != row;
}

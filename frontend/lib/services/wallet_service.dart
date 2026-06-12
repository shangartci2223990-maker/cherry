import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  ReownAppKitModal? _modal;
  final ValueNotifier<String?> connectedWallet = ValueNotifier(null);

  Future<void> _ensureInitialized(BuildContext context) async {
    if (_modal != null) return;

    _modal = ReownAppKitModal(
      context: context,
      projectId: '1b69b0ce35d16e26e8dcd9e5f650f618',
      metadata: const PairingMetadata(
        name: 'anonymous',
        description: 'Private anonymous doctor appointments',
        url: 'https://localhost',
        icons: ['https://avatars.githubusercontent.com/u/37784886'],
        redirect: Redirect(
          native: 'anonymous://app',
          universal: 'https://localhost',
        ),
      ),
    );

    await _modal!.init();

    _modal!.onModalConnect.subscribe((_) {
      final address = _modal!.session?.getAddress('eip155');
      debugPrint('🔗 Wallet connected: $address');
      connectedWallet.value = address;
    });

    _modal!.onModalDisconnect.subscribe((_) {
      connectedWallet.value = null;
    });
  }

  Future<void> connectWallet(BuildContext context) async {
    await _ensureInitialized(context);
    _modal!.openModalView();
  }

  // Try to restore a previous MetaMask session.
  // Called when the app starts — if already connected skip the login screen.
  Future<void> tryRestoreSession(BuildContext context) async {
    await _ensureInitialized(context);

    // Check if there is an active session.
    if (_modal!.session != null) {
      final address = _modal!.session?.getAddress('eip155');
      if (address != null) {
        connectedWallet.value = address;
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await _modal?.disconnect();
    } catch (_) {
      // Ignore errors from the modal — we reset state regardless.
    } finally {
      // Null out the modal so the next connectWallet call starts completely
      // fresh. Without this, the next openModalView() on a half-disconnected
      // modal does nothing, forcing the user to kill and restart the app.
      _modal = null;
      connectedWallet.value = null;
    }
  }

  bool get isConnected => connectedWallet.value != null;
    // Expose modal so blockchain service can use it to send transactions.
  ReownAppKitModal? get modal => _modal;
}

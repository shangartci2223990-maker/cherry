import 'package:flutter/material.dart';
import 'wallet_service.dart';
import 'api_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? wallet;
  final String? role;

  const AuthState({required this.status, this.wallet, this.role});
}

// Single source of truth for who is logged in and what role they have.
// All navigation in the app is driven by this state.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ValueNotifier<AuthState> state = ValueNotifier(
    const AuthState(status: AuthStatus.loading),
  );

  static const String _adminWallet = '0x7E678aD083307B91e619d07345F1A47Ea1D1503C';

  bool _initialized = false;

  // Called once at app startup from AppRouter.
  // Tries to restore any previous session, then sets up the wallet listener
  // for all future logins/logouts.
  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;
    _initialized = true;

    // Attempt to restore a saved WalletConnect session.
    // We do NOT add the listener yet — we handle this restoration manually
    // to avoid double-processing the same wallet address.
    await WalletService().tryRestoreSession(context);
    final wallet = WalletService().connectedWallet.value;

    if (wallet != null) {
      await _resolveRole(wallet);
    } else {
      state.value = const AuthState(status: AuthStatus.unauthenticated);
    }

    // Only now attach the listener — from this point on, any wallet
    // connection or disconnection is handled reactively.
    WalletService().connectedWallet.addListener(_onWalletChanged);
  }

  // Called whenever WalletService.connectedWallet changes value.
  void _onWalletChanged() {
    final wallet = WalletService().connectedWallet.value;
    if (wallet == null) {
      // Wallet disconnected — go back to login screen.
      state.value = const AuthState(status: AuthStatus.unauthenticated);
    } else {
      // Wallet connected — figure out what role this address has.
      _resolveRole(wallet);
    }
  }

  // Asks the backend what role this wallet belongs to, then updates state.
  Future<void> _resolveRole(String wallet) async {
    state.value = const AuthState(status: AuthStatus.loading);
    try {
      final role = await ApiService.checkRole(
        walletAddress: wallet,
        adminWallet: _adminWallet,
      );
      state.value = AuthState(
        status: AuthStatus.authenticated,
        wallet: wallet,
        role: role,
      );
    } catch (_) {
      // If the backend is unreachable, don't leave the user stuck on a
      // loading screen — send them back to login.
      state.value = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    await WalletService().disconnect();
    state.value = const AuthState(status: AuthStatus.unauthenticated);
  }
}

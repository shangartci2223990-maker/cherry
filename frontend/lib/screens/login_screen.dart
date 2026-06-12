import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/services/wallet_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/theme/app_colors.dart';

// LoginScreen has one job: let the user initiate a wallet connection.
// It does not check sessions, does not navigate, and does not know about roles.
// AppRouter observes AuthService state and handles all of that automatically.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isConnecting = false;
  final _settingsKey = GlobalKey();

  Future<void> _connect() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);
    try {
      await WalletService().connectWallet(context);
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _showTestSelector() async {
    final box = _settingsKey.currentContext!.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;

    final selected = await showMenu<String>(
      context: context,
      color: AppColors.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height + 4,
        position.dx + 160,
        0,
      ),
      items: const [
        PopupMenuItem(value: 'admin', child: Text('Admin', style: TextStyle(fontSize: 18, color: AppColors.text))),
        PopupMenuItem(value: 'doctor', child: Text('Doctor', style: TextStyle(fontSize: 18, color: AppColors.text))),
        PopupMenuItem(value: 'patient', child: Text('Patient', style: TextStyle(fontSize: 18, color: AppColors.text))),
      ],
    );

    if (selected == null) return;

    const wallets = {
      'patient': '0xf273cB29D47aEfA30C206f021b2Bb0e1DC27ba7c',
      'doctor': '0xE8a807126B14D7574c74D6A343D2aaE3078412E2',
      'admin': '0x7E678aD083307B91e619d07345F1A47Ea1D1503C',
    };

    AuthService().state.value = AuthState(
      status: AuthStatus.authenticated,
      wallet: wallets[selected]!,
      role: selected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [

            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Anonymous',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontFamily: 'Caveat',
                                fontSize: 34,
                                color: AppColors.text,
                              ),
                              children: [
                                TextSpan(text: 'Your wallet address is your '),
                                TextSpan(
                                  text: 'only',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(text: ' identity.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 64),
                  child: GestureDetector(
                    onTap: _connect,
                    child: _isConnecting
                        ? const SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          )
                        : SvgPicture.asset(
                            'assets/icons/MetaMask-icon-fox.svg',
                            width: 64,
                            height: 64,
                          ),
                  ),
                ),

              ],
            ),

            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                key: _settingsKey,
                onTap: _showTestSelector,
                child: SvgPicture.asset(
                  'assets/icons/settings_code.svg',
                  width: 34,
                  height: 34,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

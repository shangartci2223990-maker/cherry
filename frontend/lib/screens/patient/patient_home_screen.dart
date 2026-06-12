import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/screens/patient/doctor_list_screen.dart';
import 'package:frontend/screens/patient/my_appointments_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/theme/app_colors.dart';

class PatientHomeScreen extends StatefulWidget {
  final String patientWallet;

  const PatientHomeScreen({
    super.key,
    required this.patientWallet,
  });

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;
  final _menuKey = GlobalKey();

  String get _truncatedWallet {
    final w = widget.patientWallet;
    return '${w.substring(0, 6)}...${w.substring(w.length - 4)}';
  }

  Future<void> _showMenu() async {
    final box = _menuKey.currentContext!.findRenderObject() as RenderBox;
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
      items: [
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppColors.text, size: 24),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(fontSize: 18, color: AppColors.text)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/info-circle.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              const Text('Info', style: TextStyle(fontSize: 18, color: AppColors.text)),
            ],
          ),
        ),
      ],
    );

    if (selected == 'logout') AuthService().logout();
    if (selected == 'info') _showInfoPage();
  }

  void _showInfoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _PatientInfoPage()),
    );
  }

  void _copyWallet() {
    Clipboard.setData(ClipboardData(text: widget.patientWallet));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Address copied',
          style: TextStyle(color: AppColors.text, fontSize: 14),
        ),
        backgroundColor: AppColors.background,
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DoctorListScreen(),
      MyAppointmentsScreen(patientWallet: widget.patientWallet),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/wallet.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              _truncatedWallet,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _copyWallet,
              child: SvgPicture.asset(
                'assets/icons/copy.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            key: _menuKey,
            onTap: _showMenu,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SvgPicture.asset(
                'assets/icons/menu.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: AppColors.background,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/search.svg',
                  width: 34,
                  height: 34,
                  colorFilter: ColorFilter.mode(
                    _currentIndex == 0 ? AppColors.primary : AppColors.text,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 34,
                  height: 34,
                  colorFilter: ColorFilter.mode(
                    _currentIndex == 1 ? AppColors.primary : AppColors.text,
                    BlendMode.srcIn,
                  ),
                ),
                label: '',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientInfoPage extends StatelessWidget {
  const _PatientInfoPage();

  Widget _row(String label, List<String> actions, {bool isHeader = false, String number = ''}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Text(
            number,
            style: const TextStyle(fontSize: 16, color: AppColors.primary, fontFamily: 'UbuntuMono', fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isHeader ? 24 : 16,
              fontFamily: isHeader ? 'Caveat' : 'UbuntuMono',
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: isHeader ? AppColors.primary : AppColors.text,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 4),
                Text(
                  actions[i],
                  style: TextStyle(
                    fontSize: isHeader ? 24 : 16,
                    fontFamily: isHeader ? 'Caveat' : 'UbuntuMono',
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    color: isHeader ? AppColors.primary : AppColors.text,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE8E8E8)),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Patient',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          '✗',
                          style: TextStyle(fontSize: 24, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE8E8E8)),
                  const SizedBox(height: 16),
                  _row('Status', ['Action'], isHeader: true),
                  const SizedBox(height: 12),
                  _row('booked', ['Cancel Appointment (partial refund)'], number: '1'),
                  const SizedBox(height: 12),
                  _row('active', ['Open Chat'], number: '2'),
                  const SizedBox(height: 12),
                  _row('completed', ['nothing'], number: '3'),
                  const SizedBox(height: 12),
                  _row('cancelled', ['nothing'], number: '4'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

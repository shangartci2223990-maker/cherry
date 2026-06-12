import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/screens/admin/add_doctor_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminWallet;

  const AdminDashboardScreen({super.key, required this.adminWallet});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;
  String? error;
  final _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    try {
      final result = await ApiService.getAllAppointments();
      setState(() {
        appointments = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Could not load appointments.';
        isLoading = false;
      });
    }
  }

  double calculateEarnings() {
    final completed = appointments.where((a) => a['status'] == 'completed').length;
    return completed * 0.001;
  }

  int completedCount() {
    return appointments.where((a) => a['status'] == 'completed').length;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
      case 'cancelled':
        return AppColors.primary;
      default:
        return AppColors.text;
    }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw.endsWith('Z') ? raw : '${raw}Z').toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}/${dt.year}  $hour:$min';
    } catch (_) {
      return raw;
    }
  }

  String _shorten(String w) =>
      w.length < 10 ? w : '${w.substring(0, 6)}...${w.substring(w.length - 4)}';

  String get _truncatedWallet => _shorten(widget.adminWallet);

  void _copyWallet() {
    Clipboard.setData(ClipboardData(text: widget.adminWallet));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied', style: TextStyle(color: AppColors.text, fontSize: 14)),
        backgroundColor: AppColors.background,
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        duration: Duration(seconds: 2),
      ),
    );
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
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/logout.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              const Text('Logout', style: TextStyle(fontSize: 18, color: AppColors.text)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_doctor',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/nurse.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              const Text('Add Doctor', style: TextStyle(fontSize: 18, color: AppColors.text)),
            ],
          ),
        ),
      ],
    );

    if (selected == 'logout') AuthService().logout();
    if (selected == 'add_doctor' && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDoctorScreen()));
    }
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE8E8E8)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(fontSize: 18, color: AppColors.text),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: AppColors.text),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { isLoading = true; error = null; });
                          loadAppointments();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Try Again', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: appointments.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 24, bottom: 16),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontFamily: 'Caveat',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE8E8E8)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Earnings',
                                    style: TextStyle(fontSize: 18, color: AppColors.text),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${calculateEarnings().toStringAsFixed(3)} ETH',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${completedCount()} completed × 0.001 ETH fee',
                                    style: const TextStyle(fontSize: 16, color: AppColors.text),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _statCard('${appointments.length}', 'Total'),
                                const SizedBox(width: 8),
                                _statCard(
                                  '${appointments.where((a) => a['status'] == 'active').length}',
                                  'Active',
                                ),
                                const SizedBox(width: 8),
                                _statCard(
                                  '${appointments.where((a) => a['status'] == 'cancelled').length}',
                                  'Cancelled',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (appointments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 32),
                                child: Center(
                                  child: Text(
                                    'No appointments yet.',
                                    style: TextStyle(fontSize: 16, color: AppColors.text),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }

                      final appointment = appointments[index - 1];
                      final status = appointment['status'] as String;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE8E8E8)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'patient',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _shorten(appointment['patient_wallet']),
                                          style: const TextStyle(fontSize: 16, color: AppColors.text),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'doctor',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _shorten(appointment['doctor_wallet']),
                                          style: const TextStyle(fontSize: 16, color: AppColors.text),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatTime(appointment['scheduled_time']),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

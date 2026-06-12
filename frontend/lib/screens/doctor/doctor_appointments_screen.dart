import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/screens/shared/chat_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/wallet_service.dart';
import 'package:frontend/services/blockchain_service.dart';
import 'package:frontend/theme/app_colors.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final String doctorWallet;

  const DoctorAppointmentsScreen({
    super.key,
    required this.doctorWallet,
  });

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
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
      final result = await ApiService.getAppointments(widget.doctorWallet);
      setState(() {
        appointments = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Could not load appointments. Is the backend running?';
        isLoading = false;
      });
    }
  }

  String get _truncatedWallet {
    final w = widget.doctorWallet;
    return '${w.substring(0, 6)}...${w.substring(w.length - 4)}';
  }

  String _truncatedAddress(String w) =>
      '${w.substring(0, 6)}...${w.substring(w.length - 4)}';

  void _copyWallet() {
    Clipboard.setData(ClipboardData(text: widget.doctorWallet));
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

  void _copyAddress(String wallet) {
    Clipboard.setData(ClipboardData(text: wallet));
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

  void _showInfoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _DoctorInfoPage()),
    );
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
                                'My Appointments',
                                style: TextStyle(
                                  fontFamily: 'Caveat',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
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
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _truncatedAddress(appointment['patient_wallet']),
                                              style: const TextStyle(fontSize: 16, color: AppColors.text),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _copyAddress(appointment['patient_wallet']),
                                              child: SvgPicture.asset(
                                                'assets/icons/copy.svg',
                                                width: 18,
                                                height: 18,
                                                colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
                                              ),
                                            ),
                                          ],
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

                                        if (status == 'booked') ...[
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: () async {
                                              try {
                                                final doctorWallet = WalletService().connectedWallet.value;
                                                if (doctorWallet == null) throw Exception('Wallet not connected');
                                                final txHash = await BlockchainService().startMeeting(
                                                  doctorAddress: doctorWallet,
                                                  appointmentId: int.parse(appointment['blockchain_appointment_id'].toString()),
                                                );
                                                await BlockchainService().waitForTransaction(txHash);
                                                await ApiService.updateAppointmentStatus(
                                                  appointmentId: appointment['id'],
                                                  status: 'active',
                                                );
                                                loadAppointments();
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Meeting started — chat is now open',
                                                      style: TextStyle(color: AppColors.text, fontSize: 14),
                                                    ),
                                                    backgroundColor: AppColors.background,
                                                    behavior: SnackBarBehavior.floating,
                                                    elevation: 2,
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to start meeting: $e'),
                                                    backgroundColor: AppColors.primary,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.primary, width: 2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Start Meeting',
                                                  style: TextStyle(fontSize: 16, color: AppColors.text),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              try {
                                                final doctorWallet = WalletService().connectedWallet.value;
                                                if (doctorWallet == null) throw Exception('Wallet not connected');
                                                final txHash = await BlockchainService().cancelByDoctor(
                                                  doctorAddress: doctorWallet,
                                                  appointmentId: int.parse(appointment['blockchain_appointment_id'].toString()),
                                                );
                                                await BlockchainService().waitForTransaction(txHash);
                                                await ApiService.updateAppointmentStatus(
                                                  appointmentId: appointment['id'],
                                                  status: 'cancelled',
                                                );
                                                loadAppointments();
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Appointment cancelled — patient refunded',
                                                      style: TextStyle(color: AppColors.text, fontSize: 14),
                                                    ),
                                                    backgroundColor: AppColors.background,
                                                    behavior: SnackBarBehavior.floating,
                                                    elevation: 2,
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to cancel: $e'),
                                                    backgroundColor: AppColors.primary,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.primary, width: 2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Cancel Appointment',
                                                  style: TextStyle(fontSize: 16, color: AppColors.text),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],

                                        if (status == 'active') ...[
                                          const SizedBox(height: 12),
                                          GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ChatScreen(
                                                  appointmentId: appointment['id'],
                                                  otherPersonLabel: appointment['patient_wallet'],
                                                ),
                                              ),
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.primary, width: 2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Open Chat',
                                                  style: TextStyle(fontSize: 16, color: AppColors.text),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              try {
                                                await ApiService.updateAppointmentStatus(
                                                  appointmentId: appointment['id'],
                                                  status: 'completed',
                                                );
                                                loadAppointments();
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Meeting completed — chat deleted',
                                                      style: TextStyle(color: AppColors.text, fontSize: 14),
                                                    ),
                                                    backgroundColor: AppColors.background,
                                                    behavior: SnackBarBehavior.floating,
                                                    elevation: 2,
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to end meeting: $e'),
                                                    backgroundColor: AppColors.primary,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.primary, width: 2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'End Meeting',
                                                  style: TextStyle(fontSize: 16, color: AppColors.text),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],

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

class _DoctorInfoPage extends StatelessWidget {
  const _DoctorInfoPage();

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
                          'Doctor',
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
                  _row('booked', ['Start Meeting', 'Cancel Appointment (full refund to patient)'], number: '1'),
                  const SizedBox(height: 12),
                  _row('active', ['Open Chat', 'End Meeting'], number: '2'),
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

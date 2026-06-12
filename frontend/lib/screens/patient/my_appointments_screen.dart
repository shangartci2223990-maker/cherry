import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/screens/shared/chat_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/wallet_service.dart';
import 'package:frontend/services/blockchain_service.dart';
import 'package:frontend/theme/app_colors.dart';

class MyAppointmentsScreen extends StatefulWidget {
  final String patientWallet;

  const MyAppointmentsScreen({
    super.key,
    required this.patientWallet,
  });

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<dynamic> appointments = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    try {
      final result = await ApiService.getAppointments(widget.patientWallet);
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

  String _truncatedWallet(String w) =>
      '${w.substring(0, 6)}...${w.substring(w.length - 4)}';

  void _copyWallet(String wallet) {
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
                                          'doctor',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _truncatedWallet(appointment['doctor_wallet']),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: AppColors.text,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _copyWallet(appointment['doctor_wallet']),
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
                                                final patientWallet = WalletService().connectedWallet.value;
                                                if (patientWallet == null) throw Exception('Wallet not connected');
                                                final txHash = await BlockchainService().cancelByPatient(
                                                  patientAddress: patientWallet,
                                                  appointmentId: int.parse(
                                                    appointment['blockchain_appointment_id'].toString(),
                                                  ),
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
                                                      'Appointment cancelled — partial refund sent',
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
                                                  otherPersonLabel: appointment['doctor_wallet'],
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

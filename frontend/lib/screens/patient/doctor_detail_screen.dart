import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/services/wallet_service.dart';
import 'package:frontend/services/blockchain_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_colors.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorName;
  final String doctorSpecialty;
  final String doctorWallet;

  const DoctorDetailScreen({
    super.key,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.doctorWallet,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  DateTime? selectedDateTime;
  bool isLoading = false;

  String get _truncatedWallet {
    final w = widget.doctorWallet;
    return '${w.substring(0, 6)}...${w.substring(w.length - 4)}';
  }

  void _copyWallet() {
    Clipboard.setData(ClipboardData(text: widget.doctorWallet));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied', style: TextStyle(color: AppColors.text, fontSize: 16)),
        backgroundColor: AppColors.background,
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.primary,
            onSecondary: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.primary,
            onSecondary: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year, date.month, date.day,
        time.hour, time.minute,
      );
    });
  }

  String get _formattedDate {
    if (selectedDateTime == null) return 'Pick a date and time';
    final d = selectedDateTime!;
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $hour:$min';
  }

  Future<void> _book() async {
    setState(() => isLoading = true);
    try {
      final patientWallet = WalletService().connectedWallet.value;
      if (patientWallet == null) throw Exception('Wallet not connected');

      final txHash = await BlockchainService().bookAppointment(
        patientAddress: patientWallet,
        doctorAddress: widget.doctorWallet,
      );

      await BlockchainService().waitForTransaction(txHash);
      final blockchainId = await BlockchainService().getAppointmentCounter();

      await ApiService.createAppointment(
        patientWallet: patientWallet,
        doctorWallet: widget.doctorWallet,
        blockchainTxId: txHash,
        blockchainAppointmentId: blockchainId,
        scheduledTime: selectedDateTime!.toIso8601String(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booked. Check My Appointments.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    setState(() => isLoading = false);
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.doctorName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.doctorSpecialty,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _truncatedWallet,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _copyWallet,
                                  child: SvgPicture.asset(
                                    'assets/icons/copy.svg',
                                    width: 18,
                                    height: 18,
                                    colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          '✗',
                          style: TextStyle(
                            fontSize: 24,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE8E8E8)),
                  const SizedBox(height: 16),

                  const Text(
                    '0.01 ETH per appointment',
                    style: TextStyle(fontSize: 16, color: AppColors.text),
                  ),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _formattedDate,
                          style: const TextStyle(fontSize: 16, color: AppColors.text),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: selectedDateTime == null || isLoading ? null : _book,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Book Appointment',
                                style: TextStyle(fontSize: 16, color: AppColors.text),
                              ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

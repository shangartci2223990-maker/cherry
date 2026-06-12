import 'package:flutter/material.dart';
import 'package:frontend/screens/patient/doctor_detail_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_colors.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<dynamic> doctors = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    try {
      final result = await ApiService.getDoctors();
      setState(() {
        doctors = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Could not load doctors. Is the backend running?';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            error = null;
                          });
                          loadDoctors();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: loadDoctors,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: doctors.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 24, bottom: 16),
                          child: Text(
                            'Doctors',
                            style: TextStyle(
                              fontFamily: 'Caveat',
                              fontSize:34,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      final doctor = doctors[index - 1];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) => DoctorDetailScreen(
                              doctorName: doctor['name'],
                              doctorSpecialty: doctor['specialty'],
                              doctorWallet: doctor['wallet_address'],
                            ),
                            transitionsBuilder: (_, animation, _, child) {
                              return ScaleTransition(
                                scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                                ),
                                child: FadeTransition(opacity: animation, child: child),
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 250),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctor['specialty'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

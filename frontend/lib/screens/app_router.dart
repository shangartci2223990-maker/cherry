import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/patient/patient_home_screen.dart';
import 'package:frontend/screens/doctor/doctor_appointments_screen.dart';
import 'package:frontend/screens/admin/admin_dashboard_screen.dart';

// AppRouter lives at the root of the widget tree and is never unmounted.
// It listens to AuthService and swaps the visible screen when auth state changes.
// No screen in this app needs to call Navigator.pushReplacement for auth transitions.
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  @override
  void initState() {
    super.initState();
    AuthService().state.addListener(_onAuthStateChanged);
    // Initialize after the first frame so the widget tree is fully built
    // before any navigation decisions are made.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthService().initialize(context);
    });
  }

  @override
  void dispose() {
    AuthService().state.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService().state.value;

    if (auth.status == AuthStatus.loading) {
      return const _SplashScreen();
    }

    if (auth.status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }

    // Authenticated — route to the correct dashboard for this role.
    if (auth.role == 'admin') {
      return AdminDashboardScreen(adminWallet: auth.wallet!);
    }
    if (auth.role == 'doctor') {
      return DoctorAppointmentsScreen(doctorWallet: auth.wallet!);
    }
    return PatientHomeScreen(patientWallet: auth.wallet!);
  }
}

// Shown while the app checks for a saved session on startup.
// Keeps the screen blank and consistent — no flash of the login screen.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFD20A2E)),
      ),
    );
  }
}

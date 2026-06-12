import 'package:flutter/material.dart';
import 'package:frontend/screens/app_router.dart';
import 'package:frontend/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Anonymous());
}

class Anonymous extends StatelessWidget {
  const Anonymous({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anonymous Doctor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'UbuntuMono',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          surface: AppColors.background,
          onSurface: AppColors.text,
        ),
      ),
      home: const AppRouter(),
    );
  }
}

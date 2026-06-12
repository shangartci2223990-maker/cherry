// This screen allows the admin to add a new doctor to the platform.
// Simple form — name, specialty, wallet address.

import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_colors.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  // Controllers to read what the admin typed in each field.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();

  // Tracks if the form is currently submitting.
  bool isLoading = false;

  // Submits the form — calls the real backend API.
  void submitDoctor() async {
    // Make sure all fields are filled.
    if (_nameController.text.trim().isEmpty ||
        _specialtyController.text.trim().isEmpty ||
        _walletController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields', style: TextStyle(color: AppColors.text, fontSize: 14)),
          backgroundColor: AppColors.background,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Call the real backend API.
      await ApiService.createDoctor(
        name: _nameController.text.trim(),
        specialty: _specialtyController.text.trim(),
        walletAddress: _walletController.text.trim(),
      );

      // Show success message.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor added successfully', style: TextStyle(color: AppColors.text, fontSize: 14)),
          backgroundColor: AppColors.background,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear the form.
      _nameController.clear();
      _specialtyController.clear();
      _walletController.clear();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add doctor. Try again.', style: TextStyle(color: AppColors.text, fontSize: 14)),
          backgroundColor: AppColors.background,
          behavior: SnackBarBehavior.floating,
          elevation: 2,
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  Widget _buildField(TextEditingController controller, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.text, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.text.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          'Add Doctor',
          style: TextStyle(color: AppColors.text),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title.
            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                'New Doctor',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),

            const Text(
              'Add a new doctor to the platform.',
              style: TextStyle(color: AppColors.text, fontSize: 16),
            ),

            const SizedBox(height: 32),

            // Doctor name field.
            _buildField(_nameController, 'Full Name', 'Cherry'),

            const SizedBox(height: 20),

            // Specialty field.
            _buildField(_specialtyController, 'Specialty', 'Therapist, Psychiatrist'),

            const SizedBox(height: 20),

            // Wallet address field.
            _buildField(_walletController, 'Wallet Address', '0x...'),

            const SizedBox(height: 40),

            // Submit button.
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitDoctor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Add Doctor',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

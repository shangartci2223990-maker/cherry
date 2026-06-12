// This file handles all communication with the FastAPI backend.
// Every screen will use this service to get and send data.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiService {

  // ─────────────────────────────────────────
  // DOCTORS
  // ─────────────────────────────────────────

  // Get all doctors from the backend.
  static Future<List<dynamic>> getDoctors() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/doctors/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load doctors');
    }
  }

  // Admin creates a new doctor.
  static Future<void> createDoctor({
    required String name,
    required String specialty,
    required String walletAddress,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/doctors/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'specialty': specialty,
        'wallet_address': walletAddress,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create doctor');
    }
  }

  // ─────────────────────────────────────────
  // APPOINTMENTS
  // ─────────────────────────────────────────

  // Get every appointment in the system — admin only.
  static Future<List<dynamic>> getAllAppointments() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/appointments/'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  // Get all appointments for a wallet address.
  static Future<List<dynamic>> getAppointments(String walletAddress) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/appointments/$walletAddress'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  // Save appointment record after blockchain confirms.
  static Future<void> createAppointment({
    required String patientWallet,
    required String doctorWallet,
    required String blockchainTxId,
    required int blockchainAppointmentId,
    required String scheduledTime,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/appointments/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patient_wallet': patientWallet,
        'doctor_wallet': doctorWallet,
        'blockchain_tx_id': blockchainTxId,
        'blockchain_appointment_id': blockchainAppointmentId,
        'scheduled_time': scheduledTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create appointment');
    }
  }

  // Update appointment status.
  static Future<void> updateAppointmentStatus({
    required int appointmentId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/appointments/$appointmentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment');
    }
  }

  // ─────────────────────────────────────────
  // ROLE CHECK
  // ─────────────────────────────────────────

  // Check what role a wallet address belongs to.
  // Returns 'admin', 'doctor', or 'patient'.
  static Future<String> checkRole({
    required String walletAddress,
    required String adminWallet,
  }) async {
    // Check if this is the admin wallet.
    if (walletAddress.toLowerCase() == adminWallet.toLowerCase()) {
      return 'admin';
    }

    // Check if this wallet belongs to a doctor.
    final doctors = await getDoctors();
    for (final doctor in doctors) {
      if (doctor['wallet_address'].toLowerCase() == walletAddress.toLowerCase()) {
        return 'doctor';
      }
    }

    // Otherwise it is a patient.
    return 'patient';
  }
}

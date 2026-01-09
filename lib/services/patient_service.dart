import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/patient.dart';
import 'auth_service.dart';

class PatientService {
  final String baseUrl = 'http://maia.clinic/api';
  final AuthService authService;

  PatientService(this.authService);

  Future<List<Patient>> getPatients() async {
    final token = await authService.getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/patients'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Patient.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load patients: ${response.statusCode}');
    }
  }

  Future<Map<String, String>> createPatient({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? dateOfBirth,
    String? gender,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    final token = await authService.getAccessToken();

    final response = await http.post(
      Uri.parse('$baseUrl/patients'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'auth': {
          'email': email,
          'password': password,
        },
        'personal_info': {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'dateOfBirth': dateOfBirth,
          'gender': gender,
          'phone': phone,
          'address': address,
          'city': city,
          'state': state,
          'zipCode': zipCode,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'personalInfoId': data['personalInfoId'],
        'patientId': data['patientId'],
        'authUserId': data['authUserId'],
      };
    } else {
      throw Exception('Failed to create patient: ${response.statusCode}');
    }
  }
}

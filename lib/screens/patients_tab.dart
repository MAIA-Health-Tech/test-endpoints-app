import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import '../models/patient.dart';

class PatientsTab extends StatefulWidget {
  final PatientService patientService;

  const PatientsTab({super.key, required this.patientService});

  @override
  State<PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<PatientsTab> {
  List<Patient>? _patients;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final patients = await widget.patientService.getPatients();
      setState(() {
        _patients = patients;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_errorMessage',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPatients,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _patients == null || _patients!.isEmpty
                  ? const Center(child: Text('No patients found'))
                  : RefreshIndicator(
                      onRefresh: _loadPatients,
                      child: ListView.builder(
                        itemCount: _patients!.length,
                        itemBuilder: (context, index) {
                          final patient = _patients![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: patient.personalInfo.photo !=
                                            null &&
                                        patient.personalInfo.photo!.isNotEmpty
                                    ? NetworkImage(
                                        'http://maia.clinic${patient.personalInfo.photo}',
                                      )
                                    : null,
                                child: patient.personalInfo.photo == null ||
                                        patient.personalInfo.photo!.isEmpty
                                    ? Text(
                                        patient.personalInfo.firstName[0]
                                            .toUpperCase(),
                                      )
                                    : null,
                              ),
                              title: Text(patient.fullName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (patient.personalInfo.email != null)
                                    Text('Email: ${patient.personalInfo.email}'),
                                  if (patient.personalInfo.phone != null &&
                                      patient.personalInfo.phone!.isNotEmpty)
                                    Text('Phone: ${patient.personalInfo.phone}'),
                                  Text(
                                    'ID: ${patient.id}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPatients,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import '../services/upload_service.dart';
import '../services/patient_service.dart';
import '../services/websocket_service.dart';
import '../models/patient.dart';

class UploadTab extends StatefulWidget {
  final UploadService uploadService;
  final PatientService patientService;
  final WebSocketService webSocketService;

  const UploadTab({
    super.key,
    required this.uploadService,
    required this.patientService,
    required this.webSocketService,
  });

  @override
  State<UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<UploadTab> {
  List<Patient>? _patients;
  Patient? _selectedPatient;
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isRecording = false;
  double _uploadProgress = 0.0;
  String? _successMessage;
  String? _errorMessage;
  String _audioType = 'medical'; // Default to medical

  // Audio recording
  final _audioRecorder = AudioRecorder();
  String? _recordingPath;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
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

      // Auto-select patient if there's a notification with patientId
      final notificationPatientId = widget.webSocketService.lastPatientIdFromNotification;
      if (notificationPatientId != null && patients.isNotEmpty) {
        final matchingPatient = patients.firstWhere(
          (p) => p.id == notificationPatientId,
          orElse: () => patients.first,
        );
        setState(() {
          _selectedPatient = matchingPatient;
          _successMessage = 'Auto-selected patient from notification: ${matchingPatient.fullName}';
        });
      }
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

  Future<void> _startRecording() async {
    try {
      // Request permission
      if (await _audioRecorder.hasPermission()) {
        // Get temporary directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordingPath = filePath;
          _recordingSeconds = 0;
          _errorMessage = null;
        });

        // Start timer
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      } else {
        setState(() {
          _errorMessage = 'Microphone permission denied';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();

      if (path != null) {
        setState(() {
          _isRecording = false;
          _selectedFilePath = path;
          _selectedFileName = path.split('/').last;
          _successMessage = 'Recording saved: $_selectedFileName';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error stopping recording: $e';
        _isRecording = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _uploadFile() async {
    // Use manually selected patient first, fallback to notification patientId
    final notificationPatientId = widget.webSocketService.lastPatientIdFromNotification;
    final patientIdToUse = _selectedPatient?.id ?? notificationPatientId;

    if (patientIdToUse == null) {
      setState(() {
        _errorMessage = 'Please select a patient or receive a notification with patient ID';
      });
      return;
    }

    if (_selectedFilePath == null) {
      setState(() {
        _errorMessage = 'Please record or select an audio file';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final jobId = await widget.uploadService.uploadConversation(
        patientId: patientIdToUse,
        audioFilePath: _selectedFilePath!,
        type: _audioType,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      // Subscribe to the jobId channel to receive processing updates
      widget.webSocketService.subscribeToChannel(jobId);

      setState(() {
        _successMessage = 'Upload successful!\nPatient ID: $patientIdToUse\nJob ID: $jobId\nSubscribed to job updates.\nCheck Notifications tab for updates.';
        _selectedFilePath = null;
        _selectedFileName = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Upload Audio Conversation',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (widget.webSocketService.lastPatientIdFromNotification != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ready to upload!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Audio will be uploaded to:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Patient ID: ${widget.webSocketService.lastPatientIdFromNotification}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(from notification)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    widget.webSocketService.lastPatientIdFromNotification != null
                        ? 'Or select a different patient (optional)'
                        : 'Select Patient',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.webSocketService.lastPatientIdFromNotification != null
                          ? Colors.grey.shade600
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_patients == null || _patients!.isEmpty)
                    Text(
                      widget.webSocketService.lastPatientIdFromNotification != null
                          ? 'No patients in database. Using notification patient ID.'
                          : 'No patients available. Create one first.',
                      style: TextStyle(
                        color: widget.webSocketService.lastPatientIdFromNotification != null
                            ? Colors.green.shade700
                            : Colors.black,
                      ),
                    )
                  else
                    DropdownButtonFormField<Patient>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      value: _selectedPatient,
                      hint: const Text('Select a patient'),
                      items: _patients!.map((patient) {
                        final isFromNotification =
                            widget.webSocketService.lastPatientIdFromNotification == patient.id;
                        return DropdownMenuItem(
                          value: patient,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFromNotification)
                                const Icon(
                                  Icons.notification_important,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              if (isFromNotification)
                                const SizedBox(width: 8),
                              Text(
                                patient.fullName,
                                style: TextStyle(
                                  fontWeight: isFromNotification
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isFromNotification
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Patient? value) {
                        setState(() {
                          _selectedPatient = value;
                        });
                      },
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Audio Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _audioType = 'medical';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _audioType == 'medical'
                                    ? Colors.blue
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.medical_services,
                                    color: _audioType == 'medical'
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Medical',
                                    style: TextStyle(
                                      color: _audioType == 'medical'
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: _audioType == 'medical'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _audioType = 'reception';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _audioType == 'reception'
                                    ? Colors.blue
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_in_talk,
                                    color: _audioType == 'reception'
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reception',
                                    style: TextStyle(
                                      color: _audioType == 'reception'
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: _audioType == 'reception'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Record Audio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        if (_isRecording)
                          Column(
                            children: [
                              const Icon(
                                Icons.mic,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Recording: ${_formatDuration(_recordingSeconds)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _stopRecording,
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop Recording'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              const Icon(
                                Icons.mic_none,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : _startRecording,
                                icon: const Icon(Icons.fiber_manual_record),
                                label: const Text('Start Recording'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (_selectedFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ready: $_selectedFileName',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_isUploading)
                    Column(
                      children: [
                        LinearProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: (_isUploading ||
                            _isRecording ||
                            (_selectedPatient == null &&
                             widget.webSocketService.lastPatientIdFromNotification == null) ||
                            _selectedFilePath == null)
                        ? null
                        : _uploadFile,
                    icon: const Icon(Icons.upload),
                    label: Text(
                      widget.webSocketService.lastPatientIdFromNotification != null
                          ? 'Upload to Notification Patient'
                          : 'Upload to Server',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

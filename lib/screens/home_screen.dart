import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../services/upload_service.dart';
import '../services/websocket_service.dart';
import 'patients_tab.dart';
import 'create_patient_tab.dart';
import 'upload_tab.dart';
import 'notifications_tab.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  late final PatientService _patientService;
  late final UploadService _uploadService;
  late final WebSocketService _webSocketService;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _patientService = PatientService(_authService);
    _uploadService = UploadService(_authService);
    _webSocketService = WebSocketService(_authService);
    _loadUserInfo();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final email = await _authService.getUserEmail();
    setState(() {
      _userEmail = email;
    });
  }

  Future<void> _connectWebSocket() async {
    try {
      await _webSocketService.connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WebSocket connected'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WebSocket connection failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MAIA Test App'),
              if (_userEmail != null)
                Text(
                  _userEmail!,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _connectWebSocket,
              tooltip: 'Reconnect WebSocket',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Patients'),
              Tab(icon: Icon(Icons.person_add), text: 'Create'),
              Tab(icon: Icon(Icons.upload_file), text: 'Upload'),
              Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PatientsTab(patientService: _patientService),
            CreatePatientTab(patientService: _patientService),
            UploadTab(
              uploadService: _uploadService,
              patientService: _patientService,
              webSocketService: _webSocketService,
            ),
            NotificationsTab(webSocketService: _webSocketService),
          ],
        ),
      ),
    );
  }
}

import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'auth_service.dart';

class WebSocketService {
  final String wsUrl = 'ws://maia.clinic/ws';
  final AuthService authService;

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;
  String _lastError = '';
  String _connectionStatus = 'Disconnected';
  String? _lastPatientIdFromNotification;

  WebSocketService(this.authService);

  String? get lastPatientIdFromNotification => _lastPatientIdFromNotification;

  Stream<Map<String, dynamic>>? get messages => _messageController?.stream;
  bool get isConnected => _isConnected;
  String get lastError => _lastError;
  String get connectionStatus => _connectionStatus;

  Future<void> connect() async {
    if (_isConnected) {
      developer.log('Already connected to WebSocket', name: 'WebSocketService');
      return;
    }

    _connectionStatus = 'Connecting...';
    developer.log('Starting WebSocket connection to $wsUrl', name: 'WebSocketService');

    final token = await authService.getAccessToken();
    if (token == null) {
      _connectionStatus = 'Error: No token';
      _lastError = 'No authentication token available';
      developer.log('No authentication token available', name: 'WebSocketService', error: _lastError);
      throw Exception(_lastError);
    }

    // Get user email to use as channel
    final userEmail = await authService.getUserEmail();
    if (userEmail == null) {
      _connectionStatus = 'Error: No email';
      _lastError = 'No user email available';
      developer.log('No user email available', name: 'WebSocketService', error: _lastError);
      throw Exception(_lastError);
    }

    developer.log('Token obtained, connecting with email: $userEmail', name: 'WebSocketService');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _messageController = StreamController<Map<String, dynamic>>.broadcast();

      _connectionStatus = 'Connected, subscribing...';
      developer.log('WebSocket connected, sending subscribe message', name: 'WebSocketService');

      // Subscribe to the user email channel
      final subscribeMsg = jsonEncode({
        'action': 'subscribe',
        'channel': userEmail,
        'token': token,
      });

      developer.log('Sending subscribe: $subscribeMsg', name: 'WebSocketService');
      print('🔌 WebSocket: Sending subscribe message: $subscribeMsg');
      _channel!.sink.add(subscribeMsg);

      // Listen to messages
      _channel!.stream.listen(
        (message) {
          developer.log('Received message: $message', name: 'WebSocketService');
          print('🔵 RAW WebSocket message: $message');
          try {
            final data = jsonDecode(message);
            print('🔵 Decoded message keys: ${data.keys.toList()}');
            print('🔵 Full decoded message: $data');

            // Check if there's a 'data' field that needs to be parsed as JSON
            Map<String, dynamic>? innerData;
            if (data['data'] != null && data['data'] is String) {
              try {
                innerData = jsonDecode(data['data']) as Map<String, dynamic>;
                print('🔵 Inner data parsed: $innerData');
              } catch (e) {
                print('⚠️ Could not parse inner data: $e');
              }
            }

            // Look for patientId in both the outer data and inner data
            String? patientId = data['patientId'] ?? innerData?['patientId'];

            // Save patientId if present and not empty
            if (patientId != null && patientId.isNotEmpty) {
              _lastPatientIdFromNotification = patientId;
              developer.log('Saved patientId from notification: $_lastPatientIdFromNotification', name: 'WebSocketService');
              print('📱 ✅ Notification patientId saved: $_lastPatientIdFromNotification');
            } else {
              print('⚠️ No valid patientId found. Outer: ${data['patientId']}, Inner: ${innerData?['patientId']}');
            }

            // Add the parsed inner data to the message if it exists
            if (innerData != null) {
              data['parsedData'] = innerData;
            }

            _messageController!.add(data);
            _connectionStatus = 'Connected & Subscribed';
          } catch (e) {
            _lastError = 'Error parsing message: $e';
            developer.log(_lastError, name: 'WebSocketService', error: e);
            print('❌ Error parsing message: $e');
          }
        },
        onError: (error) {
          _lastError = 'WebSocket error: $error';
          _connectionStatus = 'Error';
          _isConnected = false;
          developer.log(_lastError, name: 'WebSocketService', error: error);
        },
        onDone: () {
          _connectionStatus = 'Disconnected';
          _isConnected = false;
          developer.log('WebSocket connection closed', name: 'WebSocketService');
        },
      );

      _isConnected = true;
      _connectionStatus = 'Connected to $userEmail';
      developer.log('WebSocket fully connected and listening to $userEmail', name: 'WebSocketService');
    } catch (e) {
      _lastError = 'Failed to connect: $e';
      _connectionStatus = 'Connection failed';
      _isConnected = false;
      developer.log(_lastError, name: 'WebSocketService', error: e);
      rethrow;
    }
  }

  /// Subscribe to a new channel dynamically
  void subscribeToChannel(String channel) {
    if (!_isConnected || _channel == null) {
      developer.log('Cannot subscribe: WebSocket not connected', name: 'WebSocketService');
      return;
    }

    final subscribeMsg = jsonEncode({
      'action': 'subscribe',
      'channel': channel,
    });

    developer.log('Subscribing to new channel: $channel', name: 'WebSocketService');
    print('🔌 WebSocket: Subscribing to channel: $channel');
    _channel!.sink.add(subscribeMsg);
  }

  void disconnect() {
    _channel?.sink.close();
    _messageController?.close();
    _isConnected = false;
  }
}

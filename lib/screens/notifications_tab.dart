import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../services/websocket_service.dart';

class NotificationsTab extends StatefulWidget {
  final WebSocketService webSocketService;

  const NotificationsTab({super.key, required this.webSocketService});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final List<Map<String, dynamic>> _notifications = [];
  StreamSubscription? _subscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _listenToWebSocket();
    // Refresh UI every second to show connection status updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _listenToWebSocket() {
    _subscription = widget.webSocketService.messages?.listen((message) {
      // Only process actual notifications, not subscription confirmations
      if (message['action'] != 'notification') {
        developer.log('Ignoring non-notification message: ${message['action']}', name: 'NotificationsTab');
        return;
      }

      setState(() {
        _notifications.insert(0, {
          'message': message,
          'timestamp': DateTime.now(),
        });
      });

      // Get notification type from parsedData or message
      final parsedData = message['parsedData'] as Map<String, dynamic>?;
      final notificationType = parsedData?['status'] ?? message['type'] ?? 'Unknown';

      // Show snackbar for new notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New notification: $notificationType'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _clearNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.webSocketService.isConnected;
    final connectionStatus = widget.webSocketService.connectionStatus;
    final lastError = widget.webSocketService.lastError;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isConnected ? Colors.green.shade100 : Colors.orange.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.sync,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WebSocket Status',
                            style: TextStyle(
                              color: isConnected ? Colors.green.shade900 : Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            connectionStatus,
                            style: TextStyle(
                              color: isConnected ? Colors.green.shade700 : Colors.orange.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _clearNotifications,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                if (lastError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lastError,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload an audio file to receive notifications',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final message = notification['message'] as Map<String, dynamic>;
                      final timestamp = notification['timestamp'] as DateTime;

                      // Get patientId from parsedData if available
                      final parsedData = message['parsedData'] as Map<String, dynamic>?;
                      final patientId = message['patientId'] ?? parsedData?['patientId'];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ExpansionTile(
                          leading: const Icon(Icons.notification_important),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message['type'] ?? 'Unknown Type',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (patientId != null && patientId.toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Patient ID',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatTimestamp(timestamp)),
                              if (patientId != null && patientId.toString().isNotEmpty)
                                Text(
                                  'Patient: $patientId',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Message Details:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ...message.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              '${entry.key}:',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              entry.value.toString(),
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

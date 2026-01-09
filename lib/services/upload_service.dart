import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';

class UploadService {
  final String baseUrl = 'http://maia.clinic/api';
  final AuthService authService;
  final Dio _dio = Dio();

  UploadService(this.authService);

  Future<String> uploadConversation({
    required String patientId,
    required String audioFilePath,
    required String type, // 'medical' or 'reception'
    Function(double)? onProgress,
  }) async {
    final token = await authService.getAccessToken();

    FormData formData = FormData.fromMap({
      'patientId': patientId,
      'type': type,
      'file': await MultipartFile.fromFile(
        audioFilePath,
        filename: audioFilePath.split('/').last,
        contentType: MediaType('audio', 'mpeg'),
      ),
    });

    final response = await _dio.post(
      '$baseUrl/patients/upload-conversation',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
      onSendProgress: (sent, total) {
        if (onProgress != null) {
          onProgress(sent / total);
        }
      },
    );

    return response.data['jobId'];
  }
}

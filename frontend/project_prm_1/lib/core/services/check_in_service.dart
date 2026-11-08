import 'dart:convert';

import '../../models/check_in_result.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class CheckInService {
  static final RegExp _uuidRegex = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  /// Extract ticket UUID from QR string, JSON, or URL
  static String? extractTicketId(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return null;

    // Check if it's a JSON payload
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final ticketId = decoded['ticket_id'] ?? decoded['ticketId'] ?? decoded['id'];
          if (ticketId != null) {
            final match = _uuidRegex.firstMatch(ticketId.toString());
            if (match != null) return match.group(0);
            return ticketId.toString().trim();
          }
        }
      } catch (_) {
        // Fallback to regex extraction
      }
    }

    // Try finding a UUID pattern in text or URL
    final match = _uuidRegex.firstMatch(trimmed);
    if (match != null) {
      return match.group(0);
    }

    return trimmed;
  }

  /// Check if a string is a valid UUID
  static bool isValidUuid(String text) {
    return _uuidRegex.hasMatch(text);
  }

  /// Perform ticket check-in with the backend API
  static Future<CheckInResult> checkIn(String rawCode) async {
    final ticketId = extractTicketId(rawCode);

    if (ticketId == null || ticketId.isEmpty) {
      return CheckInResult.failure(
        message: 'Mã QR trống hoặc không đọc được.',
        rawScannedCode: rawCode,
      );
    }

    if (!isValidUuid(ticketId)) {
      return CheckInResult.failure(
        message: 'Mã không đúng định dạng vé (UUID). Vui lòng kiểm tra lại.',
        ticketId: ticketId,
        rawScannedCode: rawCode,
      );
    }

    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return CheckInResult.failure(
        message: 'Chưa đăng nhập hoặc phiên đã hết hạn. Vui lòng đăng nhập lại.',
        ticketId: ticketId,
        rawScannedCode: rawCode,
      );
    }

    try {
      final response = await ApiService.post(
        ApiConfig.staffCheckIn,
        body: {'ticket_id': ticketId},
        token: token,
      );

      return CheckInResult.fromJson(
        response,
        rawScannedCode: rawCode,
      );
    } catch (e) {
      final rawError = e.toString().replaceFirst('Exception: ', '').trim();
      final vietnameseMessage = _mapErrorMessage(rawError);

      return CheckInResult.failure(
        message: vietnameseMessage,
        ticketId: ticketId,
        rawScannedCode: rawCode,
      );
    }
  }

  static String _mapErrorMessage(String error) {
    final lower = error.toLowerCase();

    if (lower.contains('already been checked in') ||
        lower.contains('status: used')) {
      return 'Vé này đã được điểm danh trước đó.';
    }
    if (lower.contains('ticket not found')) {
      return 'Không tìm thấy vé trong hệ thống.';
    }
    if (lower.contains('staff permission required') ||
        lower.contains('403')) {
      return 'Chỉ tài khoản Staff hoặc Admin mới có quyền điểm danh.';
    }
    if (lower.contains('missing or invalid') ||
        lower.contains('401') ||
        lower.contains('expired token')) {
      return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.';
    }
    if (lower.contains('invalid ticket_id') ||
        lower.contains('ticket_id is required')) {
      return 'Mã vé không hợp lệ hoặc bị thiếu.';
    }
    if (lower.contains('connection refused') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable')) {
      return 'Không thể kết nối đến máy chủ API. Vui lòng kiểm tra mạng.';
    }

    return error;
  }
}

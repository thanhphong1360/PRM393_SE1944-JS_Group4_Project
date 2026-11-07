import '../../models/ticket.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class TicketService {
  /// Fetch list of registered tickets for current attendee
  static Future<List<Ticket>> getMyRegistrations() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }

    final response = await ApiService.get(
      ApiConfig.myRegistrations,
      token: token,
    );

    final List<dynamic> list = response['registrations'] ?? [];
    return list.map((item) => Ticket.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  /// Default demo tickets for testing without backend
  static List<Ticket> getMockTickets() {
    return [
      Ticket(
        registrationId: 1,
        ticketId: 'd3b07384-d113-46fb-a79b-2221b6329e47',
        conferenceId: 1,
        conferenceTitle: 'Hội nghị Công nghệ AI & Cloud 2026',
        conferenceLocation: 'Trung tâm Hội nghị Quốc gia, Hà Nội',
        conferenceStartDate: DateTime.parse('2026-11-20'),
        registeredAt: DateTime.parse('2026-11-01 09:00:00'),
        status: 'Valid',
      ),
      Ticket(
        registrationId: 2,
        ticketId: 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
        conferenceId: 2,
        conferenceTitle: 'Diễn đàn Lập trình Di động Flutter & Mobile Summit',
        conferenceLocation: 'Hội trường Trống Đồng, TP. Hồ Chí Minh',
        conferenceStartDate: DateTime.parse('2026-12-05'),
        registeredAt: DateTime.parse('2026-11-02 10:15:00'),
        status: 'Valid',
      ),
      Ticket(
        registrationId: 3,
        ticketId: 'e4f5a6b7-c8d9-4e0f-1a2b-3c4d5e6f7a8b',
        conferenceId: 1,
        conferenceTitle: 'Hội nghị Công nghệ AI & Cloud 2026',
        conferenceLocation: 'Trung tâm Hội nghị Quốc gia, Hà Nội',
        conferenceStartDate: DateTime.parse('2026-11-20'),
        registeredAt: DateTime.parse('2026-11-03 14:00:00'),
        status: 'Used',
        checkedInAt: DateTime.parse('2026-11-05 08:30:00'),
      ),
      Ticket(
        registrationId: 4,
        ticketId: 'f9e8d7c6-b5a4-4321-fedc-ba9876543210',
        conferenceId: 3,
        conferenceTitle: 'Hội thảo An toàn Thông tin & Cybersecurity 2026',
        conferenceLocation: 'Đại học FPT, Hà Nội',
        conferenceStartDate: DateTime.parse('2026-12-18'),
        registeredAt: DateTime.parse('2026-11-04 16:45:00'),
        status: 'Cancelled',
      ),
    ];
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:project_prm_1/core/services/check_in_service.dart';
import 'package:project_prm_1/models/check_in_result.dart';

void main() {
  group('CheckInService - Ticket ID parsing & validation', () {
    const validUuid = 'c8b21c43-b9dc-4e8c-8f4b-76b92f7685dc';

    test('extracts raw UUID correctly', () {
      final result = CheckInService.extractTicketId(validUuid);
      expect(result, validUuid);
      expect(CheckInService.isValidUuid(result!), isTrue);
    });

    test('extracts UUID from JSON payload', () {
      final jsonPayload = '{"ticket_id": "$validUuid", "event": "PRM393"}';
      final result = CheckInService.extractTicketId(jsonPayload);
      expect(result, validUuid);
    });

    test('extracts UUID from URL query or path', () {
      final url = 'https://conference.example.com/check-in?ticket=$validUuid';
      final result = CheckInService.extractTicketId(url);
      expect(result, validUuid);
    });

    test('validates UUID correctly', () {
      expect(CheckInService.isValidUuid(validUuid), isTrue);
      expect(CheckInService.isValidUuid('invalid-uuid-string'), isFalse);
      expect(CheckInService.isValidUuid(''), isFalse);
    });
  });

  group('CheckInResult model tests', () {
    test('parses successful check-in JSON correctly', () {
      final json = {
        'success': true,
        'message': 'Check-in successful',
        'ticket': {
          'ticket_id': 'c8b21c43-b9dc-4e8c-8f4b-76b92f7685dc',
          'status': 'Used',
          'registered_at': '2026-11-01T10:00:00',
          'checked_in_at': '2026-11-05T08:30:00',
        },
        'attendee': {
          'user_id': 101,
          'full_name': 'Nguyen Van A',
          'email': 'vana@example.com',
        },
        'conference': {
          'conference_id': 5,
          'title': 'Flutter & Cloud Summit 2026',
          'location': 'Hall A, FPT University',
          'start_date': '2026-11-20',
        },
      };

      final result = CheckInResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.message, 'Check-in successful');
      expect(result.ticketId, 'c8b21c43-b9dc-4e8c-8f4b-76b92f7685dc');
      expect(result.ticketStatus, 'Used');
      expect(result.attendeeFullName, 'Nguyen Van A');
      expect(result.attendeeEmail, 'vana@example.com');
      expect(result.conferenceTitle, 'Flutter & Cloud Summit 2026');
      expect(result.isAlreadyCheckedIn, isFalse);
    });

    test('parses already checked-in failure correctly', () {
      final failure = CheckInResult.failure(
        message: 'Vé này đã được điểm danh trước đó.',
        ticketId: 'c8b21c43-b9dc-4e8c-8f4b-76b92f7685dc',
      );

      expect(failure.success, isFalse);
      expect(failure.isAlreadyCheckedIn, isTrue);
    });
  });
}

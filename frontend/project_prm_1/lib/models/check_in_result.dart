class CheckInResult {
  final bool success;
  final String message;
  final String? ticketId;
  final String? ticketStatus;
  final DateTime? registeredAt;
  final DateTime? checkedInAt;
  final int? attendeeId;
  final String? attendeeFullName;
  final String? attendeeEmail;
  final int? conferenceId;
  final String? conferenceTitle;
  final String? conferenceLocation;
  final String? conferenceStartDate;
  final DateTime scannedAt;
  final String? rawScannedCode;

  CheckInResult({
    required this.success,
    required this.message,
    this.ticketId,
    this.ticketStatus,
    this.registeredAt,
    this.checkedInAt,
    this.attendeeId,
    this.attendeeFullName,
    this.attendeeEmail,
    this.conferenceId,
    this.conferenceTitle,
    this.conferenceLocation,
    this.conferenceStartDate,
    DateTime? scannedAt,
    this.rawScannedCode,
  }) : scannedAt = scannedAt ?? DateTime.now();

  factory CheckInResult.fromJson(
    Map<String, dynamic> json, {
    String? rawScannedCode,
  }) {
    final ticket = json['ticket'] as Map<String, dynamic>?;
    final attendee = json['attendee'] as Map<String, dynamic>?;
    final conference = json['conference'] as Map<String, dynamic>?;

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return CheckInResult(
      success: json['success'] == true,
      message: json['message'] as String? ?? 'Điểm danh thành công',
      ticketId: ticket?['ticket_id'] as String?,
      ticketStatus: ticket?['status'] as String?,
      registeredAt: parseDateTime(ticket?['registered_at']),
      checkedInAt: parseDateTime(ticket?['checked_in_at']),
      attendeeId: attendee?['user_id'] is int
          ? attendee!['user_id'] as int
          : int.tryParse(attendee?['user_id']?.toString() ?? ''),
      attendeeFullName: attendee?['full_name'] as String?,
      attendeeEmail: attendee?['email'] as String?,
      conferenceId: conference?['conference_id'] is int
          ? conference!['conference_id'] as int
          : int.tryParse(conference?['conference_id']?.toString() ?? ''),
      conferenceTitle: conference?['title'] as String?,
      conferenceLocation: conference?['location'] as String?,
      conferenceStartDate: conference?['start_date']?.toString(),
      rawScannedCode: rawScannedCode,
    );
  }

  factory CheckInResult.failure({
    required String message,
    String? rawScannedCode,
    String? ticketId,
  }) {
    return CheckInResult(
      success: false,
      message: message,
      ticketId: ticketId,
      rawScannedCode: rawScannedCode,
    );
  }

  bool get isAlreadyCheckedIn {
    return !success &&
        (message.toLowerCase().contains('used') ||
            message.toLowerCase().contains('already') ||
            message.toLowerCase().contains('đã'));
  }
}

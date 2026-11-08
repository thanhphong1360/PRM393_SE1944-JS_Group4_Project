
class Ticket {
  final int registrationId;
  final String ticketId;
  final int conferenceId;
  final String conferenceTitle;
  final String location;
  final DateTime startDate;
  final DateTime registeredAt;
  final String status;
  final DateTime? checkedInAt;
  final String? description;

  Ticket({
    required this.registrationId,
    required this.ticketId,
    required this.conferenceId,
    required this.conferenceTitle,
    required this.location,
    required this.startDate,
    required this.registeredAt,
    required this.status,
    this.checkedInAt,
    this.description,
  });

  // SQL Server may return seven fractional-second digits.
  // Dart DateTime.parse supports up to six, so truncate the extra digit.
  static DateTime _parseDateTime(String value) {
    final normalized = value.replaceFirst(' ', 'T');
    final safeValue = normalized.replaceFirstMapped(
      RegExp(r'(\.\d{6})\d+'),
          (match) => match[1]!,
    );

    return DateTime.parse(safeValue);
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      registrationId: json['registration_id'] as int,
      ticketId: json['ticket_id'] as String,
      conferenceId: json['conference_id'] as int,
      conferenceTitle: json['conference_title'] as String,
      location: json['location'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      registeredAt: _parseDateTime(json['registered_at'] as String),
      status: json['status'] as String,
      checkedInAt: json['checked_in_at'] == null
          ? null
          : _parseDateTime(json['checked_in_at'] as String),
      description: json['description'] as String?,
    );
  }
}


class AdminTicket {
  final int registrationId;
  final String ticketId;
  final int conferenceId;
  final int attendeeId;
  final DateTime registeredAt;
  final String status;

  AdminTicket({
    required this.registrationId,
    required this.ticketId,
    required this.conferenceId,
    required this.attendeeId,
    required this.registeredAt,
    required this.status,
  });

  factory AdminTicket.fromJson(Map<String, dynamic> json) {
    return AdminTicket(
      registrationId: json['registration_id'] as int,
      ticketId: json['ticket_id'] as String,
      conferenceId: json['conference_id'] as int,
      attendeeId: json['user_id'] as int,
      registeredAt: DateTime.parse(
        (json['registered_at'] as String).replaceFirst(' ', 'T'),
      ),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registration_id': registrationId,
      'ticket_id': ticketId,
      'conference_id': conferenceId,
      'user_id': attendeeId,
      'registered_at': registeredAt.toIso8601String(),
      'status': status,
    };
  }
}

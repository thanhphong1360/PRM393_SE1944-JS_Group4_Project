class Ticket {
  final int registrationId;
  final String ticketId;
  final int conferenceId;
  final String conferenceTitle;
  final String conferenceLocation;
  final DateTime conferenceStartDate;
  final DateTime registeredAt;
  final String status;
  final DateTime? checkedInAt;

  Ticket({
    required this.registrationId,
    required this.ticketId,
    required this.conferenceId,
    required this.conferenceTitle,
    required this.conferenceLocation,
    required this.conferenceStartDate,
    required this.registeredAt,
    required this.status,
    this.checkedInAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      registrationId: json['registration_id'],
      ticketId: json['ticket_id'],
      conferenceId: json['conference_id'],
      conferenceTitle: json['conference_title'],
      conferenceLocation: json['conference_location'],
      conferenceStartDate: DateTime.parse(json['start_date']),
      registeredAt: DateTime.parse(json['registered_at']),
      status: json['status'],
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'])
          : null,
    );
  }
}

class Conference {
  final int conferenceId;
  final String title;
  final String location;
  final DateTime startDate;
  final String? description;
  final String status;
  final String? registrationPolicy;

  Conference({
    required this.conferenceId,
    required this.title,
    required this.location,
    required this.startDate,
    this.description,
    required this.status,
    this.registrationPolicy,
  });

  factory Conference.fromJson(Map<String, dynamic> json) {
    return Conference(
      conferenceId: json['conference_id'] as int,
      title: json['title'] as String,
      location: json['location'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      description: json['description'] as String?,
      status: json['status'] as String,
      registrationPolicy: json['registration_policy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conference_id': conferenceId,
      'title': title,
      'location': location,
      'start_date': startDate.toIso8601String().split('T').first,
      'description': description,
      'status': status,
      'registration_policy': registrationPolicy,
    };
  }
}

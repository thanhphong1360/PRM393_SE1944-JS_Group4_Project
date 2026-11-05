class Conference {
  final int conferenceId;
  final String title;
  final String location;
  final DateTime startDate;
  final String? description;
  final String status;
  final String registrationPolicy;

  Conference({
    required this.conferenceId,
    required this.title,
    required this.location,
    required this.startDate,
    this.description,
    required this.status,
    required this.registrationPolicy,
  });

  factory Conference.fromJson(Map<String, dynamic> json) {
    return Conference(
      conferenceId: json['conference_id'],
      title: json['title'],
      location: json['location'],
      startDate: DateTime.parse(json['start_date']),
      description: json['description'],
      status: json['status'],
      registrationPolicy: json['registration_policy'],
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
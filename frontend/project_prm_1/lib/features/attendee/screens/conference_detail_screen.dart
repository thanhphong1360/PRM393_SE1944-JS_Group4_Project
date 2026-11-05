
import 'package:flutter/material.dart';

import '../../../core/services/conference_service.dart';
import '../../../models/conference.dart';
import '../../../core/services/registration_service.dart';

class ConferenceDetailScreen extends StatefulWidget {
  final Conference conference;

  const ConferenceDetailScreen({
    super.key,
    required this.conference,
  });

  @override
  State<ConferenceDetailScreen> createState() =>
      _ConferenceDetailScreenState();
}

class _ConferenceDetailScreenState
    extends State<ConferenceDetailScreen> {
  late Future<Conference> _conferenceFuture;

  bool _isRegistering = false;


  Future<void> _registerConference(int conferenceId) async {
    setState(() {
      _isRegistering = true;
    });

    try {
      final response =
      await RegistrationService.registerConference(
        conferenceId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Registration successful!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }


  @override
  void initState() {
    super.initState();

    _conferenceFuture =
        ConferenceService.getConferenceDetail(
          widget.conference.conferenceId,
        );
  }
  bool _canRegister(Conference conference) {
    return conference.status == 'Upcoming' &&
        conference.registrationPolicy == 'Open';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conference Details'),
      ),
      body: FutureBuilder<Conference>(
        future: _conferenceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Conference not found.'),
            );
          }

          final conference = snapshot.data!;

          return _buildConferenceDetails(conference);
        },
      ),
    );
  }

  Widget _buildConferenceDetails(Conference conference) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conference.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          _buildInfoRow(
            Icons.location_on,
            'Location',
            conference.location,
          ),

          const SizedBox(height: 16),

          _buildInfoRow(
            Icons.calendar_today,
            'Start date',
            conference.startDate.toString().split(' ').first,
          ),

          const SizedBox(height: 16),

          _buildInfoRow(
            Icons.info_outline,
            'Status',
            conference.status,
          ),

          const SizedBox(height: 24),

          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            conference.description?.isNotEmpty == true
                ? conference.description!
                : 'No description available.',
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 24),

          _buildInfoRow(
            Icons.confirmation_number,
            'Registration policy',
            conference.registrationPolicy ??
                'Not specified',
          ),
          const SizedBox(height: 32),

          if (_canRegister(conference))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRegistering
                    ? null
                    : () {
                  _registerConference(conference.conferenceId);
                },
                icon: _isRegistering
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.app_registration),
                label: Text(
                  _isRegistering ? 'Registering...' : 'Register Conference',
                ),

              ),

            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                conference.status != 'Upcoming'
                    ? 'This conference is not available for registration.'
                    : conference.registrationPolicy == 'ApprovalRequired'
                    ? 'Registration requires approval.'
                    : conference.registrationPolicy == 'InvitationOnly'
                    ? 'This conference is invitation-only.'
                    : 'Registration is currently unavailable.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}

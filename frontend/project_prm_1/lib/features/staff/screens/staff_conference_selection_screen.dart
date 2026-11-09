
import 'package:flutter/material.dart';

import '../../../models/conference.dart';
import '../../../core/services/conference_service.dart';

class StaffConferenceSelectionScreen extends StatefulWidget {
  const StaffConferenceSelectionScreen({super.key});

  @override
  State<StaffConferenceSelectionScreen> createState() =>
      _StaffConferenceSelectionScreenState();
}

class _StaffConferenceSelectionScreenState
    extends State<StaffConferenceSelectionScreen> {
  late Future<List<Conference>> _conferencesFuture;

  @override
  void initState() {
    super.initState();
    _loadConferences();
  }

  void _loadConferences() {
    _conferencesFuture = ConferenceService.getConferences();
  }

  Future<void> _refreshConferences() async {
    setState(() {
      _loadConferences();
    });

    await _conferencesFuture;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.green;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildConferenceCard(Conference conference) {
    final isCancelled =
        conference.status.toLowerCase() == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCancelled
            ? null
            : () {
          Navigator.pop(context, conference);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      conference.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(conference.status)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      conference.status,
                      style: TextStyle(
                        color: _getStatusColor(conference.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(conference.location),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(_formatDate(conference.startDate)),
                ],
              ),
              if (isCancelled) ...[
                const SizedBox(height: 12),
                const Text(
                  'This conference is cancelled.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select conference',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Conference>>(
      future: _conferencesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load conferences.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(_loadConferences);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final conferences = snapshot.data ?? [];

        if (conferences.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshConferences,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Icon(
                  Icons.event_busy,
                  size: 56,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Center(
                  child: Text('No conferences available.'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshConferences,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: conferences.length,
            itemBuilder: (context, index) {
              return _buildConferenceCard(conferences[index]);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Conference'),
      ),
      body: _buildBody(),
    );
  }
}


import 'package:flutter/material.dart';

import '../../../core/services/conference_service.dart';
import '../../../models/conference.dart';
import 'create_conference_screen.dart';
import 'edit_conference_screen.dart';

class AdminConferenceListScreen extends StatefulWidget {
  const AdminConferenceListScreen({super.key});

  @override
  State<AdminConferenceListScreen> createState() =>
      _AdminConferenceListScreenState();
}

class _AdminConferenceListScreenState
    extends State<AdminConferenceListScreen> {
  late Future<List<Conference>> _conferencesFuture;

  @override
  void initState() {
    super.initState();
    _loadConferences();
  }

  void _loadConferences() {
    _conferencesFuture =
        ConferenceService.getAdminConferences();
  }

  Future<void> _openCreateConference() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const CreateConferenceScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(_loadConferences);
    }
  }

  Future<void> _openEditConference(
      Conference conference,
      ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditConferenceScreen(
          conference: conference,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(_loadConferences);
    }
  }

  Future<void> _cancelConference(
      Conference conference,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Conference'),
          content: Text(
            'Are you sure you want to cancel '
                '"${conference.title}"?\n\n'
                'This conference will remain in the database '
                'with status Cancelled.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final response =
      await ConferenceService.cancelConference(
        conference.conferenceId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ??
                'Conference cancelled successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(_loadConferences);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel conference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getPolicyColor(String policy) {
    switch (policy) {
      case 'Open':
        return Colors.green;
      case 'ApprovalRequired':
        return Colors.orange;
      case 'InvitationOnly':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildConferenceCard(Conference conference) {
    final isCancelled = conference.status == 'Cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conference.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(conference.location),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  conference.startDate
                      .toString()
                      .split(' ')
                      .first,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLabel(
                  conference.status,
                  _getStatusColor(conference.status),
                ),
                if (conference.registrationPolicy != null)
                  _buildLabel(
                    conference.registrationPolicy!,
                    _getPolicyColor(
                      conference.registrationPolicy!,
                    ),
                  ),
              ],
            ),

            if (!isCancelled) ...[
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openEditConference(conference),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _cancelConference(conference),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conference Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateConference,
        tooltip: 'Create Conference',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Conference>>(
        future: _conferencesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
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
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(_loadConferences);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final conferences = snapshot.data ?? [];

          if (conferences.isEmpty) {
            return const Center(
              child: Text('No conferences found.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadConferences);
              await _conferencesFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conferences.length,
              itemBuilder: (context, index) {
                return _buildConferenceCard(
                  conferences[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

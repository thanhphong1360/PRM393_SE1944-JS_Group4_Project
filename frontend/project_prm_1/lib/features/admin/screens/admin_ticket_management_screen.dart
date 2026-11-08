
import 'package:flutter/material.dart';

import '../../../core/services/conference_service.dart';
import '../../../core/services/attendee_service.dart';
import '../../../core/services/admin_ticket_service.dart';
import '../../../models/conference.dart';
import '../../../models/attendee.dart';
import '../../../models/admin_ticket.dart';

class AdminTicketManagementScreen extends StatefulWidget {
  const AdminTicketManagementScreen({super.key});

  @override
  State<AdminTicketManagementScreen> createState() =>
      _AdminTicketManagementScreenState();
}

class _AdminTicketManagementScreenState
    extends State<AdminTicketManagementScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<Conference> _conferences = [];
  List<Attendee> _attendees = [];

  Conference? _selectedConference;
  Attendee? _selectedAttendee;

  bool _isLoadingConferences = true;
  bool _isLoadingAttendees = false;
  bool _isIssuingTicket = false;

  String? _conferenceError;
  String? _attendeeError;

  @override
  void initState() {
    super.initState();
    _loadConferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConferences() async {
    setState(() {
      _isLoadingConferences = true;
      _conferenceError = null;
    });

    try {
      final conferences =
      await ConferenceService.getAdminConferences();

      if (!mounted) return;

      setState(() {
        _conferences = conferences;
        _isLoadingConferences = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _conferenceError = e.toString();
        _isLoadingConferences = false;
      });
    }
  }

  List<Conference> get _eligibleConferences {
    return _conferences.where((conference) {
      return conference.status == 'Upcoming' &&
          conference.registrationPolicy == 'InvitationOnly';
    }).toList();
  }

  Future<void> _loadAttendees({String? search}) async {
    setState(() {
      _isLoadingAttendees = true;
      _attendeeError = null;
      _selectedAttendee = null;
    });

    try {
      final attendees = await AttendeeService.getAttendees(
        search: search,
      );

      if (!mounted) return;

      setState(() {
        _attendees = attendees;
        _isLoadingAttendees = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _attendeeError = e.toString();
        _isLoadingAttendees = false;
      });
    }
  }

  Future<void> _issueTicket() async {
    if (_selectedConference == null ||
        _selectedAttendee == null) {
      return;
    }

    final conference = _selectedConference!;
    final attendee = _selectedAttendee!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Issue Ticket'),
          content: Text(
            'Are you sure you want to issue a ticket for '
                '${attendee.fullName} to attend '
                '${conference.title}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isIssuingTicket = true;
    });

    try {
      final response = await AdminTicketService.issueTicket(
        conferenceId: conference.conferenceId,
        attendeeId: attendee.userId,
      );

      final registrationData = response['registration'];

      if (registrationData is! Map) {
        throw Exception(
          'Invalid registration data returned by API.',
        );
      }

      final ticket = AdminTicket.fromJson(
        Map<String, dynamic>.from(registrationData),
      );

      if (!mounted) return;

      setState(() {
        _isIssuingTicket = false;
      });

      await _showTicketSuccessDialog(
        ticket: ticket,
        attendee: attendee,
        conference: conference,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isIssuingTicket = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to issue ticket: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _showTicketSuccessDialog({
    required AdminTicket ticket,
    required Attendee attendee,
    required Conference conference,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text('Ticket Issued Successfully'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ticket Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Registration ID: ${ticket.registrationId}',
                ),
                const SizedBox(height: 8),
                const Text('Ticket ID:'),
                SelectableText(ticket.ticketId),
                const SizedBox(height: 8),
                Text('Status: ${ticket.status}'),
                const Divider(height: 24),
                const Text(
                  'Attendee Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(attendee.fullName),
                Text(attendee.email),
                const Divider(height: 24),
                const Text(
                  'Conference Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(conference.title),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConferenceSelector() {
    if (_isLoadingConferences) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_conferenceError != null) {
      return Column(
        children: [
          Text(
            'Failed to load conferences: $_conferenceError',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadConferences,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_eligibleConferences.isEmpty) {
      return const Text(
        'No eligible conferences found. '
            'Only Upcoming conferences with InvitationOnly '
            'policy can receive Admin-issued tickets.',
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedConference?.conferenceId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Select Conference',
        border: OutlineInputBorder(),
      ),
      items: _eligibleConferences.map((conference) {
        return DropdownMenuItem<int>(
          value: conference.conferenceId,
          child: Text(
            conference.title,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (conferenceId) {
        if (conferenceId == null) return;

        setState(() {
          _selectedConference =
              _eligibleConferences.firstWhere(
                    (conference) =>
                conference.conferenceId == conferenceId,
              );

          _selectedAttendee = null;
          _attendees = [];
          _searchController.clear();
          _attendeeError = null;
        });
      },
    );
  }

  Widget _buildAttendeeSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: () {
                _searchController.clear();
                _loadAttendees();
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
            ),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _loadAttendees(search: value);
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _loadAttendees(
                search: _searchController.text,
              );
            },
            icon: const Icon(Icons.search),
            label: const Text('Search Attendees'),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeList() {
    if (_isLoadingAttendees) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_attendeeError != null) {
      return Column(
        children: [
          Text(
            'Failed to load attendees: $_attendeeError',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              _loadAttendees(
                search: _searchController.text,
              );
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_attendees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('No attendees found.'),
        ),
      );
    }

    return Column(
      children: _attendees.map((attendee) {
        final isSelected =
            _selectedAttendee?.userId == attendee.userId;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
              Colors.blue.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
              ),
            ),
            title: Text(
              attendee.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attendee.email),
                const SizedBox(height: 4),
                Text(
                  attendee.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: attendee.isActive
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: isSelected
                ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
                : const Icon(Icons.radio_button_unchecked),
            selected: isSelected,
            onTap: attendee.isActive
                ? () {
              setState(() {
                _selectedAttendee = attendee;
              });
            }
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedAttendee() {
    if (_selectedAttendee == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.green.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  'Selected Attendee',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _selectedAttendee!.fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(_selectedAttendee!.email),
            Text('Attendee ID: ${_selectedAttendee!.userId}'),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTicketButton() {
    final canIssue = _selectedConference != null &&
        _selectedAttendee != null &&
        !_isIssuingTicket;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canIssue ? _issueTicket : null,
        icon: _isIssuingTicket
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.confirmation_number),
        label: Text(
          _isIssuingTicket ? 'Issuing Ticket...' : 'Issue Ticket',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Issue Ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a conference and an attendee '
                  'before issuing a ticket.',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Select Conference',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            _buildConferenceSelector(),
            if (_selectedConference != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedConference!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location: '
                            '${_selectedConference!.location}',
                      ),
                      Text(
                        'Date: ${_selectedConference!.startDate}'
                            .split(' ')
                            .first,
                      ),
                      Text(
                        'Policy: '
                            '${_selectedConference!.registrationPolicy}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '2. Select Attendee',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              _buildAttendeeSearch(),
              const SizedBox(height: 12),
              _buildAttendeeList(),
              const SizedBox(height: 12),
              _buildSelectedAttendee(),
              const SizedBox(height: 20),
              _buildIssueTicketButton(),
            ],
          ],
        ),
      ),
    );
  }
}

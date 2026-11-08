
import 'package:flutter/material.dart';

import '../../../core/services/registration_service.dart';
import '../../../models/ticket.dart';
import 'ticket_detail_screen.dart';

class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({super.key});

  @override
  State<MyRegistrationsScreen> createState() =>
      _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState
    extends State<MyRegistrationsScreen> {
  late Future<List<Ticket>> _registrationsFuture;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  void _loadRegistrations() {
    _registrationsFuture =
        RegistrationService.getMyRegistrations();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Valid':
        return Colors.green;
      case 'Used':
        return Colors.blue;
      case 'Revoked':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _openTicketDetail(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(
          ticketId: ticket.ticketId,
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(Ticket ticket) {
    final statusColor = _getStatusColor(ticket.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTicketDetail(ticket),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.conferenceTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ticket.location)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(ticket.startDate.toString().split(' ').first),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Ticket status: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ticket ID: ${ticket.ticketId}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View details',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Registrations'),
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _registrationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(_loadRegistrations);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final registrations = snapshot.data ?? [];

          if (registrations.isEmpty) {
            return const Center(
              child: Text('You have no registrations yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadRegistrations);
              await _registrationsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registrations.length,
              itemBuilder: (context, index) {
                return _buildRegistrationCard(
                  registrations[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

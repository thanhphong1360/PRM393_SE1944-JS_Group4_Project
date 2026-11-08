
import 'package:flutter/material.dart';

import '../../../core/services/attendee_service.dart';
import '../../../models/attendee.dart';

class AdminAttendeeListScreen extends StatefulWidget {
  const AdminAttendeeListScreen({super.key});

  @override
  State<AdminAttendeeListScreen> createState() =>
      _AdminAttendeeListScreenState();
}

class _AdminAttendeeListScreenState
    extends State<AdminAttendeeListScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<Attendee> _attendees = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttendees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendees({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final attendees = await AttendeeService.getAttendees(
        search: search,
      );

      if (!mounted) return;

      setState(() {
        _attendees = attendees;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(bool isActive) {
    return isActive ? Colors.green : Colors.red;
  }

  Widget _buildAttendeeCard(Attendee attendee) {
    final statusColor = _getStatusColor(attendee.isActive);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendee.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    attendee.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attendee.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadAttendees(
                  search: _searchController.text,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_attendees.isEmpty) {
      return const Center(
        child: Text('No attendees found.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAttendees(
        search: _searchController.text,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attendees.length,
        itemBuilder: (context, index) {
          return _buildAttendeeCard(_attendees[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendee Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                _loadAttendees(search: value);
              },
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}

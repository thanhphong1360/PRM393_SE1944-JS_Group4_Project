
import 'package:flutter/material.dart';

import '../../../core/services/conference_service.dart';
import '../../../models/conference.dart';
import 'conference_detail_screen.dart';

class ConferenceListScreen extends StatefulWidget {
  const ConferenceListScreen({super.key});

  @override
  State<ConferenceListScreen> createState() =>
      _ConferenceListScreenState();
}

class _ConferenceListScreenState
    extends State<ConferenceListScreen> {
  late Future<List<Conference>> _conferencesFuture;

  @override
  void initState() {
    super.initState();
    _loadConferences();
  }

  void _loadConferences() {
    _conferencesFuture = ConferenceService.getConferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conferences'),
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
                      setState(() {
                        _loadConferences();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final conferences = snapshot.data ?? [];

          if (conferences.isEmpty) {
            return const Center(
              child: Text('No conferences available.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conferences.length,
            itemBuilder: (context, index) {
              final conference = conferences[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConferenceDetailScreen(
                          conference: conference,
                        ),
                      ),
                    );
                  },
                  title: Text(
                    conference.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text('Location: ${conference.location}'),
                        Text(
                          'Date: ${conference.startDate.toString().split(' ').first}',
                        ),
                        Text('Status: ${conference.status}'),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),

                ),
              );
            },
          );
        },
      ),
    );
  }
}

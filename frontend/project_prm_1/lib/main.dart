
import 'package:flutter/material.dart';
import 'services/conference_service.dart';

void main() {
  runApp(const ConferenceApp());
}

class ConferenceApp extends StatelessWidget {
  const ConferenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const ConferencePage(),
    );
  }
}

class ConferencePage extends StatefulWidget {
  const ConferencePage({super.key});

  @override
  State<ConferencePage> createState() => _ConferencePageState();
}

class _ConferencePageState extends State<ConferencePage> {
  final ConferenceService _service = ConferenceService();

  late Future<List<dynamic>> _conferencesFuture;

  @override
  void initState() {
    super.initState();
    _conferencesFuture = _service.fetchConferences();
  }

  void _reloadConferences() {
    setState(() {
      _conferencesFuture = _service.fetchConferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách hội nghị'),
        actions: [
          IconButton(
            onPressed: _reloadConferences,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text('Không thể tải danh sách hội nghị.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reloadConferences,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final conferences = snapshot.data ?? [];

          if (conferences.isEmpty) {
            return const Center(
              child: Text('Chưa có hội nghị nào.'),
            );
          }

          return ListView.builder(
            itemCount: conferences.length,
            itemBuilder: (context, index) {
              final conference =
              conferences[index] as Map<String, dynamic>;

              final title =
                  conference['title']?.toString() ?? 'Chưa có tiêu đề';
              final location =
                  conference['location']?.toString() ?? 'Chưa có địa điểm';
              final startDate =
                  conference['start_date']?.toString() ?? 'Chưa có ngày';
              final description =
                  conference['description']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      '${conference['conference_id'] ?? '?'}',
                    ),
                  ),
                  title: Text(title),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Địa điểm: $location\n'
                          'Ngày bắt đầu: $startDate\n'
                          'Mô tả: ${description.isEmpty ? 'Không có mô tả' : description}',
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

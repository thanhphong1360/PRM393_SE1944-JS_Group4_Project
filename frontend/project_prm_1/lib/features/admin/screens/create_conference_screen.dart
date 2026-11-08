
import 'package:flutter/material.dart';

import '../../../core/services/conference_service.dart';

class CreateConferenceScreen extends StatefulWidget {
  const CreateConferenceScreen({super.key});

  @override
  State<CreateConferenceScreen> createState() =>
      _CreateConferenceScreenState();
}

class _CreateConferenceScreenState
    extends State<CreateConferenceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;

  String _registrationPolicy = 'Open';

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        _startDate = selectedDate;
      });
    }
  }

  Future<void> _createConference() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a conference date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response =
      await ConferenceService.createConference(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDate!,
        description:
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        registrationPolicy: _registrationPolicy,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ??
                'Conference created successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create conference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Conference'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Conference Title',
                icon: Icons.event,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter conference title.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter location.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Conference Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _startDate == null
                        ? 'Select Date'
                        : '${_startDate!.year}-'
                        '${_startDate!.month.toString().padLeft(2, '0')}-'
                        '${_startDate!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                icon: Icons.description,
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              const Text(
                'Registration Policy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _registrationPolicy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.policy),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Open',
                    child: Text('Open'),
                  ),
                  DropdownMenuItem(
                    value: 'ApprovalRequired',
                    child: Text('Approval Required'),
                  ),
                  DropdownMenuItem(
                    value: 'InvitationOnly',
                    child: Text('Invitation Only'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _registrationPolicy = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : _createConference,
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.add),
                  label: Text(
                    _isSubmitting
                        ? 'Creating...'
                        : 'Create Conference',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

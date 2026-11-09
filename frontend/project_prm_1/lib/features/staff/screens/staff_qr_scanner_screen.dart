import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../models/conference.dart';
import '../../../core/services/staff_check_in_service.dart';

class StaffQrScannerScreen extends StatefulWidget {
  final Conference conference;

  const StaffQrScannerScreen({super.key, required this.conference});

  @override
  State<StaffQrScannerScreen> createState() => _StaffQrScannerScreenState();
}

class _StaffQrScannerScreenState extends State<StaffQrScannerScreen> {
  late final MobileScannerController _scannerController;

  bool _hasScanned = false;
  bool _isLoading = false;
  bool _isCheckingIn = false;
  bool _isCheckedIn = false;

  String? _scannedTicketId;
  String? _errorMessage;
  String? _checkInMessage;

  Map<String, dynamic>? _validationResult;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || _isLoading) return;

    for (final barcode in capture.barcodes) {
      final String? value = barcode.rawValue?.trim();

      if (value == null || value.isEmpty) continue;

      setState(() {
        _hasScanned = true;
        _scannedTicketId = value;
        _isLoading = true;
        _errorMessage = null;
        _validationResult = null;
      });

      unawaited(_validateTicket(value));
      break;
    }
  }

  Future<void> _validateTicket(String ticketId) async {
    await _scannerController.stop();

    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{12}$',
    );

    if (!uuidPattern.hasMatch(ticketId)) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid QR code. Please scan a valid ticket QR.';
      });

      return;
    }

    try {
      final response = await StaffCheckInService.validateTicket(
        ticketId: ticketId,
        conferenceId: widget.conference.conferenceId,
      );

      if (!mounted) return;

      if (response['success'] != true) {
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'Ticket validation failed.';
        });

        return;
      }

      setState(() {
        _isLoading = false;
        _validationResult = response;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmCheckIn() async {
    if (_isCheckingIn || _isCheckedIn) return;

    if (_scannedTicketId == null) return;

    setState(() {
      _isCheckingIn = true;
      _checkInMessage = null;
    });

    try {
      final response = await StaffCheckInService.checkIn(
        ticketId: _scannedTicketId!,
        conferenceId: widget.conference.conferenceId,
      );

      if (!mounted) return;

      if (response['success'] != true) {
        setState(() {
          _isCheckingIn = false;
          _checkInMessage = response['message'] ?? 'Check-in failed.';
        });

        return;
      }

      setState(() {
        _isCheckingIn = false;
        _isCheckedIn = true;
        _checkInMessage =
            response['message'] ?? 'Check-in completed successfully.';

        final ticket = Map<String, dynamic>.from(
          _validationResult!['ticket'] as Map,
        );

        ticket['status'] = 'Used';

        _validationResult!['ticket'] = ticket;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCheckingIn = false;
        _checkInMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _hasScanned = false;
      _isLoading = false;
      _isCheckingIn = false;
      _isCheckedIn = false;
      _scannedTicketId = null;
      _errorMessage = null;
      _checkInMessage = null;
      _validationResult = null;
    });

    await _scannerController.start();
  }

  Widget _buildValidationResult() {
    final ticket = Map<String, dynamic>.from(
      _validationResult!['ticket'] as Map,
    );

    final attendee = Map<String, dynamic>.from(
      _validationResult!['attendee'] as Map,
    );

    final conference = Map<String, dynamic>.from(
      _validationResult!['conference'] as Map,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              _isCheckedIn ? Icons.check_circle : Icons.verified,
              color: _isCheckedIn ? Colors.green : Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isCheckedIn ? 'Check-in Successful' : 'Ticket is valid',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        const Text(
          'Attendee Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text('Name: ${attendee['full_name'] ?? 'N/A'}'),
        Text('Email: ${attendee['email'] ?? 'N/A'}'),
        Text('User ID: ${attendee['user_id'] ?? 'N/A'}'),

        const Divider(height: 24),

        const Text(
          'Ticket Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text('Ticket ID: ${ticket['ticket_id'] ?? 'N/A'}'),
        Text('Status: ${ticket['status'] ?? 'N/A'}'),
        Text('Registered at: ${ticket['registered_at'] ?? 'N/A'}'),

        const Divider(height: 24),

        const Text(
          'Conference Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text('Title: ${conference['title'] ?? 'N/A'}'),
        Text('Location: ${conference['location'] ?? 'N/A'}'),
        Text('Start date: ${conference['start_date'] ?? 'N/A'}'),

        const SizedBox(height: 16),

        if (_isCheckedIn)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _checkInMessage ?? 'Check-in completed successfully.',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else ...[
          const Text(
            'Please review the information before confirming check-in.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 12),

          if (_checkInMessage != null) ...[
            Text(_checkInMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCheckingIn ? null : _confirmCheckIn,
              icon: _isCheckingIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.how_to_reg),
              label: Text(
                _isCheckingIn ? 'Checking in...' : 'Confirm Check-in',
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _scanAgain,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Another Ticket'),
          ),
        ),
      ],
    );
  }

  Widget _buildScanResult() {
    if (_isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Validating ticket...'),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          const Text(
            'Ticket Validation Failed',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanAgain,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
            ),
          ),
        ],
      );
    }

    if (_validationResult != null) {
      return _buildValidationResult();
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Ticket QR')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Conference',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.conference.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.conference.location),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

                if (!_hasScanned)
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                if (_hasScanned)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 420),
                          child: SingleChildScrollView(
                            child: _buildScanResult(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (!_hasScanned)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Place the ticket QR code inside the scanning frame.',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

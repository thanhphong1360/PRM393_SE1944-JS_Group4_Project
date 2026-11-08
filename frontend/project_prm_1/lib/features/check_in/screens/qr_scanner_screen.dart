import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/check_in_service.dart';
import '../../../models/check_in_result.dart';
import '../widgets/check_in_result_sheet.dart';
import '../widgets/manual_ticket_dialog.dart';
import '../widgets/scan_history_sheet.dart';
import '../widgets/scanner_overlay.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late final MobileScannerController _controller;

  bool _isProcessing = false;
  bool _continuousMode = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  final List<CheckInResult> _scanHistory = [];

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue ?? barcodes.first.displayValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final trimmed = rawValue.trim();

    // Prevent duplicate triggers within 2 seconds for identical code
    final now = DateTime.now();
    if (_lastScannedCode == trimmed &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 2000) {
      return;
    }

    _lastScannedCode = trimmed;
    _lastScanTime = now;

    await _processTicket(trimmed);
  }

  Future<void> _processTicket(String code) async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isProcessing = true;
    });

    if (!_continuousMode) {
      try {
        await _controller.stop();
      } catch (_) {}
    }

    final result = await CheckInService.checkIn(code);

    if (!mounted) return;

    setState(() {
      _scanHistory.insert(0, result);
      _isProcessing = false;
    });

    if (_continuousMode) {
      // Show non-blocking toast/snack in continuous mode
      final color = result.success
          ? Colors.green
          : (result.isAlreadyCheckedIn ? Colors.orange : Colors.red);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: color,
          content: Row(
            children: [
              Icon(
                result.success
                    ? Icons.check_circle
                    : (result.isAlreadyCheckedIn ? Icons.warning : Icons.error),
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.attendeeFullName != null
                      ? '${result.attendeeFullName} - ${result.message}'
                      : result.message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show full bottom sheet
      await CheckInResultSheet.show(
        context,
        result: result,
        onContinue: () async {
          _resumeScanning();
        },
      );
      _resumeScanning();
    }
  }

  void _resumeScanning() async {
    if (!mounted) return;
    setState(() {
      _lastScannedCode = null;
    });
    try {
      await _controller.start();
    } catch (_) {}
  }

  Future<void> _openManualEntry() async {
    final ticketId = await ManualTicketDialog.show(context);
    if (ticketId != null && ticketId.isNotEmpty) {
      await _processTicket(ticketId);
    }
  }

  void _openHistory() {
    ScanHistorySheet.show(
      context,
      history: _scanHistory,
      onClear: () {
        setState(() {
          _scanHistory.clear();
        });
      },
      onItemTap: (item) {
        CheckInResultSheet.show(
          context,
          result: item,
          onContinue: () {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = (size.width * 0.72).clamp(240.0, 320.0);

    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: scanBoxSize,
      height: scanBoxSize,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Scanner View
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) {
              return _buildErrorState(error.errorCode.name);
            },
            placeholderBuilder: (context) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          ),

          // 2. Animated Overlay with Corner Brackets & Laser
          ScannerOverlay(
            scanWindow: scanWindow,
            borderColor: _isProcessing ? Colors.orange : const Color(0xFF3B82F6),
          ),

          // 3. Instruction Text under scan window
          Positioned(
            top: scanWindow.bottom + 24,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isProcessing
                            ? Icons.hourglass_top
                            : Icons.qr_code_scanner,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isProcessing
                            ? 'Đang kiểm tra mã vé...'
                            : 'Căn chỉnh mã QR vé vào trong khung',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Top Header & Camera Action Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Quét Mã QR Điểm Danh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Torch button
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (context, state, _) {
                        final isTorchOn = state.torchState == TorchState.on;
                        return IconButton(
                          tooltip: 'Bật/Tắt đèn Flash',
                          icon: Icon(
                            isTorchOn ? Icons.flash_on : Icons.flash_off,
                            color: isTorchOn ? Colors.amber : Colors.white,
                          ),
                          onPressed: () => _controller.toggleTorch(),
                        );
                      },
                    ),
                    // Switch Camera
                    IconButton(
                      tooltip: 'Đổi camera trước/sau',
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => _controller.switchCamera(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Controls Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Manual input button
                        _buildQuickActionButton(
                          icon: Icons.keyboard_alt_outlined,
                          label: 'Nhập thủ công',
                          onTap: _openManualEntry,
                        ),
                        // History button
                        Stack(
                          children: [
                            _buildQuickActionButton(
                              icon: Icons.history,
                              label: 'Lịch sử quét',
                              onTap: _openHistory,
                            ),
                            if (_scanHistory.isNotEmpty)
                              Positioned(
                                right: 12,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${_scanHistory.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Continuous mode toggle
                        _buildQuickActionButton(
                          icon: _continuousMode
                              ? Icons.autorenew
                              : Icons.pause_circle_outline,
                          label: _continuousMode ? 'Quét liên tục: BẬT' : 'Quét liên tục: TẮT',
                          isActive: _continuousMode,
                          onTap: () {
                            setState(() {
                              _continuousMode = !_continuousMode;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 6. Processing Loading Indicator
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Đang điểm danh...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.lightBlueAccent : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.lightBlueAccent : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorDetails) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể truy cập máy ảnh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng cấp quyền máy ảnh cho ứng dụng hoặc sử dụng tính năng nhập mã vé thủ công.\n($errorDetails)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _openManualEntry,
              icon: const Icon(Icons.keyboard),
              label: const Text('Nhập mã vé thủ công'),
            ),
          ],
        ),
      ),
    );
  }
}

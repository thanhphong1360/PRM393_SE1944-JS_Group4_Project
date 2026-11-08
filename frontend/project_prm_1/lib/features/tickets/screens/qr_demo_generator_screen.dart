import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/services/check_in_service.dart';
import '../../check_in/widgets/check_in_result_sheet.dart';

class QrDemoGeneratorScreen extends StatefulWidget {
  const QrDemoGeneratorScreen({super.key});

  @override
  State<QrDemoGeneratorScreen> createState() => _QrDemoGeneratorScreenState();
}

class _QrDemoGeneratorScreenState extends State<QrDemoGeneratorScreen> {
  final List<Map<String, String>> _presets = [
    {
      'title': '1. Vé hợp lệ (Nguyễn Văn An)',
      'uuid': 'd3b07384-d113-46fb-a79b-2221b6329e47',
      'desc': 'Chưa điểm danh, quét sẽ THÀNH CÔNG (Xanh lá)',
      'status': 'Valid',
    },
    {
      'title': '2. Vé hợp lệ (Trần Thị Bình)',
      'uuid': 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
      'desc': 'Chưa điểm danh, quét sẽ THÀNH CÔNG (Xanh lá)',
      'status': 'Valid',
    },
    {
      'title': '3. Vé đã dùng (Lê Hoàng Cường)',
      'uuid': 'e4f5a6b7-c8d9-4e0f-1a2b-3c4d5e6f7a8b',
      'desc': 'Đã check-in trước đó, quét sẽ báo CẢNH BÁO (Cam)',
      'status': 'Used',
    },
    {
      'title': '4. Vé bị hủy (Phạm Thu Dung)',
      'uuid': 'f9e8d7c6-b5a4-4321-fedc-ba9876543210',
      'desc': 'Trạng thái Cancelled, quét sẽ báo LỖI (Đỏ)',
      'status': 'Cancelled',
    },
  ];

  late int _selectedIndex;
  final TextEditingController _customController = TextEditingController();
  bool _isCustom = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String get _currentTicketId {
    if (_isCustom) {
      return _customController.text.trim().isEmpty
          ? _presets[0]['uuid']!
          : _customController.text.trim();
    }
    return _presets[_selectedIndex]['uuid']!;
  }

  Future<void> _simulateCheckIn() async {
    setState(() => _isChecking = true);
    final result = await CheckInService.checkIn(_currentTicketId);
    if (!mounted) return;
    setState(() => _isChecking = false);

    CheckInResultSheet.show(
      context,
      result: result,
      onContinue: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUuid = _currentTicketId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bộ Tạo & Xem Mã QR Kiểm Thử'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chọn loại vé mẫu trong Database để hiển thị mã QR:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Presets Selector
            ...List.generate(_presets.length, (i) {
              final preset = _presets[i];
              final isSelected = !_isCustom && _selectedIndex == i;
              final isUsed = preset['status'] == 'Used';
              final isCancelled = preset['status'] == 'Cancelled';

              final color = isUsed
                  ? Colors.orange
                  : (isCancelled ? Colors.red : Colors.green);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isCustom = false;
                      _selectedIndex = i;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preset['desc']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Live QR Display Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'MÃ QR VÉ ĐIỂM DANH',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: currentUuid,
                        version: QrVersions.auto,
                        size: 210.0,
                        backgroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Ticket UUID Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentUuid,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Sao chép',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: currentUuid),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép mã UUID!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Button: Simulate Scanning Right Here
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isChecking ? null : _simulateCheckIn,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isChecking
                            ? 'Đang gửi điểm danh...'
                            : 'Thử điểm danh ngay với mã này',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

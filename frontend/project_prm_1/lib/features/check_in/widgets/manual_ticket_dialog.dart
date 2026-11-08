import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/check_in_service.dart';

class ManualTicketDialog extends StatefulWidget {
  final ValueChanged<String> onSubmit;

  const ManualTicketDialog({
    super.key,
    required this.onSubmit,
  });

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => ManualTicketDialog(
        onSubmit: (ticketId) => Navigator.of(context).pop(ticketId),
      ),
    );
  }

  @override
  State<ManualTicketDialog> createState() => _ManualTicketDialogState();
}

class _ManualTicketDialogState extends State<ManualTicketDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      final extracted = CheckInService.extractTicketId(data.text!);
      setState(() {
        _controller.text = extracted ?? data.text!.trim();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final ticketId = CheckInService.extractTicketId(_controller.text);
      if (ticketId != null) {
        widget.onSubmit(ticketId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.keyboard, color: Colors.blue),
          SizedBox(width: 10),
          Text(
            'Nhập mã vé thủ công',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nhập hoặc dán mã vé (UUID) của người tham dự để tiến hành điểm danh.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Mã vé (Ticket ID)',
                hintText: 'e.g. 12345678-1234-1234-1234-123456789abc',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Dán từ clipboard',
                  icon: const Icon(Icons.content_paste),
                  onPressed: _pasteFromClipboard,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập mã vé';
                }
                final id = CheckInService.extractTicketId(val);
                if (id == null || !CheckInService.isValidUuid(id)) {
                  return 'Mã vé không đúng định dạng UUID';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _submit,
          child: const Text('Điểm danh'),
        ),
      ],
    );
  }
}

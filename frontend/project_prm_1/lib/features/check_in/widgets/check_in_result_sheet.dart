import 'package:flutter/material.dart';

import '../../../models/check_in_result.dart';

class CheckInResultSheet extends StatelessWidget {
  final CheckInResult result;
  final VoidCallback onContinue;

  const CheckInResultSheet({
    super.key,
    required this.result,
    required this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    required CheckInResult result,
    required VoidCallback onContinue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckInResultSheet(
        result: result,
        onContinue: () {
          Navigator.of(context).pop();
          onContinue();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccess = result.success;
    final isAlreadyUsed = result.isAlreadyCheckedIn;

    final primaryColor = isSuccess
        ? const Color(0xFF16A34A)
        : (isAlreadyUsed ? const Color(0xFFEA580C) : const Color(0xFFDC2626));

    final bgColor = isSuccess
        ? const Color(0xFFF0FDF4)
        : (isAlreadyUsed ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2));

    final icon = isSuccess
        ? Icons.check_circle_rounded
        : (isAlreadyUsed ? Icons.warning_amber_rounded : Icons.cancel_rounded);

    final title = isSuccess
        ? 'Điểm Danh Thành Công!'
        : (isAlreadyUsed ? 'Vé Đã Được Điểm Danh' : 'Điểm Danh Thất Bại');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Details content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Attendee Card
                  if (result.attendeeFullName != null || result.attendeeEmail != null) ...[
                    _buildInfoCard(
                      context,
                      title: 'Thông tin người tham dự',
                      icon: Icons.person_outline,
                      items: [
                        if (result.attendeeFullName != null)
                          _InfoRow(
                            label: 'Họ và tên',
                            value: result.attendeeFullName!,
                            isHighlight: true,
                          ),
                        if (result.attendeeEmail != null)
                          _InfoRow(
                            label: 'Email',
                            value: result.attendeeEmail!,
                          ),
                        if (result.attendeeId != null)
                          _InfoRow(
                            label: 'Mã người dùng',
                            value: '#${result.attendeeId}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Conference Card
                  if (result.conferenceTitle != null) ...[
                    _buildInfoCard(
                      context,
                      title: 'Thông tin hội nghị',
                      icon: Icons.event_outlined,
                      items: [
                        _InfoRow(
                          label: 'Hội nghị',
                          value: result.conferenceTitle!,
                        ),
                        if (result.conferenceLocation != null)
                          _InfoRow(
                            label: 'Địa điểm',
                            value: result.conferenceLocation!,
                          ),
                        if (result.conferenceStartDate != null)
                          _InfoRow(
                            label: 'Ngày diễn ra',
                            value: result.conferenceStartDate!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Ticket Card
                  _buildInfoCard(
                    context,
                    title: 'Chi tiết vé',
                    icon: Icons.confirmation_number_outlined,
                    items: [
                      if (result.ticketId != null)
                        _InfoRow(
                          label: 'Mã vé (Ticket ID)',
                          value: result.ticketId!,
                          isMonospace: true,
                        ),
                      if (result.ticketStatus != null)
                        _InfoRow(
                          label: 'Trạng thái vé',
                          value: result.ticketStatus!,
                          badgeColor: result.ticketStatus == 'Used'
                              ? Colors.green
                              : Colors.blue,
                        ),
                      if (result.checkedInAt != null)
                        _InfoRow(
                          label: 'Thời gian điểm danh',
                          value: _formatDateTime(result.checkedInAt!),
                        ),
                      _InfoRow(
                        label: 'Thời gian quét',
                        value: _formatDateTime(result.scannedAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text(
                    'Tiếp tục quét',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_InfoRow> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        e.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: e.badgeColor != null
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: e.badgeColor!.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: e.badgeColor,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              e.value,
                              style: TextStyle(
                                fontSize: e.isHighlight ? 14 : 12,
                                fontWeight: e.isHighlight
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontFamily: e.isMonospace ? 'monospace' : null,
                                color: Colors.grey.shade900,
                              ),
                            ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min:$s';
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isMonospace;
  final Color? badgeColor;

  _InfoRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isMonospace = false,
    this.badgeColor,
  });
}

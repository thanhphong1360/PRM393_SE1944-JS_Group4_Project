import 'package:flutter/material.dart';

import '../../../models/check_in_result.dart';

class ScanHistorySheet extends StatefulWidget {
  final List<CheckInResult> history;
  final VoidCallback onClear;
  final ValueChanged<CheckInResult> onItemTap;

  const ScanHistorySheet({
    super.key,
    required this.history,
    required this.onClear,
    required this.onItemTap,
  });

  static Future<void> show(
    BuildContext context, {
    required List<CheckInResult> history,
    required VoidCallback onClear,
    required ValueChanged<CheckInResult> onItemTap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScanHistorySheet(
        history: history,
        onClear: onClear,
        onItemTap: onItemTap,
      ),
    );
  }

  @override
  State<ScanHistorySheet> createState() => _ScanHistorySheetState();
}

class _ScanHistorySheetState extends State<ScanHistorySheet> {
  String _filter = 'ALL'; // ALL, SUCCESS, FAILED

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = widget.history.length;
    final successCount = widget.history.where((e) => e.success).length;
    final failedCount = totalCount - successCount;

    final filteredList = widget.history.where((item) {
      if (_filter == 'SUCCESS') return item.success;
      if (_filter == 'FAILED') return !item.success;
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Lịch sử quét phiên này',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.history.isNotEmpty)
                  IconButton(
                    tooltip: 'Xóa lịch sử',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      widget.onClear();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),

          // Stats Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildStatBadge(
                  label: 'Tổng số',
                  count: totalCount,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  label: 'Hợp lệ',
                  count: successCount,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  label: 'Thất bại/Trùng',
                  count: failedCount,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _filter == 'ALL',
                  onSelected: (_) => setState(() => _filter = 'ALL'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Thành công'),
                  selected: _filter == 'SUCCESS',
                  onSelected: (_) => setState(() => _filter = 'SUCCESS'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Thất bại'),
                  selected: _filter == 'FAILED',
                  onSelected: (_) => setState(() => _filter = 'FAILED'),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Chưa có lượt quét nào trong danh sách',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isSuccess = item.success;
                      final isAlreadyUsed = item.isAlreadyCheckedIn;

                      final color = isSuccess
                          ? Colors.green
                          : (isAlreadyUsed ? Colors.orange : Colors.red);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        color: color.withValues(alpha: 0.04),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onItemTap(item);
                          },
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(
                              isSuccess
                                  ? Icons.check
                                  : (isAlreadyUsed
                                      ? Icons.warning_amber
                                      : Icons.close),
                              color: color,
                            ),
                          ),
                          title: Text(
                            item.attendeeFullName ??
                                (item.ticketId != null
                                    ? 'Vé: ${item.ticketId!.substring(0, 8)}...'
                                    : 'Mã không xác định'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                _formatTime(item.scannedAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

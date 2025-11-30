import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entity.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceEntity attendance;

  const AttendanceCard({Key? key, required this.attendance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(attendance.status),
          child: Icon(
            _getStatusIcon(attendance.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          attendance.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${attendance.date.day}/${attendance.date.month}/${attendance.date.year}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            if (attendance.checkInTime != null)
              Row(
                children: [
                  Icon(
                    Icons.login,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'In: ${_formatTime(attendance.checkInTime!)}',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            if (attendance.remarks != null && attendance.remarks!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Remarks: ${attendance.remarks}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(attendance.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getStatusColor(attendance.status)),
          ),
          child: Text(
            attendance.status.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(attendance.status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
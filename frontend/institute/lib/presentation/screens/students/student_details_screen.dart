import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../domain/entities/student_entity.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../providers/attendance_provider.dart';
import '../invoices/student_invoices_screen.dart';
import '../invoices/create_invoice_enhanced_screen.dart';

class StudentDetailsScreen extends StatelessWidget {
  final StudentEntity student;

  const StudentDetailsScreen({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          IconButton(
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(context),
            const SizedBox(height: 24),
            _buildQRCodeSection(context),
            const SizedBox(height: 24),
            _buildContactSection(context),
            const SizedBox(height: 24),
            _buildEnrollmentSection(context),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    student.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(student.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(student.status)),
                        ),
                        child: Text(
                          student.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(student.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (student.licenseNumber != null) ...[
              Row(
                children: [
                  const Icon(Icons.card_membership, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'License: ${student.licenseNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'DOB: ${_formatDate(student.dateOfBirth)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection(BuildContext context) {
    final qrData = student.qrCode ?? student.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student QR Code',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Scan this QR code for attendance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _shareQRCode(context, qrData),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyQRData(context, qrData),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy ID'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', student.email),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Phone', student.phone),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Address', student.address),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrollment Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_month, 'Enrollment Date', _formatDate(student.enrollmentDate)),
            const SizedBox(height: 12),
            if (student.packageId != null)
              _buildInfoRow(Icons.card_giftcard, 'Package ID', student.packageId!),
            if (student.instructorId != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.person, 'Instructor ID', student.instructorId!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Primary Actions - Full Width
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _createInvoice(context),
                icon: const Icon(Icons.receipt_long, size: 22),
                label: const Text(
                  'Create New Invoice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary Actions - Two Columns
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewInvoices(context),
                    icon: const Icon(Icons.receipt, size: 20),
                    label: const Text('View Invoices'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewAttendance(context),
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: const Text('Attendance'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tertiary Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _markAttendance(context),
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('Mark Attendance'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'suspended':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _shareQRCode(BuildContext context, String qrData) {
    // TODO: Implement QR code sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code sharing will be implemented')),
    );
  }

  void _copyQRData(BuildContext context, String qrData) {
    Clipboard.setData(ClipboardData(text: qrData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student ID copied to clipboard')),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: const Text('Edit student functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _viewAttendance(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AttendanceViewDialog(studentId: student.id, studentName: student.name),
    );
  }

  void _viewInvoices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentInvoicesScreen(
          studentId: student.id,
          studentName: student.name,
        ),
      ),
    );
  }

  void _markAttendance(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _MarkAttendanceDialog(student: student),
    );
  }

  void _createInvoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateInvoiceEnhancedScreen(
          preSelectedStudentId: student.id,
        ),
      ),
    );
  }
}

class _AttendanceViewDialog extends StatefulWidget {
  final String studentId;
  final String studentName;

  const _AttendanceViewDialog({
    required this.studentId,
    required this.studentName,
  });

  @override
  State<_AttendanceViewDialog> createState() => _AttendanceViewDialogState();
}

class _AttendanceViewDialogState extends State<_AttendanceViewDialog> with TickerProviderStateMixin {
  // List tab date filter (independent)
  DateTime? _listStartDate;
  DateTime? _listEndDate;

  late TabController _tabController;

  // Calendar tab state (independent)
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAttendance() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    // Load all attendance without any date filter - tabs will filter locally
    attendanceProvider.getAttendance(
      refresh: true,
      studentId: widget.studentId,
    );
  }

  // List tab date range picker
  Future<void> _selectListDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _listStartDate != null && _listEndDate != null
          ? DateTimeRange(start: _listStartDate!, end: _listEndDate!)
          : null,
    );

    if (dateRange != null) {
      setState(() {
        _listStartDate = dateRange.start;
        _listEndDate = dateRange.end;
      });
    }
  }

  // List tab clear filter
  void _clearListDateFilter() {
    setState(() {
      _listStartDate = null;
      _listEndDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Attendance - ${widget.studentName}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: 'Calendar',
                ),
                Tab(
                  icon: Icon(Icons.list),
                  text: 'List',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<AttendanceProvider>(
                builder: (context, attendanceProvider, child) {
                  if (attendanceProvider.isLoading && attendanceProvider.attendance.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (attendanceProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${attendanceProvider.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadAttendance,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final studentAttendance = attendanceProvider.attendance
                      .where((attendance) => attendance.studentId == widget.studentId)
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Calendar Tab
                      _buildCalendarView(studentAttendance),
                      // List Tab
                      _buildListView(studentAttendance),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(List<AttendanceEntity> studentAttendance) {
    // Convert attendance list to a map for easy lookup by date
    Map<DateTime, List<AttendanceEntity>> attendanceMap = {};
    for (var attendance in studentAttendance) {
      final dateKey = DateTime(attendance.date.year, attendance.date.month, attendance.date.day);
      attendanceMap[dateKey] = attendanceMap[dateKey] ?? [];
      attendanceMap[dateKey]!.add(attendance);
    }

    // Get attendance records for selected day
    List<AttendanceEntity> selectedDayAttendance = [];
    if (_selectedDay != null) {
      final selectedDateKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      selectedDayAttendance = attendanceMap[selectedDateKey] ?? [];
    }

    return SingleChildScrollView(
      child: Column(
        children: [
            // Calendar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TableCalendar<AttendanceEntity>(
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(color: Colors.black87),
                  defaultTextStyle: const TextStyle(color: Colors.black87),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  // Make calendar more compact
                  cellMargin: const EdgeInsets.all(2.0),
                  rowDecoration: const BoxDecoration(),
                ),
                daysOfWeekHeight: 30,
                rowHeight: 35,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) {
              final dateKey = DateTime(day.year, day.month, day.day);
              return attendanceMap[dateKey] ?? [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.black54),
              weekendStyle: TextStyle(color: Colors.black54),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final dateKey = DateTime(day.year, day.month, day.day);
                final dayAttendance = attendanceMap[dateKey];

                if (dayAttendance != null && dayAttendance.isNotEmpty) {
                  // Check if any attendance record is 'present'
                  final hasPresent = dayAttendance.any((att) => att.status.toLowerCase() == 'present');

                  if (hasPresent) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                }
                return null;
              },
              todayBuilder: (context, day, focusedDay) {
                final dateKey = DateTime(day.year, day.month, day.day);
                final dayAttendance = attendanceMap[dateKey];

                // Check if the person is present today
                final hasPresent = dayAttendance != null &&
                    dayAttendance.isNotEmpty &&
                    dayAttendance.any((att) => att.status.toLowerCase() == 'present');

                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: hasPresent ? Colors.green : Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: hasPresent ? Colors.white : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 30),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events.take(3).map((event) {
                        final attendance = event as AttendanceEntity;
                        final status = attendance.status.toLowerCase();

                        // Don't show marker for present status as it has green background
                        if (status == 'present') {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getAttendanceStatusColor(attendance.status),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
        ),

        // Attendance list for selected day
        if (_selectedDay != null && selectedDayAttendance.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                ...selectedDayAttendance.map((attendance) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getAttendanceStatusColor(attendance.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${attendance.status.toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _getAttendanceStatusColor(attendance.status),
                              ),
                            ),
                            if (attendance.checkInTime != null)
                              Text(
                                'Check-in: ${_formatTime(attendance.checkInTime!)}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (attendance.checkInTime != null)
                              const SizedBox(height: 4),
                            if (attendance.remarks != null && attendance.remarks!.isNotEmpty)
                              Text(
                                'Remarks: ${attendance.remarks}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ] else if (_selectedDay != null && studentAttendance.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              'No attendance records for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ] else if (studentAttendance.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No attendance records found in selected date range',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        ],
      ),
    );
  }

  Widget _buildListView(List<AttendanceEntity> studentAttendance) {
    // Filter data locally based on List tab's date range
    List<AttendanceEntity> filteredAttendance = studentAttendance;
    if (_listStartDate != null && _listEndDate != null) {
      filteredAttendance = studentAttendance.where((attendance) {
        final attendanceDate = DateTime(
          attendance.date.year,
          attendance.date.month,
          attendance.date.day,
        );
        final startDate = DateTime(
          _listStartDate!.year,
          _listStartDate!.month,
          _listStartDate!.day,
        );
        final endDate = DateTime(
          _listEndDate!.year,
          _listEndDate!.month,
          _listEndDate!.day,
        );
        return !attendanceDate.isBefore(startDate) && !attendanceDate.isAfter(endDate);
      }).toList();
    }

    return Column(
      children: [
        // Date range filter - always visible
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectListDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _listStartDate != null && _listEndDate != null
                        ? '${_formatDate(_listStartDate!)} - ${_formatDate(_listEndDate!)}'
                        : 'Select Date Range',
                  ),
                ),
              ),
              if (_listStartDate != null && _listEndDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearListDateFilter,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Filter',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Content area
        Expanded(
          child: filteredAttendance.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredAttendance.length,
                  itemBuilder: (context, index) {
                    final attendance = filteredAttendance[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAttendanceStatusColor(attendance.status),
                          child: Icon(
                            _getAttendanceStatusIcon(attendance.status),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(_formatDate(attendance.date)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${attendance.status.toUpperCase()}'),
                            if (attendance.remarks != null && attendance.remarks!.isNotEmpty)
                              Text('Remarks: ${attendance.remarks}'),
                            if (attendance.checkInTime != null)
                              Text('Check-in: ${_formatTime(attendance.checkInTime!)}'),
                          ],
                        ),
                        trailing: Text(
                          _formatTime(attendance.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }


  Color _getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAttendanceStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _MarkAttendanceDialog extends StatefulWidget {
  final StudentEntity student;

  const _MarkAttendanceDialog({required this.student});

  @override
  State<_MarkAttendanceDialog> createState() => _MarkAttendanceDialogState();
}

class _MarkAttendanceDialogState extends State<_MarkAttendanceDialog> {
  String _selectedStatus = 'present';
  DateTime _selectedDate = DateTime.now();
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  final List<String> _statusOptions = ['present', 'absent', 'late', 'excused'];

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _markAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      await attendanceProvider.markAttendance(
        widget.student.id,
        _selectedStatus,
        remarks: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance marked as $_selectedStatus for ${widget.student.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mark Attendance - ${widget.student.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Date: '),
              Expanded(
                child: TextButton(
                  onPressed: _selectDate,
                  child: Text(_formatDate(_selectedDate)),
                ),
              ),
              IconButton(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Status:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _statusOptions.map((status) {
              return ChoiceChip(
                label: Text(status.toUpperCase()),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  }
                },
                selectedColor: _getAttendanceStatusColor(status).withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: _selectedStatus == status
                      ? _getAttendanceStatusColor(status)
                      : null,
                  fontWeight: _selectedStatus == status
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (Optional)',
              hintText: 'Add any additional notes...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _markAttendance,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mark Attendance'),
        ),
      ],
    );
  }

  Color _getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
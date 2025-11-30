import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/attendance_card.dart';
import 'qr_scanner_screen.dart';
import '../../../core/constants/role_constants.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with TickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener to handle tab changes
    _tabController.addListener(_handleTabChange);

    // Auto-select today's date
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      // Load all attendance data first
      attendanceProvider.getAttendance(refresh: true);
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

      if (_tabController.index == 0) {
        // Today tab - filter for today's date
        attendanceProvider.filterByDateRange(_selectedDate, _selectedDate);
      } else {
        // All Records tab - clear filter and show all data
        if (_startDate != null && _endDate != null) {
          attendanceProvider.filterByDateRange(_startDate!, _endDate!);
        } else {
          attendanceProvider.getAttendance(refresh: true);
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      Provider.of<AttendanceProvider>(context, listen: false)
          .filterByDateRange(_startDate!, _endDate!);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });

    Provider.of<AttendanceProvider>(context, listen: false)
        .getAttendance(refresh: true);
  }

  Widget _buildAttendanceHeader(BuildContext context, bool canMarkAttendance) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Present Students Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateTime.now().toString().split(' ')[0],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canMarkAttendance) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAttendanceReport(context),
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAttendanceReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: const AttendanceReportDialog(),
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        if (attendanceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (attendanceProvider.attendance.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No attendance records for today',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final todayAttendance = attendanceProvider.attendance.where((attendance) {
          final today = DateTime.now();
          final attendanceDate = attendance.date;
          return attendanceDate.year == today.year &&
                 attendanceDate.month == today.month &&
                 attendanceDate.day == today.day;
        }).toList();

        if (todayAttendance.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No attendance records for today',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await attendanceProvider.getAttendance(refresh: true);
            final today = DateTime.now();
            final todayStart = DateTime(today.year, today.month, today.day);
            attendanceProvider.filterByDateRange(todayStart, todayStart);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: todayAttendance.length,
            itemBuilder: (context, index) {
              return AttendanceCard(attendance: todayAttendance[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAllRecordsTab() {
    return Column(
      children: [
        // Date range filter - always visible
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Select Date Range',
                  ),
                ),
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDateFilter,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Filter',
                ),
              ],
            ],
          ),
        ),
        // Content area
        Expanded(
          child: Consumer<AttendanceProvider>(
            builder: (context, attendanceProvider, child) {
              if (attendanceProvider.isLoading && attendanceProvider.attendance.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (attendanceProvider.attendance.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await attendanceProvider.getAttendance(refresh: true);
                  if (_startDate != null && _endDate != null) {
                    attendanceProvider.filterByDateRange(_startDate!, _endDate!);
                  }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!attendanceProvider.isLoading &&
                        attendanceProvider.hasMoreData &&
                        scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      // Load more data when scrolled to bottom
                      attendanceProvider.getAttendance(
                        startDate: _startDate,
                        endDate: _endDate,
                      );
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: attendanceProvider.attendance.length +
                        (attendanceProvider.hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == attendanceProvider.attendance.length) {
                        // Show loading indicator at bottom
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return AttendanceCard(
                        attendance: attendanceProvider.attendance[index],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? '';
    final canMarkAttendance = RolePermissions.hasPermission(userRole, 'attendance');

    return Scaffold(
      body: Column(
        children: [
          _buildAttendanceHeader(context, canMarkAttendance),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue[600],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[600],
              tabs: const [
                Tab(text: 'Today', icon: Icon(Icons.today)),
                Tab(text: 'All Records', icon: Icon(Icons.list)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildAllRecordsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canMarkAttendance
        ? FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );
            },
            child: const Icon(Icons.qr_code_scanner),
          )
        : null,
    );
  }
}

class AttendanceReportDialog extends StatefulWidget {
  const AttendanceReportDialog({Key? key}) : super(key: key);

  @override
  State<AttendanceReportDialog> createState() => _AttendanceReportDialogState();
}

class _AttendanceReportDialogState extends State<AttendanceReportDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes
    _tabController.addListener(_handleTabChange);

    // Auto-select today's date and filter attendance for Calendar tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      attendanceProvider.filterByDateRange(_selectedDate, _selectedDate);
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

      if (_tabController.index == 0) {
        // Switching to Calendar tab - restore calendar selection
        attendanceProvider.filterByDateRange(_selectedDate, _selectedDate);
      } else {
        // Switching to List tab - apply list filter if exists, otherwise show all
        if (_rangeStart != null && _rangeEnd != null) {
          attendanceProvider.filterByDateRange(_rangeStart!, _rangeEnd!);
        } else {
          attendanceProvider.getAttendance(refresh: true);
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCalendarTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now(),
                focusedDay: _selectedDate,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                  attendanceProvider.filterByDateRange(selectedDay, selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red[400]),
                  holidayTextStyle: TextStyle(color: Colors.red[400]),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orange[400],
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Selected Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: attendanceProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceProvider.attendance.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No attendance records for selected date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: attendanceProvider.attendance.length,
                          itemBuilder: (context, index) {
                            return AttendanceCard(
                              attendance: attendanceProvider.attendance[index],
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListTab() {
    return Column(
      children: [
        // Date range filter - always visible
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _rangeStart != null && _rangeEnd != null
                        ? '${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year} - ${_rangeEnd!.day}/${_rangeEnd!.month}/${_rangeEnd!.year}'
                        : 'Select Date Range',
                  ),
                ),
              ),
              if (_rangeStart != null && _rangeEnd != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearDateRange,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Filter',
                ),
              ],
            ],
          ),
        ),
        // Content area
        Expanded(
          child: Consumer<AttendanceProvider>(
            builder: (context, attendanceProvider, child) {
              if (attendanceProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (attendanceProvider.attendance.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: attendanceProvider.attendance.length,
                itemBuilder: (context, index) {
                  return AttendanceCard(
                    attendance: attendanceProvider.attendance[index],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _rangeStart != null && _rangeEnd != null
          ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
      });

      Provider.of<AttendanceProvider>(context, listen: false)
          .filterByDateRange(_rangeStart!, _rangeEnd!);
    }
  }

  void _clearDateRange() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });

    Provider.of<AttendanceProvider>(context, listen: false)
        .getAttendance(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Calendar View', icon: Icon(Icons.calendar_today)),
            Tab(text: 'List View', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildListTab(),
        ],
      ),
    );
  }
}
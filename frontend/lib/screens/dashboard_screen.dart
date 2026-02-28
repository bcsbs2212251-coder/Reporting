import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _recentReports = [];
  List<dynamic> _myTasks = [];
  bool _isLoading = true;
  String currentRoute = '/dashboard';
  String userName = 'User';
  String userRole = 'Employee';
  double _shiftProgress = 0.4; // 40% progress (4 hours remaining out of 10)

  @override
  void initState() {
    super.initState();
    _loadData();
    _calculateShiftProgress();
  }

  void _calculateShiftProgress() {
    // Simulate shift progress based on time of day
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 8, 0); // 8 AM start
    final endOfDay = DateTime(now.year, now.month, now.day, 18, 0); // 6 PM end
    
    if (now.isAfter(startOfDay) && now.isBefore(endOfDay)) {
      final elapsed = now.difference(startOfDay).inMinutes;
      final total = endOfDay.difference(startOfDay).inMinutes;
      setState(() {
        _shiftProgress = elapsed / total;
      });
    }
  }

  Future<void> _loadData() async {
    final userResult = await ApiService.getCurrentUser();
    final statsResult = await ApiService.getDashboardStats();
    final reportsResult = await ApiService.getReports();
    final tasksResult = await ApiService.getTasks();

    if (mounted) {
      setState(() {
        if (userResult['success']) {
          _userData = userResult['data'];
          userName = _userData?['full_name'] ?? 'User';
          userRole = _userData?['role'] == 'admin' ? 'Admin' : 'Employee';
        }
        if (statsResult['success']) {
          _dashboardStats = statsResult['data'];
        }
        if (reportsResult['success']) {
          _recentReports = reportsResult['data']['reports'] ?? [];
        }
        if (tasksResult['success']) {
          _myTasks = tasksResult['data']['tasks'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = _userData?['full_name'] ?? 'User';
    final userEmail = _userData?['email'] ?? '';
    final userRole = _userData?['role'] ?? 'employee';
    final myReports = _dashboardStats?['my_reports'] ?? 0;
    final myTasks = _dashboardStats?['my_tasks'] ?? 0;
    final pendingTasks = _dashboardStats?['pending_tasks'] ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Stay on dashboard, don't go back
        
      },child: Scaffold(
        body: Row(
          children: [
            Sidebar(currentRoute: currentRoute),
            Expanded(
              child: Column(
                children: [
                  TopBar(userName: userName, userRole: userRole),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back, ${userName.split(' ')[0]}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                              const SizedBox(width: 8),
                              Text(
                                _getCurrentDate(),
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Shift Progress and AI Status
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SHIFT PROGRESS',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${((1 - _shiftProgress) * 10).toStringAsFixed(0)} hours remaining',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: _shiftProgress,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                        minHeight: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AI Live Transcription Ready',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        Text(
                                          'System operational',
                                          style: TextStyle(fontSize: 10, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildSubmitReportCard(context),
                                    const SizedBox(height: 30),
                                    _buildRecentActivity(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 30),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildStatsCard('My Reports', myReports.toString(), Icons.description, Colors.blue),
                                    const SizedBox(height: 20),
                                    _buildStatsCard('My Tasks', myTasks.toString(), Icons.task_alt, Colors.green),
                                    const SizedBox(height: 20),
                                    _buildStatsCard('Pending', pendingTasks.toString(), Icons.pending_actions, Colors.orange),
                                    const SizedBox(height: 20),
                                    _buildProfileCard(userName, userEmail),
                                    const SizedBox(height: 20),
                                    _buildDailyTasks(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildSubmitReportCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit Daily Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture voice notes, photos, and status updates for your shift.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('System Ready', style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.mic,
                  label: 'Record Voice Note',
                  subtitle: 'Click to start audio entry',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Upload Visuals',
                  subtitle: 'Drag photos or click to browse',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.description_outlined,
                  label: 'Add Detailed Notes',
                  subtitle: 'Manual entry & review draft',
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/submit-report').then((_) {
                      // Reload data when returning from submit report
                      _loadData();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Finalize & Submit Report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.blue),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // Sample data if no reports exist
    final displayReports = _recentReports.isEmpty
        ? [
            {
              'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
              'priority': 'high',
              'title': 'Morning perimeter check - All clear at North',
              'status': 'approved',
              'type': 'voice+image'
            },
            {
              'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
              'priority': 'medium',
              'title': 'Equipment maintenance log - Unit 4 invent',
              'status': 'completed',
              'type': 'image'
            },
            {
              'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
              'priority': 'low',
              'title': 'Shift handover notes for afternoon team...',
              'status': 'under_review',
              'type': 'voice'
            },
          ]
        : _recentReports;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/detailed-report'),
                child: const Text('View Full History →'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date & Time',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    'Summary Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...displayReports.take(5).map((report) {
            return Column(
              children: [
                _buildActivityItem(
                  _formatDateTime(report['created_at']),
                  report['type'] ?? 'text',
                  report['title'] ?? 'Report',
                  report['status'] ?? 'pending',
                ),
                if (displayReports.indexOf(report) < displayReports.take(5).length - 1)
                  const Divider(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${months[date.month - 1]} ${date.day}, ${date.year}\n${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildActivityItem(String date, String type, String summary, String status) {
    Color statusColor = status == 'approved'
        ? Colors.green
        : status == 'completed'
            ? Colors.blue
            : status == 'under_review'
                ? Colors.orange
                : Colors.grey;

    IconData typeIcon = type.contains('voice')
        ? Icons.mic
        : type.contains('image')
            ? Icons.image
            : Icons.description;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(typeIcon, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                if (type.contains('+'))
                  Row(
                    children: [
                      const Icon(Icons.add, size: 12, color: Colors.black54),
                      Icon(
                        type.contains('image') ? Icons.image : Icons.description,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              '"$summary"',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status == 'under_review' ? 'Under Review' : status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String userName, String userEmail) {
    final userId = _userData?['_id'] ?? 'N/A';
    final employeeId = userId.length > 6 ? '#${userId.substring(userId.length - 6)}' : '#000000';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'EMPLOYEE ID: $employeeId',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _buildProfileInfo(Icons.badge, 'Designation', 'Senior Field Technician'),
          const SizedBox(height: 8),
          _buildProfileInfo(Icons.business, 'Department', 'Operations & Safety'),
          const SizedBox(height: 8),
          _buildProfileInfo(Icons.location_on, 'Primary Location', 'North Sector Facility'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/request-leave');
              if (result == true) {
                _loadData();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Request Leave'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/my-leaves');
            },
            icon: const Icon(Icons.history),
            label: const Text('My Leaves'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
              Text(
                text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTasks() {
    final completedTasks = _myTasks.where((task) => task['status'] == 'completed').toList();
    final totalTasks = _myTasks.isEmpty ? 5 : _myTasks.length; // Default to 5 if no tasks
    final completedCount = completedTasks.length;

    // Sample tasks if no real tasks exist
    final displayTasks = _myTasks.isEmpty
        ? [
            {'_id': '1', 'title': 'Morning Safety Briefing', 'time': '08:00 AM', 'status': 'completed', 'priority': 'high'},
            {'_id': '2', 'title': 'Site Perimeter Inspection', 'time': '09:30 AM', 'status': 'completed', 'priority': 'high'},
            {'_id': '3', 'title': 'Equipment Calibration Check', 'time': '11:00 AM', 'status': 'pending', 'priority': 'medium'},
            {'_id': '4', 'title': 'Mid-day Progress Sync', 'time': '01:30 PM', 'status': 'pending', 'priority': 'medium'},
            {'_id': '5', 'title': 'Daily Incident Reporting', 'time': '04:00 PM', 'status': 'pending', 'priority': 'high'},
          ]
        : _myTasks;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'High Priority',
                  style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount/$totalTasks Tasks completed',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ...displayTasks.take(5).map((task) {
            final isCompleted = task['status'] == 'completed';
            final taskId = task['_id'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Checkbox(
                    value: isCompleted,
                    onChanged: (value) async {
                      if (taskId.isNotEmpty && _myTasks.isNotEmpty) {
                        // Update task status in backend
                        final result = await ApiService.updateTask(
                          taskId: taskId,
                          status: value == true ? 'completed' : 'pending',
                        );
                        
                        if (result['success']) {
                          // Reload data to reflect changes
                          _loadData();
                          if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value == true ? 'Task completed!' : 'Task marked as pending'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      } else {
                        // For sample tasks, just show a message
                        if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sample task - no real data to update'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    activeColor: Colors.blue,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] ?? 'Task',
                          style: TextStyle(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.black54 : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (task['time'] != null)
                          Text(
                            task['time'],
                            style: const TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'SHIFT PROGRESS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(completedCount / totalTasks * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completedCount / totalTasks,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Maintenance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'The reporting portal will be offline for 15 mins today at 11:00 PM for a minor security patch.',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

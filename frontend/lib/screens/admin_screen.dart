import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _allReports = [];
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _filterUsers() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          final name = (user['full_name'] ?? '').toLowerCase();
          final email = (user['email'] ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();
          return name.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    final userResult = await ApiService.getCurrentUser();
    final statsResult = await ApiService.getDashboardStats();
    final reportsResult = await ApiService.getReports();
    final usersResult = await ApiService.getUsers();

    if (mounted) {
      setState(() {
        if (userResult['success']) {
          _userData = userResult['data'];
        }
        if (statsResult['success']) {
          _dashboardStats = statsResult['data'];
        }
        if (reportsResult['success']) {
          _allReports = reportsResult['data']['reports'] ?? [];
        }
        if (usersResult['success']) {
          _allUsers = usersResult['data']['users'] ?? [];
          _filteredUsers = _allUsers;
        }
        _isLoading = false;
      });
    }
  }

  void _showAssignTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedUserId = '';
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign New Task'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedUserId.isEmpty ? null : selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Assign To',
                    border: OutlineInputBorder(),
                  ),
                  items: _allUsers.map<DropdownMenuItem<String>>((user) {
                    return DropdownMenuItem<String>(
                      value: user['_id'] as String,
                      child: Text(user['full_name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPriority = value ?? 'medium';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedUserId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                final result = await ApiService.createTask(
                  userId: selectedUserId,
                  title: titleController.text,
                  description: descriptionController.text,
                  priority: selectedPriority,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task assigned successfully!')),
                    );
                    _loadData(); // Reload data
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${result['error']}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Assign Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDialog() {
    final messageController = TextEditingController();
    String selectedPriority = 'normal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Broadcast Message'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a message to all employees',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Enter your broadcast message...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'important', child: Text('Important')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedPriority = value ?? 'normal';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a message')),
                  );
                  return;
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Broadcasting message to ${_allUsers.length} employees...',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select export format:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV Format'),
              subtitle: const Text('Compatible with Excel and Google Sheets'),
              onTap: () {
                Navigator.pop(context);
                _performExport('CSV');
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON Format'),
              subtitle: const Text('For developers and API integration'),
              onTap: () {
                Navigator.pop(context);
                _performExport('JSON');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Report'),
              subtitle: const Text('Formatted document for printing'),
              onTap: () {
                Navigator.pop(context);
                _performExport('PDF');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performExport(String format) async {
    if (format != 'CSV') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$format export is not yet implemented. Please use CSV.')),
      );
      return;
    }

    final Map<String, String> exportTypes = {
      'Reports': 'reports',
      'Leaves': 'leaves',
      'Tasks': 'tasks',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Content to Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: exportTypes.keys.map((type) {
            return ListTile(
              title: Text(type),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse(ApiService.getExportUrl(exportTypes[type]!));
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading $type export...')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not trigger download. Check browser settings.')),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = _userData?['full_name'] ?? 'Admin';
    final totalUsers = _dashboardStats?['total_users'] ?? 0;
    final totalReports = _dashboardStats?['total_reports'] ?? 0;
    final totalTasks = _dashboardStats?['total_tasks'] ?? 0;
    final pendingReports = _dashboardStats?['pending_reports'] ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Stay on admin dashboard, don't go back
        
      },child: Scaffold(
        body: Row(
          children: [
            const Sidebar(currentRoute: '/admin'),
            Expanded(
              child: Column(
                children: [
                  TopBar(userName: userName, userRole: 'Admin'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Control Center',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Monitor organization-wide reporting activity and performance metrics.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Total Reports Today', totalReports.toString(), '+12% from yesterday', Colors.blue)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildStatCard('Pending Approvals', pendingReports.toString(), '$pendingReports items flagged', Colors.red)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildStatCard('Total Tasks', totalTasks.toString(), 'All systems operational', Colors.green)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildStatCard('Active Employees', totalUsers.toString(), 'All systems operational', Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildSearchAndFilters(),
                          const SizedBox(height: 30),
                          _buildEmployeeActivity(),
                          const SizedBox(height: 30),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildRecentDepartmentUpdates(),
                              ),
                              const SizedBox(width: 30),
                              Expanded(
                                child: _buildQuickInsights(),
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

  Widget _buildStatCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search employees or departments...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterUsers();
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list),
          label: const Text('Filters'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.calendar_today),
          label: const Text('Oct 24, 2024'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _showBroadcastDialog,
          icon: const Icon(Icons.campaign),
          label: const Text('Broadcast'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _showAssignTaskDialog,
          icon: const Icon(Icons.add),
          label: const Text('Assign Task'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeActivity() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final paginatedUsers = _filteredUsers.length > startIndex
        ? _filteredUsers.sublist(
            startIndex,
            endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
          )
        : [];
    final totalPages = (_filteredUsers.length / _itemsPerPage).ceil();

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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employee Activity Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real-time log of report submissions and status updates.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Export Data'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_filteredUsers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No users found', style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                    columns: const [
                      DataColumn(label: Text('Employee', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Last Report', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: paginatedUsers.map((user) {
                      // Find user's latest report
                      final userReports = _allReports.where((r) => r['user_id'] == user['_id']).toList();
                      final latestReport = userReports.isNotEmpty ? userReports.first : null;
                      final reportStatus = latestReport?['status'] ?? 'No reports';
                      final reportTime = latestReport != null ? _formatTime(latestReport['created_at']) : '-';

                      return DataRow(cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  (user['full_name'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    user['full_name'] ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    user['email'] ?? 'N/A',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(user['role'] == 'admin' ? 'Administration' : 'Operations')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: reportStatus == 'completed' || reportStatus == 'approved'
                                  ? Colors.green.shade100
                                  : reportStatus == 'pending'
                                      ? Colors.orange.shade100
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              reportStatus == 'No reports' ? 'Waiting...' : reportStatus,
                              style: TextStyle(
                                color: reportStatus == 'completed' || reportStatus == 'approved'
                                    ? Colors.green
                                    : reportStatus == 'pending'
                                        ? Colors.orange
                                        : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(reportTime, style: const TextStyle(fontWeight: FontWeight.w500)),
                              const Text('TODAY', style: TextStyle(fontSize: 10, color: Colors.black54)),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/report-detail',
                                    arguments: user['_id'],
                                  );
                                },
                                child: const Text('View Detail'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_horiz),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1} to ${endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex} of ${_filteredUsers.length} employees',
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                          child: const Text('Previous'),
                        ),
                        ...List.generate(
                          totalPages > 3 ? 3 : totalPages,
                          (index) => TextButton(
                            onPressed: () => setState(() => _currentPage = index + 1),
                            style: TextButton.styleFrom(
                              backgroundColor: _currentPage == index + 1
                                  ? Colors.blue
                                  : Colors.transparent,
                              foregroundColor: _currentPage == index + 1
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            child: Text('${index + 1}'),
                          ),
                        ),
                        TextButton(
                          onPressed: _currentPage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return '-';
    }
  }

  Widget _buildRecentDepartmentUpdates() {
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
          const Text(
            'Recent Department Updates',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildDepartmentUpdate(
            'Engineering Sync',
            'Architecture review reports for Project Titan have been fully completed.',
            '2h ago',
            Icons.engineering,
          ),
          const Divider(height: 30),
          _buildDepartmentUpdate(
            'Marketing Campaign',
            'Low reporting rate detected in European regions for current sprint.',
            '4h ago',
            Icons.campaign,
          ),
          const Divider(height: 30),
          _buildDepartmentUpdate(
            'System Maintenance',
            'Voice-to-text processing node #4 is undergoing scheduled restart.',
            '6h ago',
            Icons.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentUpdate(String title, String description, String time, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInsights() {
    final completionRate = _allReports.isEmpty
        ? 0.0
        : (_allReports.where((r) => r['status'] == 'completed' || r['status'] == 'approved').length /
                _allReports.length) *
            100;

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
          const Text(
            'Quick Insights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Reporting Compliance',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${completionRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionRate / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          const Text(
            'Organization-wide target: 95%',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ADMIN TIP',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enable "Auto-Approve" for recurring task reports to reduce your review queue by 30%.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Update Settings →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

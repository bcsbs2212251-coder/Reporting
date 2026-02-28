import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class UnifiedAdminScreen extends StatefulWidget {
  const UnifiedAdminScreen({super.key});

  @override
  State<UnifiedAdminScreen> createState() => _UnifiedAdminScreenState();
}

class _UnifiedAdminScreenState extends State<UnifiedAdminScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _reports = [];
  List<dynamic> _users = [];
  List<dynamic> _tasks = [];
  List<dynamic> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userResult = await ApiService.getCurrentUser();
      final statsResult = await ApiService.getDashboardStats();
      final reportsResult = await ApiService.getReports();
      final usersResult = await ApiService.getUsers();
      final tasksResult = await ApiService.getTasks();
      final leavesResult = await ApiService.getAllLeaves();

      if (mounted) {
        setState(() {
          if (userResult['success']) _userData = userResult['data'];
          if (statsResult['success']) _dashboardStats = statsResult['data'];
          if (reportsResult['success']) _reports = reportsResult['data']['reports'] ?? [];
          if (usersResult['success']) _users = usersResult['data']['users'] ?? [];
          if (tasksResult['success']) _tasks = tasksResult['data']['tasks'] ?? [];
          _leaves = leavesResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
            PopupMenuButton(
              icon: const Icon(Icons.account_circle),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Sign Out'),
                  onTap: () async {
                    await ApiService.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.description), text: 'Reports'),
              Tab(icon: Icon(Icons.task), text: 'Tasks'),
              Tab(icon: Icon(Icons.event_available), text: 'Leaves'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildReportsTab(),
                  _buildTasksTab(),
                  _buildLeavesTab(),
                  _buildUsersTab(),
                  _buildAnalyticsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalReports = _dashboardStats?['total_reports'] ?? 0;
    final pendingReports = _dashboardStats?['pending_reports'] ?? 0;
    final totalUsers = _dashboardStats?['total_users'] ?? 0;
    final totalTasks = _dashboardStats?['total_tasks'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${_userData?['full_name'] ?? 'Admin'}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Stats Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Reports', totalReports.toString(), Icons.description, Colors.blue),
              _buildStatCard('Pending Reports', pendingReports.toString(), Icons.pending, Colors.orange),
              _buildStatCard('Total Users', totalUsers.toString(), Icons.people, Colors.green),
              _buildStatCard('Total Tasks', totalTasks.toString(), Icons.task, Colors.purple),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Recent Activity
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reports.take(5).length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final report = _reports[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.description, color: Colors.blue),
                  ),
                  title: Text(report['title'] ?? 'No Title'),
                  subtitle: Text('By ${report['user_name'] ?? 'Unknown'}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report['status']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (report['status'] ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(report['status']),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reports.length,
            itemBuilder: (context, index) {
              final report = _reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(report['status']).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.description,
                      color: _getStatusColor(report['status']),
                    ),
                  ),
                  title: Text(report['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('By: ${report['user_name'] ?? 'Unknown'}'),
                      Text('Priority: ${report['priority'] ?? 'medium'}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report['status']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (report['status'] ?? 'pending').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(report['status']),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _showReportDialog(report);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Task Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAssignTaskDialog,
                icon: const Icon(Icons.add),
                label: const Text('Assign Task'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(task['status']).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.task,
                      color: _getStatusColor(task['status']),
                    ),
                  ),
                  title: Text(task['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned to: ${task['user_name'] ?? 'Unknown'}'),
                      Text('Priority: ${task['priority'] ?? 'medium'}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task['status']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (task['status'] ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(task['status']),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeavesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leaves.length,
            itemBuilder: (context, index) {
              final leave = _leaves[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(leave['status']).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.event_available,
                      color: _getStatusColor(leave['status']),
                    ),
                  ),
                  title: Text('${leave['user_name']} - ${leave['leave_type']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason: ${leave['reason']}'),
                      Text('Date: ${leave['start_date']}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(leave['status']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (leave['status'] ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(leave['status']),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    _showLeaveActionDialog(leave);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ========== NEW USERS TAB ==========
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Users (${_users.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final role = (user['role'] ?? 'employee').toString();
              final isAdmin = role.toLowerCase() == 'admin';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.purple[100] : Colors.blue[100],
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin ? Colors.purple : Colors.blue,
                    ),
                  ),
                  title: Text(
                    user['full_name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? ''),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.purple[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAdmin ? Colors.purple : Colors.blue,
                              ),
                            ),
                          ),
                          if (user['department'] != null && user['department'].toString().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              user['department'],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showUserDetailsDialog(user),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(user['full_name'] ?? 'Unknown')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.email, 'Email', user['email'] ?? 'N/A'),
            _buildDetailRow(Icons.badge, 'Role', (user['role'] ?? 'employee').toString().toUpperCase()),
            _buildDetailRow(Icons.business, 'Department', user['department'] ?? 'Not set'),
            _buildDetailRow(Icons.location_on, 'Location', user['location'] ?? 'Not set'),
            _buildDetailRow(Icons.phone, 'Phone', user['phone'] ?? 'Not set'),
            _buildDetailRow(Icons.calendar_today, 'Joined', _formatCreatedAt(user['created_at'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCreatedAt(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics & Reports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Export Options
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              _buildExportCard('Export Reports', Icons.description, Colors.blue),
              _buildExportCard('Export Tasks', Icons.task, Colors.green),
              _buildExportCard('Export Leaves', Icons.event_available, Colors.orange),
              _buildExportCard('Export Users', Icons.people, Colors.purple),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Quick Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Statistics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total Reports', _reports.length.toString()),
                _buildStatRow('Pending Reports', _reports.where((r) => r['status'] == 'pending').length.toString()),
                _buildStatRow('Total Tasks', _tasks.length.toString()),
                _buildStatRow('Pending Tasks', _tasks.where((t) => t['status'] == 'pending').length.toString()),
                _buildStatRow('Total Leaves', _leaves.length.toString()),
                _buildStatRow('Pending Leaves', _leaves.where((l) => l['status'] == 'pending').length.toString()),
                _buildStatRow('Total Users', _users.length.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        final type = title.split(' ').last.toLowerCase(); // 'reports', 'tasks', 'leaves', 'users'
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Export $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.green),
                  title: const Text('Export as CSV'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleExport(type, 'csv');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleExport(type, 'pdf');
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(String type, String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preparing $type export ($format)...')),
    );

    try {
      final url = ApiService.getExportUrl(type, format: format);
      final fileName = '${type}_export_${DateTime.now().millisecondsSinceEpoch}.$format';
      await ApiService.downloadFile(url, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported $type as $format — saved as $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showReportDialog(dynamic report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title'] ?? 'Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${report['description'] ?? 'No description'}'),
            const SizedBox(height: 8),
            Text('Priority: ${report['priority'] ?? 'medium'}'),
            Text('Status: ${report['status'] ?? 'pending'}'),
            Text('Submitted by: ${report['user_name'] ?? 'Unknown'}'),
            if (report['attachments'] != null && (report['attachments'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (report['attachments'] as List).length,
                  itemBuilder: (context, i) {
                    final url = report['attachments'][i];
                    final isImage = url.toLowerCase().contains('.jpg') || 
                                    url.toLowerCase().contains('.png') || 
                                    url.toLowerCase().contains('.jpeg');
                    return GestureDetector(
                      onTap: () => _viewAttachment(url),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          image: isImage ? DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: !isImage ? const Icon(Icons.insert_drive_file, color: Colors.blue) : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (report['status'] == 'pending') ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.updateReport(
                  reportId: report['_id'],
                  status: 'approved',
                );
                if (!mounted) return;
                _loadData();
              },
              child: const Text('Approve'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.updateReport(
                  reportId: report['_id'],
                  status: 'rejected',
                );
                if (!mounted) return;
                _loadData();
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedUserId = '';
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign New Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Assign to User'),
                items: _users.map<DropdownMenuItem<String>>((user) {
                  return DropdownMenuItem<String>(
                    value: user['_id'],
                    child: Text(user['full_name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedUserId = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['low', 'medium', 'high'].map<DropdownMenuItem<String>>((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedPriority = value ?? 'medium';
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
              if (titleController.text.isNotEmpty && selectedUserId.isNotEmpty) {
                Navigator.pop(context);
                await ApiService.createTask(
                  userId: selectedUserId,
                  title: titleController.text,
                  description: descriptionController.text,
                  priority: selectedPriority,
                );
                if (!mounted) return;
                _loadData();
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showLeaveActionDialog(dynamic leave) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${leave['user_name']}'),
            Text('Type: ${leave['leave_type']}'),
            Text('Reason: ${leave['reason']}'),
            Text('Date: ${leave['start_date']}${leave['end_date'] != null ? ' to ${leave['end_date']}' : ''}'),
            const SizedBox(height: 16),
            if (leave['voice_note_url'] != null || leave['attachment_url'] != null) ...[
              const Text('Multimedia:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (leave['voice_note_url'] != null)
                    ElevatedButton.icon(
                      onPressed: () => _playVoiceNote(leave['voice_note_url']),
                      icon: const Icon(Icons.play_circle_fill, size: 18),
                      label: const Text('Voice Note', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  if (leave['voice_note_url'] != null && leave['attachment_url'] != null)
                    const SizedBox(width: 8),
                  if (leave['attachment_url'] != null)
                    OutlinedButton.icon(
                      onPressed: () => _viewAttachment(leave['attachment_url']),
                      icon: const Icon(Icons.attach_file, size: 14),
                      label: const Text('Attachment', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (leave['status'] == 'pending') ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.updateLeaveStatus(
                  leave['_id'],
                  'rejected',
                  commentController.text.isEmpty ? null : commentController.text,
                );
                _loadData();
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.updateLeaveStatus(
                  leave['_id'],
                  'approved',
                  commentController.text.isEmpty ? null : commentController.text,
                );
                _loadData();
              },
              child: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  void _viewAttachment(String url) {
    final isImage = url.toLowerCase().contains('.jpg') || 
                    url.toLowerCase().contains('.png') || 
                    url.toLowerCase().contains('.jpeg');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url, 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(40),
                child: Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isImage ? 'Image Attachment' : 'File Attachment',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _playVoiceNote(String url) {
    final player = AudioPlayer();
    bool isPlaying = false;
    bool isPaused = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          player.onPlayerComplete.listen((_) {
            if (mounted) {
              setState(() {
                isPlaying = false;
                isPaused = false;
              });
            }
          });
          
          return AlertDialog(
            title: const Text('Voice Note'),
            content: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, 
                    size: 48, 
                    color: Colors.blue,
                  ),
                  onPressed: () async {
                    if (isPlaying) {
                      await player.pause();
                      setState(() {
                        isPlaying = false;
                        isPaused = true;
                      });
                    } else if (isPaused) {
                      await player.resume();
                      setState(() {
                        isPlaying = true;
                        isPaused = false;
                      });
                    } else {
                      await player.play(UrlSource(url));
                      setState(() {
                        isPlaying = true;
                        isPaused = false;
                      });
                    }
                  },
                ),
                if (isPlaying || isPaused)
                  IconButton(
                    icon: const Icon(Icons.stop_circle, size: 48, color: Colors.red),
                    onPressed: () async {
                      await player.stop();
                      setState(() {
                        isPlaying = false;
                        isPaused = false;
                      });
                    },
                  ),
                const Expanded(
                  child: Text('Click to listen to the recorded message'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  player.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          );
        }
      ),
    );
  }
}

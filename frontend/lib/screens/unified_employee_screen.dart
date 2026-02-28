import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import 'improved_submit_report_dialog.dart';
import 'report_detail_screen.dart';

class UnifiedEmployeeScreen extends StatefulWidget {
  const UnifiedEmployeeScreen({super.key});

  @override
  State<UnifiedEmployeeScreen> createState() => _UnifiedEmployeeScreenState();
}

class _UnifiedEmployeeScreenState extends State<UnifiedEmployeeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userData;
  List<dynamic> _myReports = [];
  List<dynamic> _myTasks = [];
  List<dynamic> _myLeaves = [];
  bool _isLoading = true;
  double _shiftProgress = 0.4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _calculateShiftProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateShiftProgress() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 8, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 18, 0);
    
    if (now.isAfter(startOfDay) && now.isBefore(endOfDay)) {
      final elapsed = now.difference(startOfDay).inMinutes;
      final total = endOfDay.difference(startOfDay).inMinutes;
      setState(() {
        _shiftProgress = elapsed / total;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userResult = await ApiService.getCurrentUser();
      final reportsResult = await ApiService.getReports();
      final tasksResult = await ApiService.getTasks();
      final leavesResult = await ApiService.getMyLeaves();

      if (mounted) {
        setState(() {
          if (userResult['success']) _userData = userResult['data'];
          if (reportsResult['success']) _myReports = reportsResult['data']['reports'] ?? [];
          if (tasksResult['success']) _myTasks = tasksResult['data']['tasks'] ?? [];
          _myLeaves = leavesResult;
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
          title: const Text('Employee Dashboard'),
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
                  child: const Text('Edit Profile'),
                  onTap: () {
                    Navigator.pushNamed(context, '/edit-profile');
                  },
                ),
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
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.description), text: 'My Reports'),
              Tab(icon: Icon(Icons.task), text: 'My Tasks'),
              Tab(icon: Icon(Icons.event_available), text: 'My Leaves'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildReportsTab(),
                  _buildTasksTab(),
                  _buildLeavesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    final userName = _userData?['full_name'] ?? 'Employee';
    final employeeId = _userData?['_id']?.substring(0, 8).toUpperCase() ?? 'EMP001';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $userName',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Employee ID: $employeeId',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildActionCard(
                'Submit Report',
                Icons.add_circle,
                Colors.blue,
                () => ImprovedSubmitReportDialog.show(context, _loadData),
              ),
              _buildActionCard(
                'Request Leave',
                Icons.event_available,
                Colors.green,
                () => _showRequestLeaveDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Shift Progress
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shift Progress',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(_shiftProgress * 100).toInt()}% Done',
                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _shiftProgress,
                      minHeight: 12,
                      backgroundColor: Colors.blue[50],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Standard Shift: 08:00 AM - 06:00 PM',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity Summary
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'My Reports',
                  _myReports.length.toString(),
                  Icons.description,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'My Tasks',
                  _myTasks.length.toString(),
                  Icons.task,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => ImprovedSubmitReportDialog.show(context, _loadData),
                icon: const Icon(Icons.add),
                label: const Text('New Report'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _myReports.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No reports yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _myReports.length,
                  itemBuilder: (context, index) {
                    final report = _myReports[index];
                    final attachments = report['attachments'] ?? [];
                    
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDetailScreen(reportId: report['_id']),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  report['title'] ?? 'No Title',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
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
                            const SizedBox(height: 8),
                            Text(report['description'] ?? '', style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.priority_high, size: 14, color: Colors.grey),
                                Text(' ${report['priority'] ?? 'medium'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                Text(' ${_formatDate(report['created_at'])}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            if (attachments.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('Attachments:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 60,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: attachments.length,
                                  itemBuilder: (context, i) {
                                    final url = attachments[i];
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
                      ),
                    ),
                  );
                },
                ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: const Row(
            children: [
              Text(
                'My Tasks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: _myTasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No tasks assigned', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _myTasks.length,
                  itemBuilder: (context, index) {
                    final task = _myTasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Checkbox(
                          value: task['status'] == 'completed',
                          onChanged: (value) async {
                            final newStatus = value == true ? 'completed' : 'pending';
                            try {
                              await ApiService.updateTask(
                                taskId: task['_id'],
                                status: newStatus,
                              );
                              if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Task marked as $newStatus')),
                              );
                              _loadData();
                            } catch (e) {
                              if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                        ),
                        title: Text(task['title'] ?? 'No Title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task['description'] != null && task['description'].isNotEmpty)
                              Text(task['description']),
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
        ),
      ],
    );
  }

  Widget _buildLeavesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Leaves',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRequestLeaveDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Request Leave'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _myLeaves.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No leave requests', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _myLeaves.length,
                  itemBuilder: (context, index) {
                    final leave = _myLeaves[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  leave['leave_type'] ?? 'Leave',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
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
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Reason: ${leave['reason'] ?? 'No reason'}'),
                            Text('Date: ${leave['start_date'] ?? 'No date'}${leave['end_date'] != null ? ' to ${leave['end_date']}' : ''}'),
                            if (leave['voice_note_url'] != null || leave['attachment_url'] != null) ...[
                              const SizedBox(height: 12),
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
                            ],
                            if (leave['admin_comment'] != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Admin Comment:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Text(leave['admin_comment']),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
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
              Image.network(url, fit: BoxFit.contain)
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
        builder: (context, setDialogState) {
          player.onPlayerComplete.listen((_) {
            if (mounted) {
              setDialogState(() {
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
                  icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 48, color: Colors.blue),
                  onPressed: () async {
                    if (isPlaying) {
                      await player.pause();
                      setDialogState(() {
                        isPlaying = false;
                        isPaused = true;
                      });
                    } else {
                      if (isPaused) {
                        await player.resume();
                      } else {
                        await player.play(UrlSource(url));
                      }
                      setDialogState(() {
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
                      setDialogState(() {
                        isPlaying = false;
                        isPaused = false;
                      });
                    },
                  ),
                const Expanded(
                  child: Text('Listen to the recorded message'),
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

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showSubmitReportDialog() {
    ImprovedSubmitReportDialog.show(context, () => _loadData());
  }

  void _showRequestLeaveDialog() {
    String selectedLeaveType = 'full day';
    String? selectedReason;
    DateTime? startDate;
    DateTime? endDate;
    
    // Voice recording state
    final AudioRecorder audioRecorder = AudioRecorder();
    final AudioPlayer audioPlayer = AudioPlayer();
    String? recordedPath;
    bool isRecording = false;
    bool isPaused = false;
    bool isPlaying = false;
    bool isPlaybackPaused = false;
    
    // Attachment state
    PlatformFile? attachedFile;
    bool isSubmitting = false;

    void showPreview(PlatformFile file) {
      final isImage = file.name.toLowerCase().endsWith('.jpg') ||
          file.name.toLowerCase().endsWith('.jpeg') ||
          file.name.toLowerCase().endsWith('.png');

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('Preview: ${file.name}'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      isImage ? Icons.image : Icons.insert_drive_file,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      file.name,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(file.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          Future<void> startRecording() async {
            if (kIsWeb) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice recording is not supported on web. Please use the mobile app.')),
              );
              return;
            }
            try {
              if (await audioRecorder.hasPermission()) {
                final directory = await getApplicationDocumentsDirectory();
                final path = '${directory.path}/leave_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
                
                await audioRecorder.start(const RecordConfig(), path: path);
                setDialogState(() {
                  isRecording = true;
                  isPaused = false;
                  recordedPath = null;
                });
              }
            } catch (e) {
              debugPrint('Error starting recording: $e');
            }
          }

          Future<void> pauseRecording() async {
            await audioRecorder.pause();
            setDialogState(() => isPaused = true);
          }

          Future<void> resumeRecording() async {
            await audioRecorder.resume();
            setDialogState(() => isPaused = false);
          }

          Future<void> stopRecording() async {
            try {
              final path = await audioRecorder.stop();
              setDialogState(() {
                isRecording = false;
                isPaused = false;
                recordedPath = path;
              });
            } catch (e) {
              debugPrint('Error stopping recording: $e');
            }
          }

          Future<void> playRecording() async {
            if (recordedPath != null) {
              try {
                if (isPlaybackPaused) {
                  await audioPlayer.resume();
                  setDialogState(() {
                    isPlaying = true;
                    isPlaybackPaused = false;
                  });
                } else {
                  await audioPlayer.play(DeviceFileSource(recordedPath!));
                  setDialogState(() {
                    isPlaying = true;
                    isPlaybackPaused = false;
                  });
                  audioPlayer.onPlayerComplete.listen((_) {
                    if (context.mounted) {
                      setDialogState(() {
                        isPlaying = false;
                        isPlaybackPaused = false;
                      });
                    }
                  });
                }
              } catch (e) {
                debugPrint('Error playing recording: $e');
              }
            }
          }

          Future<void> pausePlayback() async {
            await audioPlayer.pause();
            setDialogState(() {
              isPlaying = false;
              isPlaybackPaused = true;
            });
          }

          Future<void> stopPlayback() async {
            await audioPlayer.stop();
            setDialogState(() {
              isPlaying = false;
              isPlaybackPaused = false;
            });
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Request Leave',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leave Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedLeaveType,
                    decoration: const InputDecoration(labelText: 'Leave Type'),
                    items: [
                      'half day morning',
                      'half day afternoon',
                      'full day',
                      'Annual Leave',
                      'Work from Home',
                      'Work At site'
                    ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (v) => setDialogState(() => selectedLeaveType = v!),
                  ),
                  const SizedBox(height: 16),
                  
                  // Reason Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: [
                      'University class',
                      'Personal Work',
                      'Sick Leave',
                      'Site Deployment'
                    ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDialogState(() => selectedReason = v),
                  ),
                  const SizedBox(height: 16),
                  
                  // Start Date
                  const Text('Start Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate != null && startDate!.isBefore(today) ? today : (startDate ?? today),
                        firstDate: today,
                        lastDate: DateTime(2026, 12, 31),
                      );
                      if (date != null) {
                        setDialogState(() => startDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            startDate == null ? 'Select start date' : DateFormat('MMM dd, yyyy').format(startDate!),
                            style: TextStyle(color: startDate == null ? Colors.grey[600] : Colors.black),
                          ),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // End Date
                  const Text('End Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate ?? today,
                        firstDate: startDate ?? today,
                        lastDate: DateTime(2026, 12, 31),
                      );
                      if (date != null) {
                        setDialogState(() => endDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            endDate == null ? 'Select end date' : DateFormat('MMM dd, yyyy').format(endDate!),
                            style: TextStyle(color: endDate == null ? Colors.grey[600] : Colors.black),
                          ),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Voice Recording Section
                  const Text('Voice Note', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        if (!isRecording && recordedPath == null)
                          ElevatedButton.icon(
                            onPressed: startRecording,
                            icon: const Icon(Icons.mic, size: 20),
                            label: const Text('Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (isRecording) ...[
                          Icon(isPaused ? Icons.pause_circle_filled : Icons.fiber_manual_record, 
                               color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            isPaused ? 'Recording Paused' : 'Recording...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                            onPressed: isPaused ? resumeRecording : pauseRecording,
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop),
                            onPressed: stopRecording,
                          ),
                        ],
                        if (recordedPath != null && !isRecording) ...[
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_circle : Icons.play_circle,
                              size: 32,
                              color: Colors.blue,
                            ),
                            onPressed: isPlaying ? pausePlayback : playRecording,
                          ),
                          if (isPlaybackPaused || isPlaying)
                            IconButton(
                              icon: const Icon(Icons.stop_circle, color: Colors.orange),
                              onPressed: stopPlayback,
                            ),
                          const Expanded(
                            child: Text('Voice note recorded ✓', style: TextStyle(fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setDialogState(() {
                              recordedPath = null;
                              isPlaying = false;
                              isPlaybackPaused = false;
                              audioPlayer.stop();
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Attachment Section
                  const Text('Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (attachedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Chip(
                              label: Text(attachedFile!.name),
                              onDeleted: () => setDialogState(() => attachedFile = null),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => showPreview(attachedFile!),
                            tooltip: 'Preview',
                          ),
                        ],
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.any);
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() => attachedFile = result.files.single);
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add Document/Image'),
                  ),
                  
                  if (isSubmitting)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (startDate == null || selectedReason == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                    return;
                  }
                  
                  setDialogState(() => isSubmitting = true);
                  
                  try {
                    String? voiceUrl;
                    String? attachmentUrl;
                    
                    if (recordedPath != null) {
                      voiceUrl = await ApiService.uploadFile(recordedPath!);
                    }
                    if (attachedFile != null && attachedFile!.path != null) {
                      attachmentUrl = await ApiService.uploadFile(attachedFile!.path!);
                    }
                    
                    await ApiService.createLeave({
                      'leave_type': selectedLeaveType,
                      'reason': selectedReason,
                      'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
                      'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
                      'voice_note_url': voiceUrl,
                      'attachment_url': attachmentUrl,
                    });
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted')));
                    _loadData();
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Submit'),
              ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      audioRecorder.dispose();
      audioPlayer.dispose();
    });
  }
}
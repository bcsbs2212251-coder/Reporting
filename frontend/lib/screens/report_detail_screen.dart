import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentlyPlayingUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reportsResult = await ApiService.getReports();
      
      if (mounted) {
        if (reportsResult['success']) {
          final reports = reportsResult['data']['reports'] as List;
          _report = reports.firstWhere(
            (r) => r['_id'] == widget.reportId,
            orElse: () => null,
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playVoiceNote(String url) async {
    try {
      if (_isPlaying && _currentlyPlayingUrl == url) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
          _isPaused = true;
        });
      } else if (_isPaused && _currentlyPlayingUrl == url) {
        await _audioPlayer.resume();
        setState(() {
          _isPlaying = true;
          _isPaused = false;
        });
      } else {
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _isPlaying = true;
          _isPaused = false;
          _currentlyPlayingUrl = url;
        });
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _isPaused = false;
              _currentlyPlayingUrl = null;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _isPaused = false;
        _currentlyPlayingUrl = null;
      });
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Not Found')),
        body: const Center(child: Text('Could not find the requested report.')),
      );
    }

    final createdAt = _report!['created_at'];
    final formattedDate = createdAt != null 
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(createdAt))
        : 'Unknown Date';
    final status = (_report!['status'] ?? 'pending').toString().toUpperCase();
    final priority = (_report!['priority'] ?? 'medium').toString().toUpperCase();
    final category = (_report!['category'] ?? 'general').toString().toUpperCase();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_report!['title'] ?? 'Report Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Meta Info
            Row(
              children: [
                _buildStatusChip(status),
                const SizedBox(width: 8),
                _buildPriorityChip(priority),
                const SizedBox(width: 8),
                _buildCategoryChip(category),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formattedDate,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const Divider(height: 32),

            // Description Section
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                _report!['description'] ?? 'No description provided.',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // Voice Notes Section
            if (_report!['voice_notes'] != null && (_report!['voice_notes'] as List).isNotEmpty) ...[
              const Text(
                'Voice Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...(_report!['voice_notes'] as List).map((url) => _buildVoiceNoteTile(url)),
              const SizedBox(height: 24),
            ],

            // Attachments Section
            if (_report!['attachments'] != null && (_report!['attachments'] as List).isNotEmpty) ...[
              const Text(
                'Attachments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAttachmentsGallery(_report!['attachments'] as List),
              const SizedBox(height: 24),
            ],

            // Admin Feedback Section
            if (_report!['admin_feedback'] != null && _report!['admin_feedback'].toString().isNotEmpty) ...[
              const Text(
                'Admin Feedback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Text(
                  _report!['admin_feedback'],
                  style: TextStyle(color: Colors.blue[900], fontSize: 15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'APPROVED' || status == 'COMPLETED') color = Colors.green;
    if (status == 'REJECTED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color = priority == 'HIGH' ? Colors.red : (priority == 'MEDIUM' ? Colors.orange : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildVoiceNoteTile(String url) {
    bool isThisPlaying = _isPlaying && _currentlyPlayingUrl == url;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
            color: Colors.blue,
            iconSize: 40,
            onPressed: () => _playVoiceNote(url),
          ),
          if (_currentlyPlayingUrl == url)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              color: Colors.red,
              iconSize: 40,
              onPressed: _stopPlayback,
            ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Note', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Click to listen', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsGallery(List attachments) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final url = attachments[index].toString();
        final isImage = url.toLowerCase().contains('.jpg') || 
                        url.toLowerCase().contains('.png') || 
                        url.toLowerCase().contains('.jpeg');

        return GestureDetector(
          onTap: () => _viewAttachment(url),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              image: isImage ? DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: !isImage ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insert_drive_file, color: Colors.blue, size: 32),
                  SizedBox(height: 8),
                  Text('Document', style: TextStyle(fontSize: 12)),
                ],
              ),
            ) : null,
          ),
        );
      },
    );
  }

  void _viewAttachment(String url) {
    final isImage = url.toLowerCase().contains('.jpg') || 
                    url.toLowerCase().contains('.png') || 
                    url.toLowerCase().contains('.jpeg');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Attachment'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isImage
                  ? Image.network(url, fit: BoxFit.contain)
                  : const Column(
                      children: [
                        Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
                        SizedBox(height: 16),
                        Text('Generic File Attachment'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

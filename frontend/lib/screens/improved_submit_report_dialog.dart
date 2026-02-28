import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class ImprovedSubmitReportDialog {
  static void show(BuildContext context, VoidCallback onSuccess) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'medium';
    String selectedCategory = 'general';
    List<PlatformFile> selectedFiles = [];
    bool isUploading = false;
    
    // Voice recording state
    final AudioRecorder audioRecorder = AudioRecorder();
    final AudioPlayer audioPlayer = AudioPlayer();
    String? recordedPath;
    bool isRecording = false;
    bool isPaused = false;
    bool isPlaying = false;
    bool isPlaybackPaused = false;
    int recordingDuration = 0;
    
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
                final path = '${directory.path}/report_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
                
                await audioRecorder.start(const RecordConfig(), path: path);
                setDialogState(() {
                  isRecording = true;
                  isPaused = false;
                  recordedPath = null;
                  recordingDuration = 0;
                });
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Microphone permission required')),
                  );
                }
              }
            } catch (e) {
              debugPrint('Error starting recording: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Recording not available: $e')),
                );
              }
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
                      child: isImage && file.path != null
                          ? Image.network(
                              file.path!,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Column(
                                children: [
                                  const Icon(Icons.image, size: 64, color: Colors.blue),
                                  const SizedBox(height: 8),
                                  Text(file.name),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Icon(
                                  _getFileIcon(file.name),
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
          
          return Stack(
            children: [
              Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Submit New Report',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: isUploading ? null : () {
                              audioRecorder.dispose();
                              audioPlayer.dispose();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // Scrollable content
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Report Title *',
                                  hintText: 'e.g., Equipment Malfunction',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description *',
                                  hintText: 'Provide details about the issue...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 4,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedPriority,
                                      decoration: const InputDecoration(
                                        labelText: 'Priority',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: ['low', 'medium', 'high'].map((priority) {
                                        return DropdownMenuItem<String>(
                                          value: priority,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.flag,
                                                size: 16,
                                                color: priority == 'high'
                                                    ? Colors.red
                                                    : priority == 'medium'
                                                        ? Colors.orange
                                                        : Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(priority.toUpperCase()),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedPriority = value ?? 'medium';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedCategory,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: ['general', 'technical', 'maintenance', 'safety', 'other']
                                          .map((category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(category.toUpperCase()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedCategory = value ?? 'general';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 12),
                              
                              // Voice Recording Section
                              const Text(
                                '🎤 Voice Note (Optional)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
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
                                        label: Text(kIsWeb ? 'Record (Mobile Only)' : 'Record'),
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
                                        isPaused 
                                          ? 'Paused ${recordingDuration ~/ 60}:${(recordingDuration % 60).toString().padLeft(2, '0')}'
                                          : 'Recording... ${recordingDuration ~/ 60}:${(recordingDuration % 60).toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                                        onPressed: isPaused ? resumeRecording : pauseRecording,
                                        tooltip: isPaused ? 'Resume' : 'Pause',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.stop, color: Colors.red),
                                        onPressed: stopRecording,
                                        tooltip: 'Stop',
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
                                        tooltip: isPlaying ? 'Pause' : 'Play',
                                      ),
                                      if (isPlaybackPaused || isPlaying)
                                        IconButton(
                                          icon: const Icon(Icons.stop_circle, color: Colors.orange),
                                          onPressed: stopPlayback,
                                          tooltip: 'Stop',
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
                                        tooltip: 'Delete recording',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Attachments Section
                              const Text(
                                '📎 Attachments (Optional)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              if (selectedFiles.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: selectedFiles.map((file) {
                                      final isImage = file.name.toLowerCase().endsWith('.jpg') ||
                                          file.name.toLowerCase().endsWith('.jpeg') ||
                                          file.name.toLowerCase().endsWith('.png');
                                      
                                      return InkWell(
                                        onTap: () => showPreview(file),
                                        child: Chip(
                                          avatar: Icon(
                                            isImage ? Icons.image : _getFileIcon(file.name),
                                            size: 16,
                                          ),
                                          label: Text(
                                            file.name.length > 20 ? '${file.name.substring(0, 20)}...' : file.name,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () {
                                            setDialogState(() {
                                              selectedFiles.remove(file);
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.custom,
                                    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
                                  );

                                  if (result != null) {
                                    setDialogState(() {
                                      selectedFiles.addAll(result.files);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Add Files (Tap to preview)'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Action buttons
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isUploading
                                ? null
                                : () {
                                    audioRecorder.dispose();
                                    audioPlayer.dispose();
                                    Navigator.pop(context);
                                  },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please fill in all required fields')),
                                      );
                                      return;
                                    }

                                    setDialogState(() {
                                      isUploading = true;
                                    });

                                    try {
                                      List<String> attachmentUrls = [];
                                      List<String> voiceNoteUrls = [];

                                      // Upload voice note
                                      if (recordedPath != null) {
                                        String? url = await ApiService.uploadFile(recordedPath!);
                                        if (url != null) {
                                          voiceNoteUrls.add(url);
                                        }
                                      }

                                      // Upload attachments
                                      for (var file in selectedFiles) {
                                        if (file.path != null) {
                                          String? url = await ApiService.uploadFile(file.path!);
                                          if (url != null) {
                                            attachmentUrls.add(url);
                                          }
                                        }
                                      }

                                      await ApiService.createReport(
                                        title: titleController.text,
                                        description: descriptionController.text,
                                        priority: selectedPriority,
                                        category: selectedCategory,
                                        attachments: attachmentUrls,
                                        voiceNotes: voiceNoteUrls,
                                      );

                                      if (!context.mounted) return;
                                      audioRecorder.dispose();
                                      audioPlayer.dispose();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Report submitted successfully!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      onSuccess();
                                    } catch (e) {
                                      setDialogState(() {
                                        isUploading = false;
                                      });
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.send),
                            label: const Text('Submit Report'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Uploading report...', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('This may take a few moments', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) return Icons.article;
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) return Icons.image;
    return Icons.insert_drive_file;
  }
}

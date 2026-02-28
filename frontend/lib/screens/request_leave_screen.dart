// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'Full Day';
  String? _halfDayType;
  String _reason = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _voiceNoteUrl;
  String? _attachmentUrl;
  bool _isLoading = false;
  bool _isRecording = false;

  final List<String> _leaveTypes = ['Full Day', 'Half Day'];
  final List<String> _halfDayTypes = ['1st Half (Morning)', '2nd Half (Afternoon)'];
  final List<String> _reasons = [
    'Sick Leave',
    'Personal Leave',
    'Emergency',
    'Family Event',
    'Medical Appointment',
    'Other'
  ];

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must be less than 10MB')),
          );
          return;
        }
        setState(() {
          _attachmentUrl = file.name;
        });
        if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selected: ${file.name}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _recordVoiceNote() async {
    setState(() {
      _isRecording = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isRecording = false;
      _voiceNoteUrl = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.mp3';
    });

    if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice note recorded successfully')),
    );
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date')),
      );
      return;
    }

    if (_leaveType == 'Half Day' && _halfDayType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select half day type')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final leaveData = {
        'leave_type': _leaveType,
        'half_day_type': _halfDayType,
        'reason': _reason,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
        'voice_note_url': _voiceNoteUrl,
        'attachment_url': _attachmentUrl,
      };

      await ApiService.createLeave(leaveData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Request Leave'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              
              // Leave Type Dropdown
              const Text('Leave Type', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                  value: _leaveType,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                items: _leaveTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _leaveType = value!;
                    if (_leaveType == 'Full Day') {
                      _halfDayType = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Half Day Selection
              if (_leaveType == 'Half Day') ...[
                const Text('Select Half Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                ..._halfDayTypes.map((type) {
                  return 
                  RadioListTile<String>(
                    title: Text(type),
                    value: type,
                    groupValue: _halfDayType,
                    onChanged: (value) {
                      setState(() {
                        _halfDayType = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const Text('Required', style: TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 24),
              ],

              // Reason Dropdown
              const Text('Reason', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                hint: const Text('Select reason'),
                items: _reasons.map((reason) {
                  return DropdownMenuItem(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _reason = value!;
                  });
                },
                validator: (value) => value == null ? 'Please select a reason' : null,
              ),
              const SizedBox(height: 24),

              // Start Date
              const Text('Start Date', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _startDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // End Date (for Full Day only)
              if (_leaveType == 'Full Day') ...[
                const Text('End Date (Optional)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'Select date',
                      style: TextStyle(
                        color: _endDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Voice Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mic, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Voice Note', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            _voiceNoteUrl != null ? 'Voice Note Attached ✓' : 'Tap to record',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (_voiceNoteUrl != null) ...[
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _voiceNoteUrl = null;
                          });
                        },
                      ),
                    ] else
                      IconButton(
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        color: _isRecording ? Colors.red : Colors.blue,
                        onPressed: _isRecording ? null : _recordVoiceNote,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attachment
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Attachment', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              _attachmentUrl ?? 'Tap to select file',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_attachmentUrl != null)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _attachmentUrl = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

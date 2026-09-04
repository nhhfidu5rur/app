import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/excel_service.dart';

class DailyEntryScreen extends StatefulWidget {
  final int fileIndex;
  final Map<String, dynamic> file;

  const DailyEntryScreen({
    super.key,
    required this.fileIndex,
    required this.file,
  });

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen> {
  late Map<String, dynamic> _file;
  late List<String> _columns;
  late Map<String, TextEditingController> _controllers;
  DateTime _selectedDate = DateTime.now();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _file = Map<String, dynamic>.from(widget.file);
    _columns = List<String>.from(_file['columns'] ?? []);
    _controllers = {
      for (var col in _columns) col: TextEditingController()
    };
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A5F),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _addEntry() async {
    final dateStr = DateFormat('yyyy/MM/dd').format(_selectedDate);
    final entry = {
      'date': dateStr,
      for (var col in _columns) col: _controllers[col]!.text.trim(),
    };

    final entries = List<dynamic>.from(_file['entries'] ?? []);
    entries.add(entry);
    _file['entries'] = entries;

    final prefs = await SharedPreferences.getInstance();
    final filesJson = prefs.getString('excel_files') ?? '[]';
    final files = List<Map<String, dynamic>>.from(
      jsonDecode(filesJson).map((e) => Map<String, dynamic>.from(e)),
    );
    files[widget.fileIndex] = _file;
    await prefs.setString('excel_files', jsonEncode(files));

    // Clear fields
    for (var c in _controllers.values) {
      c.clear();
    }

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة إدخال $dateStr ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      await ExcelService.exportToExcel(
        context: context,
        file: _file,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteEntry(int index) async {
    final entries = List<dynamic>.from(_file['entries'] ?? []);
    entries.removeAt(index);
    _file['entries'] = entries;

    final prefs = await SharedPreferences.getInstance();
    final filesJson = prefs.getString('excel_files') ?? '[]';
    final files = List<Map<String, dynamic>>.from(
      jsonDecode(filesJson).map((e) => Map<String, dynamic>.from(e)),
    );
    files[widget.fileIndex] = _file;
    await prefs.setString('excel_files', jsonEncode(files));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = List<dynamic>.from(_file['entries'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          _file['name'] ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            onPressed: _isExporting ? null : _exportExcel,
            tooltip: 'تصدير Excel',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Entry Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'إدخال يومي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF1E3A5F).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF1E3A5F),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('yyyy/MM/dd').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF1E3A5F),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Column Fields
                  ..._columns.asMap().entries.map((entry) {
                    final index = entry.key;
                    final col = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            col,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A5F),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _controllers[col],
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: 'أدخل $col...',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2E86AB),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: (index * 50).ms),
                    );
                  }),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _addEntry,
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white),
                      label: const Text(
                        'إضافة الإدخال',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E86AB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 20),

            // Entries List
            if (entries.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'الإدخالات السابقة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = Map<String, dynamic>.from(
                    entries[entries.length - 1 - index],
                  );
                  final realIndex = entries.length - 1 - index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A5F),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry['date'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteEntry(realIndex),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ..._columns.map((col) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Text(
                                    '$col: ',
                                    style: const TextStyle(
                                      color: Color(0xFF2E86AB),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry[col] ?? '-',
                                      style: const TextStyle(
                                        color: Color(0xFF1E3A5F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms);
                },
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا يوجد إدخالات بعد',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
      floatingActionButton: entries.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isExporting ? null : _exportExcel,
              backgroundColor: const Color(0xFF27AE60),
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Text(
                'تصدير Excel',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

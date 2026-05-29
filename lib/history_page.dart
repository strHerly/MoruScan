// history_page.dart - UPDATED with detection details
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildSeverityBadge(double severity) {
  String label;
  Color color;

  if (severity == 0.0) {
    label = "HEALTHY";
    color = const Color(0xFF27ae60); // Green
  } else if (severity <= 2.0) {
    label = "LOW";
    color = const Color(0xFFB8860B); // Yellow
  } else if (severity <= 7.0) {
    label = "MODERATE";
    color = const Color(0xFFE67E22); // Orange
  } else {
    label = "HIGH";
    color = const Color(0xFFe74c3c); // Red
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Color getSeverityColor(double severity) {
  if (severity == 0.0) return const Color(0xFF27ae60); // Green - Healthy
  if (severity <= 2.0) return const Color(0xFFB8860B); // Yellow - Low
  if (severity <= 7.0) return const Color(0xFFf39c12); // Orange - Moderate
  return const Color(0xFFe74c3c); // Red - High
}


class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  static Future<void> saveRecord({
    required String result,
    required double severityIndex,
    required int leafPixels,
    required int infectedPixels,
    required String recommendation,
    required String imagePath,
    int spotsDetected = 0,
    String? customName,
    String? recommendationTagalog,
    List<Map<String, dynamic>>? detections,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    List<String> saved = prefs.getStringList('history') ?? [];

    String detectionsJson = detections != null ? jsonEncode(detections) : '[]';

    final newEntry =
        "$result|${severityIndex.toStringAsFixed(2)}|$leafPixels|$infectedPixels|$recommendation|$imagePath|$spotsDetected|$dateStr|${customName ?? ''}|${recommendationTagalog ?? ''}|$detectionsJson";

    saved.insert(0, newEntry);
    if (saved.length > 50) saved = saved.sublist(0, 50);

    await prefs.setStringList('history', saved);
  }


  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  final TextEditingController _searchController = TextEditingController();

  // Filter state
  String _searchQuery = '';
  String _selectedSeverity = 'ALL';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('history');

    if (saved != null) {
      final history = saved.map((entry) {
        final parts = entry.split('|');
        
        List<Map<String, dynamic>> detectionsList = [];
        if (parts.length > 10 && parts[10].isNotEmpty) {
          try {
            detectionsList = List<Map<String, dynamic>>.from(
              jsonDecode(parts[10])
            );
          } catch (e) {
            detectionsList = [];
          }
        }
        
        return {
          'result': parts[0],
          'severity': double.tryParse(parts[1]) ?? 0.0,
          'leafPixels': int.tryParse(parts[2]) ?? 0,
          'infectedPixels': int.tryParse(parts[3]) ?? 0,
          'recommendation': parts[4],
          'image': parts[5],
          'spotsDetected': int.tryParse(parts[6]) ?? 0, 
          'date': parts[7],
          'customName': parts.length > 8 ? parts[8] : '',
          'recommendationTagalog': parts.length > 9 ? parts[9] : '',
          'detections': detectionsList,
        };
      }).toList();


      setState(() {
        _history = history;
        _filteredHistory = List.from(history);
      });
    }
  }

  Future<void> _editRecordName(int index) async {
    final record = _filteredHistory[index];
    final currentName = record['customName']?.isNotEmpty == true 
        ? record['customName'] 
        : record['result'];
    
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Record Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter custom name',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      
      // Find the record in the main history list
      final historyIndex = _history.indexWhere(
        (item) => item['date'] == record['date'] && item['image'] == record['image']
      );
      
      if (historyIndex != -1) {
        _history[historyIndex]['customName'] = newName;
        
        // Save updated history
        final updatedStrings = _history
          .map((h) =>
            "${h['result']}|${h['severity']}|${h['leafPixels']}|${h['infectedPixels']}|${h['recommendation']}|${h['image']}|${h['spotsDetected']}|${h['date']}|${h['customName'] ?? ''}|${h['recommendationTagalog'] ?? ''}|${jsonEncode(h['detections'] ?? [])}"
          )
          .toList();

        await prefs.setStringList('history', updatedStrings);
        
        _filterHistory();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record name updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImagePreview(BuildContext context, String imagePath, Map<String, dynamic> record) {
    final file = File(imagePath);
    
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image not found')),
      );
      return;
    }

    final displayName = record['customName']?.isNotEmpty == true 
        ? record['customName'] 
        : record['result'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tappable image preview (tap to open fullscreen)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showFullscreenImage(context, file);
                    },
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.45,
                        width: double.infinity,
                        color: Colors.black,
                        child: Stack(
                          children: [
                            Center(
                              child: Image.file(
                                file,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Tap to zoom hint
                            Positioned(
                              top: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.touch_app, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tap image to view fullscreen & zoom',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ),
                            buildSeverityBadge(record['severity']),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              record['date'],
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Severity Index: ${record['severity'].toStringAsFixed(2)}%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: getSeverityColor(record['severity']),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "Detected Spots: ${record['spotsDetected'] ?? 0}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // NEW: Show individual detections
                        if (record['detections'] != null && (record['detections'] as List).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            "Detection Details:",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ...((record['detections'] as List).asMap().entries.map((entry) {
                            int idx = entry.key;
                            Map<String, dynamic> det = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8, top: 2),
                              child: Text(
                                "Spot ${idx + 1}: ${det['label']} - ${(det['confidence'] * 100).toStringAsFixed(1)}% confidence",
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            );
                          }).toList()),
                        ],

                        const SizedBox(height: 6),
                        Text(
                          "Leaf Area: ${record['leafPixels']} px",
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          "Infected Area: ${record['infectedPixels']} px",
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Recommended Action:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          record['recommendation'],
                          style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                        
            
                        if (record['recommendationTagalog']?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            record['recommendationTagalog'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, File imageFile) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 10.0,
              boundaryMargin: const EdgeInsets.all(50),
              child: Center(
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Pinch to zoom (up to 10x)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Remove this scan from your history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final record = _filteredHistory[index];

      final file = File(record['image']);
      if (file.existsSync()) {
        file.deleteSync(); 
      }
      

      _history.removeWhere((item) => item['date'] == record['date'] && item['image'] == record['image']);

      final updatedStrings = _history
        .map((h) =>
          "${h['result']}|${h['severity']}|${h['leafPixels']}|${h['infectedPixels']}|${h['recommendation']}|${h['image']}|${h['spotsDetected']}|${h['date']}|${h['customName'] ?? ''}|${h['recommendationTagalog'] ?? ''}|${jsonEncode(h['detections'] ?? [])}"
        )
        .toList();

      await prefs.setStringList('history', updatedStrings);

      _filterHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record deleted'), behavior: SnackBarBehavior.floating),
      );
    }
  }


 void _filterHistory() {
    setState(() {
      _filteredHistory = _history.where((item) {
        // 1️⃣ Search filter - search in both result and custom name
        final searchText = item['customName']?.isNotEmpty == true 
            ? item['customName'] 
            : item['result'];
        final matchesQuery = searchText
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());

        // 2️⃣ Severity filter
        final severity = item['severity'] as double;
        bool matchesSeverity = true;
        if (_selectedSeverity == 'HEALTHY') matchesSeverity = severity == 0.0;
        if (_selectedSeverity == 'LOW') matchesSeverity = severity > 0.0 && severity <= 2.0;
        if (_selectedSeverity == 'MODERATE') matchesSeverity = severity > 2.0 && severity <= 7.0;
        if (_selectedSeverity == 'HIGH') matchesSeverity = severity > 7.0;

        // 3️⃣ Date filter (exact day match)
        bool matchesDate = true;
        if (_selectedDate != null) {
          final itemDateTime = DateTime.parse(item['date']);
          matchesDate = itemDateTime.year == _selectedDate!.year &&
                      itemDateTime.month == _selectedDate!.month &&
                      itemDateTime.day == _selectedDate!.day;
        }

        return matchesQuery && matchesSeverity && matchesDate;
      }).toList();
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedSeverity != 'ALL') count++;
    if (_selectedDate != null) count++;
    return count;
  }

  void _openFilterModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.filter_alt, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Filter History",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Severity Filter Section - DROPDOWN
                  const Text(
                    "Severity Level",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSeverity,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Severities')),
                          DropdownMenuItem(
                            value: 'HEALTHY',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF27ae60), size: 18),
                                SizedBox(width: 8),
                                Text('Healthy'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'LOW',
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Color(0xFFFFEB3B), size: 18),
                                SizedBox(width: 8),
                                Text('Low Severity'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'MODERATE',
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: Color(0xFFf39c12), size: 18),
                                SizedBox(width: 8),
                                Text('Moderate Severity'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'HIGH',
                            child: Row(
                              children: [
                                Icon(Icons.dangerous, color: Color(0xFFe74c3c), size: 18),
                                SizedBox(width: 8),
                                Text('High Severity'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => _selectedSeverity = value);
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Date Filter Section
                  const Text(
                    "Filter by Date",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.green,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: _selectedDate != null ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? "Select a date"
                                  : "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDate != null ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ),
                          if (_selectedDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setModalState(() => _selectedDate = null);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedSeverity = 'ALL';
                              _selectedDate = null;
                            });
                            setState(() {
                              _selectedSeverity = 'ALL';
                              _selectedDate = null;
                            });
                            _filterHistory();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            "Clear All",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Apply filters from modal state
                            });
                            _filterHistory();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Apply Filters",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilters = _getActiveFilterCount();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 4,
        shadowColor: Colors.greenAccent.withOpacity(0.4),
      ),
      body: Column(
        children: [
          // Search bar + filter button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by result...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _filterHistory();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: activeFilters > 0 ? Colors.green : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activeFilters > 0 ? Colors.green : Colors.grey.shade300,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_alt,
                          color: activeFilters > 0 ? Colors.white : Colors.green,
                        ),
                        onPressed: _openFilterModal,
                      ),
                    ),
                    if (activeFilters > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '$activeFilters',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded history list
          Expanded(
            child: _filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "No history found",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (activeFilters > 0) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedSeverity = 'ALL';
                                _selectedDate = null;
                              });
                              _filterHistory();
                            },
                            child: const Text("Clear filters"),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final h = _filteredHistory[index];
                      final file = File(h['image']);
                      final displayName = h['customName']?.isNotEmpty == true 
                          ? h['customName'] 
                          : h['result'];
                      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () => _showImagePreview(context, h['image'], h),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: file.existsSync()
                                      ? Image.file(file, width: 60, height: 60, fit: BoxFit.cover)
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 15
                                              ),
                                            ),
                                          ),
                                          if (h['customName']?.isNotEmpty == true)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6, 
                                                vertical: 2
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                size: 12,
                                                color: Colors.blue,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        h['date'],
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          buildSeverityBadge(h['severity']),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${h['severity'].toStringAsFixed(2)}%",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: getSeverityColor(h['severity']),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editRecordName(index),
                                  tooltip: 'Edit name',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteRecord(index),
                                  tooltip: 'Delete record',
                                ),
                              ],
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
}
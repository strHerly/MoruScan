// settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> clearHistory(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'Are you sure you want to delete all scan history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('History cleared successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Settings & About',
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          // General Settings Section
          Text(
            'General Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 10),

          // Clear History Card
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            shadowColor: Colors.black12,
            child: ListTile(
              leading: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child:
                    const Icon(Icons.delete_forever, color: Colors.red, size: 28),
              ),
              title: Text(
                'Clear History',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Remove all scanned results from history.',
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black45),
              onTap: () => clearHistory(context),
            ),
          ),

          const SizedBox(height: 30),

          // About MoruScan Section
          Text(
            'About MoruScan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 10),

          // App Info Card
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child:
                            const Icon(Icons.eco, color: Colors.green, size: 32),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MoruScan',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            'Version 1.0.2',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Mulberry Leaf Disease Detection System',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MoruScan uses advanced AI-powered computer vision to detect and analyze leaf spot diseases in mulberry leaves with high accuracy.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Features
                  _buildFeatureRow(
                      Icons.smart_toy_outlined, 'AI-Powered Detection'),
                  const SizedBox(height: 8),
                  _buildFeatureRow(Icons.calculate_outlined,
                      'Severity Index Calculation'),
                  const SizedBox(height: 8),
                  _buildFeatureRow(
                      Icons.analytics_outlined, 'Leaf Masking Technology'),
                  const SizedBox(height: 8),
                  _buildFeatureRow(Icons.history, 'Scan History Tracking'),

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 16),

                  // Institution
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Don Mariano Marcos Memorial State University - South La Union Campus',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'College of Computer Science',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.biotech_outlined,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sericulture Research and Development Institute (SRDI)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Development Team Section Header
          Text(
            'Development Team',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 10),

          // Adviser Card (highlighted)
          _buildAdviserCard(
            name: 'Jocelyn I. Ancheta',
            role: 'Research Adviser',
            email: 'jancheta@dmmmsu.edu.ph',
          ),

          const SizedBox(height: 12),

          // Developers label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Developers',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Developer Cards
          _buildDeveloperCard(
            name: 'Reymar Herlan D. Molina',
            email: 'rhmolina8903@student.dmmmsu.edu.ph',
            index: 0,
          ),
          const SizedBox(height: 10),
          _buildDeveloperCard(
            name: 'Cristine Joy B. Bautista',
            email: 'cjbautista9163@student.dmmmsu.edu.ph',
            index: 1,
          ),
          const SizedBox(height: 10),
          _buildDeveloperCard(
            name: 'Janiel F. Cestona',
            email: 'jcestona0753@student.dmmmsu.edu.ph',
            index: 2,
          ),
          const SizedBox(height: 10),
          _buildDeveloperCard(
            name: 'Mylene R. Galera',
            email: 'mgalera9873@student.dmmmsu.edu.ph',
            index: 3,
          ),
          const SizedBox(height: 10),
          _buildDeveloperCard(
            name: 'Mia Melody Gloria',
            email: 'mgloria@student.dmmmsu.edu.ph',
            index: 4,
          ),
          const SizedBox(height: 10),
          _buildDeveloperCard(
            name: 'Mico A. Sancho',
            email: 'msancho9783@student.dmmmsu.edu.ph',
            index: 5,
          ),

          const SizedBox(height: 30),

          // Copyright
          Center(
            child: Text(
              '© 2026 MoruScan. All Rights Reserved.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// Adviser card — distinguished with a gold accent stripe and badge
  Widget _buildAdviserCard({
    required String name,
    required String role,
    required String email,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.amber.withOpacity(0.25),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade300, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Adviser',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Developer card with alternating avatar accent colors
  Widget _buildDeveloperCard({
    required String name,
    required String email,
    required int index,
  }) {
    // Cycle through a palette of green tones for the avatars
    final List<List<Color>> avatarGradients = [
      [const Color(0xFF43A047), const Color(0xFF66BB6A)],
      [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
      [const Color(0xFF2E7D32), const Color(0xFF81C784)],
      [const Color(0xFF388E3C), const Color(0xFFA5D6A7)],
      [const Color(0xFF1B5E20), const Color(0xFF66BB6A)],
      [const Color(0xFF00695C), const Color(0xFF80CBC4)],
    ];

    final gradient = avatarGradients[index % avatarGradients.length];

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with initials
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.green[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green[700]),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Returns up to 2 initials from a full name
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
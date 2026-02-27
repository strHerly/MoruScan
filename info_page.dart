// info_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'App Guide & Tips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 4,
        shadowColor: Colors.greenAccent.withOpacity(0.4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          _buildSectionHeader('How to Use MoruScan', 'Paano Gamitin ang MoruScan'),
          _buildInfoCard(
            title: 'Step 1: Capture or Select Leaf Image',
            desc:
                'Tap the Camera button to take a photo of a mulberry leaf, or use the Gallery button to select an existing image from your device.',
            translation:
                'Pindutin ang Camera button para kumuha ng litrato ng dahon, o ang Gallery button para pumili ng larawan mula sa iyong phone.',
            icon: Icons.photo_camera_outlined,
          ),
          _buildInfoCard(
            title: 'Step 2: Analyze the Leaf',
            desc:
                'The app will automatically detect leaf spots and calculate the severity index. Results will show if the leaf is Healthy or has Low, Moderate, or High severity infection.',
            translation:
                'Awtomatikong susuriin ng app ang mga mantsa sa dahon para malaman ang tindi ng sakit nito. Lalabas sa resulta kung ito ay Healthy o may mababa (Low) hanggang malalang (High) impeksyon.',
            icon: Icons.analytics_outlined,
          ),
          _buildInfoCard(
            title: 'Step 3: View Detailed Report',
            desc:
                'Tap the result card to see a comprehensive analysis including infection percentage, leaf area metrics, and recommended actions based on severity.',
            translation:
                'I-tap ang result card para makita ang buong detalye gaya ng infection percentage at mga payo kung ano ang dapat gawin.',
            icon: Icons.assessment_outlined,
          ),
          _buildInfoCard(
            title: 'Step 4: Check Scan History',
            desc:
                'Tap the History icon to view all previous scans with images, severity levels, infection index, and recommendations. You can filter by severity or date.',
            translation:
                'Pindutin ang History icon para balikan ang mga nakaraang scan. Maaari mong i-filter ang mga ito ayon sa petsa o tindi ng impeksyon.',
            icon: Icons.history_rounded,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Tips for Accurate Detection', 'Para sa Mas Tumpak na Resulta'),
          _buildInfoCard(
            title: 'Good Lighting',
            desc:
                'Ensure the leaf is well-lit when capturing. Natural daylight works best. Avoid harsh shadows or extremely bright spots.',
            translation:
                'Siguraduhing maliwanag ang paligid. Mas mainam kung natural na liwanag ng araw. Iwasan ang sobrang madilim na anino o sobrang nakakasilaw na bahagi.',
            icon: Icons.wb_sunny_rounded,
          ),
          _buildInfoCard(
            title: 'Clear & Focused Image',
            desc:
                'Keep the camera steady and ensure the leaf is in focus. Blurry images may reduce detection accuracy.',
            translation:
                'Panatilihing matatag ang kamay at siguraduhing malinaw ang pokus sa dahon. Mahihirapang sumuri ang app kung malabo ang litrato.',
            icon: Icons.center_focus_strong_rounded,
          ),
          _buildInfoCard(
            title: 'Capture Full Leaf',
            desc:
                'Try to capture the entire leaf or the most affected area. You can photograph leaves in their natural environment or on a plain surface.',
            translation:
                'Subukang kunan ang buong dahon o ang pinaka-apektadong bahagi nito. Siguraduhing kitang-kita ang kabuuan ng dahon.',
            icon: Icons.crop_free_rounded,
          ),
          _buildInfoCard(
            title: 'Avoid Obstructions',
            desc:
                'Make sure nothing is blocking the leaf (fingers, other leaves, debris). The leaf should be clearly visible.',
            translation:
                'Siguraduhing walang nakaharang sa dahon gaya ng daliri, ibang dahon, o dumi para hindi magkamali ang pagsusuri.',
            icon: Icons.remove_red_eye_outlined,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Understanding Results', 'Pag-unawa sa Resulta'),
          _buildInfoCard(
            title: 'Healthy (0%)',
            desc:
                'No leaf spots detected. The leaf appears healthy. Continue routine monitoring and maintain proper plant care.',
            translation:
                'Walang nakitang mantsa. Mukhang malusog ang dahon. Ipagpatuloy lang ang regular na pag-aalaga at pagbabantay sa halaman.',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
          _buildInfoCard(
            title: 'Low Severity (0.01-2%)',
            desc:
                'Minor infection detected. Early intervention recommended. Monitor closely and maintain proper nutrition.',
            translation:
                'May kaunting impeksyon. Agapan ito sa pamamagitan ng masusing pagbabantay at pagbibigay ng tamang nutrisyon sa halaman.',
            icon: Icons.warning_amber_outlined,
            color: const Color(0xFFFFEB3B),
          ),
          _buildInfoCard(
            title: 'Moderate Severity (2-7%)',
            desc:
                'Moderate infection level. Remove affected leaves and apply fungicide treatment. Improve air circulation.',
            translation:
                'Katamtamang impeksyon. Tanggalin ang mga apektadong dahon, gumamit ng fungicide, at siguraduhing maayos ang daloy ng hangin.',
            icon: Icons.error_outline,
            color: const Color(0xFFf39c12),
          ),
          _buildInfoCard(
            title: 'High Severity (>7%)',
            desc:
                'Severe infection detected. Immediate action required. Consider heavy pruning or consult an agricultural expert.',
            translation:
                'Malala ang impeksyon. Kailangan ng agarang aksyon gaya ng pruning o pagkonsulta sa isang eksperto sa agrikultura.',
            icon: Icons.dangerous_outlined,
            color: const Color(0xFFe74c3c),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Rest of your helper methods remain the same...
  Widget _buildSectionHeader(String text, String translation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.green[300],
                  thickness: 1.2,
                  endIndent: 8,
                ),
              ),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[800],
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.green[300],
                  thickness: 1.2,
                  indent: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            translation,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String desc,
    required String translation,
    required IconData icon,
    Color? color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: (color ?? Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color ?? Colors.green[700], size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    translation,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
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
}
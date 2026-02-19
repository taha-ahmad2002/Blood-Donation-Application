import 'package:blood/views/user/drawer.dart';
import 'package:blood/views/user/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Responsive helper class
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 24;
    return 32;
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize ?? mobileSize * 1.2;
    return desktopSize ?? mobileSize * 1.4;
  }

  static double getResponsiveImageSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize ?? mobileSize * 1.3;
    return desktopSize ?? mobileSize * 1.6;
  }
}

class AboutUsPage extends StatefulWidget {
  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  int selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 26, tabletSize: 32, desktopSize: 40);
    final sectionTitleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 20, tabletSize: 24, desktopSize: 28);
    final bodyFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 16, tabletSize: 17, desktopSize: 18);
    final smallFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 14, tabletSize: 15, desktopSize: 16);
    final imageSize = ResponsiveHelper.getResponsiveImageSize(context, mobileSize: 120, tabletSize: 150, desktopSize: 180);
    final appBarTitleSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 20, tabletSize: 24, desktopSize: 28);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: appBarTitleSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[900],
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      drawer: SideDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsivePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: responsivePadding),
            Image.asset('assets/images/bag.png', height: imageSize),
            SizedBox(height: responsivePadding * 1.5),
            Text(
              'Welcome to Life Sync',
              style: GoogleFonts.poppins(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: responsivePadding * 0.5),
            Text(
              'Life Sync is dedicated to connecting blood donors with those in need. Our mission is to make blood donation easier, faster, and more accessible to save lives.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: bodyFontSize,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            SizedBox(height: responsivePadding * 1.5),
            Text(
              'Why Choose Us?',
              style: GoogleFonts.poppins(
                fontSize: sectionTitleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: responsivePadding * 0.8),
            BulletPoint(text: 'Find and connect with nearby donors instantly', fontSize: bodyFontSize),
            BulletPoint(text: 'Get notified about urgent blood requests', fontSize: bodyFontSize),
            BulletPoint(text: 'Easy and quick donor registration process', fontSize: bodyFontSize),
            BulletPoint(text: 'Secure and trusted donation platform', fontSize: bodyFontSize),
            SizedBox(height: responsivePadding * 2),
            Text(
              'Blood Group Compatibility',
              style: GoogleFonts.poppins(
                fontSize: sectionTitleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: responsivePadding * 0.8),
            CompatibilityTable(
              bodyFontSize: bodyFontSize,
              smallFontSize: smallFontSize,
            ),
            SizedBox(height: responsivePadding * 2),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                padding: EdgeInsets.symmetric(
                  horizontal: responsivePadding * 2.5,
                  vertical: responsivePadding * 0.75,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Back',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: bodyFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  final double fontSize;

  const BulletPoint({required this.text, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.red[900], size: fontSize * 1.2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompatibilityTable extends StatelessWidget {
  final double bodyFontSize;
  final double smallFontSize;

  const CompatibilityTable({
    super.key,
    this.bodyFontSize = 16,
    this.smallFontSize = 14,
  });

  final List<Map<String, dynamic>> compatibility = const [
    {
      'group': 'O-',
      'donate': 'All blood types',
      'receive': 'O- only',
    },
    {
      'group': 'O+',
      'donate': 'O+, A+, B+, AB+',
      'receive': 'O+, O-',
    },
    {
      'group': 'A-',
      'donate': 'A-, A+, AB-, AB+',
      'receive': 'A-, O-',
    },
    {
      'group': 'A+',
      'donate': 'A+, AB+',
      'receive': 'A+, A-, O+, O-',
    },
    {
      'group': 'B-',
      'donate': 'B-, B+, AB-, AB+',
      'receive': 'B-, O-',
    },
    {
      'group': 'B+',
      'donate': 'B+, AB+',
      'receive': 'B+, B-, O+, O-',
    },
    {
      'group': 'AB-',
      'donate': 'AB-, AB+',
      'receive': 'A-, B-, AB-, O-',
    },
    {
      'group': 'AB+',
      'donate': 'AB+ only',
      'receive': 'All blood types',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      children: compatibility
          .map(
            (row) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 10 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🩸 Blood Group: ${row['group']}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: bodyFontSize,
                        color: Colors.red[900],
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    Text(
                      'Can Donate To: ${row['donate']}',
                      style: GoogleFonts.poppins(
                        fontSize: smallFontSize,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Can Receive From: ${row['receive']}',
                      style: GoogleFonts.poppins(
                        fontSize: smallFontSize,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

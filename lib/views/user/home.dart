import 'package:blood/views/user/about.dart';
import 'package:blood/views/user/alldonors.dart';
import 'package:blood/views/user/profile.dart';
import 'package:blood/views/user/registerdonor.dart';
import 'package:blood/views/user/allrequests.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:badges/badges.dart' as badges; // Import the badges package

// Assuming this is your global variable.  It's better to manage this with a state management solution.
int notificationCount = 0; //changed to 3 to show the badge

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

  static double getResponsiveCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isMobile(context)) return (width - 60) / 2;
    if (isTablet(context)) return (width - 80) / 3;
    return 200;
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final logoSize = ResponsiveHelper.getResponsiveImageSize(context, mobileSize: 80, tabletSize: 110, desktopSize: 140);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 24, tabletSize: 32, desktopSize: 40);
    final subtitleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 11, tabletSize: 13, desktopSize: 15);
    final headerFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 20, tabletSize: 28, desktopSize: 36);
    final taglineFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 14, tabletSize: 18, desktopSize: 22);
    final notificationIconSize = ResponsiveHelper.getResponsiveImageSize(context, mobileSize: 28, tabletSize: 32, desktopSize: 40);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE0E0), // Light pink
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsivePadding, vertical: responsivePadding * 0.8),
              child: Column(
                children: [
                  // Top row with logo and notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo on left
                      Image.asset('assets/images/bloodbag.png', height: logoSize * 0.6, width: logoSize * 0.6),

                      // Notification on right
                      GestureDetector(
                        onTap: () => Get.offAll(AllRequests()),
                        child: badges.Badge(
                          badgeContent: Text(
                            '$notificationCount',
                            style: const TextStyle(fontSize: 9, color: Colors.white),
                          ),
                          showBadge: notificationCount > 0,
                          badgeAnimation: const badges.BadgeAnimation.fade(
                            animationDuration: Duration(milliseconds: 300),
                            toAnimate: true,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(responsivePadding * 0.6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade100,
                                  blurRadius: 12,
                                  offset: const Offset(4, 6),
                                ),
                              ],
                            ),
                            child: Icon(Icons.bloodtype,
                                color: Colors.red[900], size: notificationIconSize),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsivePadding * 1.5),

                  // App title centered
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'LIFE SYNC',
                          style: GoogleFonts.poppins(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.red[900],
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Donate Blood, Save Lives',
                          style: GoogleFonts.poppins(
                            fontSize: subtitleFontSize,
                            color: Colors.black87,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsivePadding * 2),

                  // Services header
                  Center(
                    child: Text(
                      'SERVICES',
                      style: GoogleFonts.poppins(
                        fontSize: headerFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: responsivePadding * 1.5),

                  // Services section
                  isMobile
                      ? Column(
                          children: [
                            ServiceCard(
                              imagePath: 'assets/images/form.png',
                              title: 'BECOME A DONOR',
                              buttonText: 'REGISTER',
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => RequestDonor()));
                              },
                            ),
                            SizedBox(height: responsivePadding),
                            ServiceCard(
                              imagePath: 'assets/images/drop.jpg',
                              title: 'FIND A DONOR',
                              buttonText: 'FIND',
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => AllDonors()));
                              },
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ServiceCard(
                              imagePath: 'assets/images/form.png',
                              title: 'BECOME A DONOR',
                              buttonText: 'REGISTER',
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => RequestDonor()));
                              },
                            ),
                            ServiceCard(
                              imagePath: 'assets/images/drop.jpg',
                              title: 'FIND A DONOR',
                              buttonText: 'FIND',
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => AllDonors()));
                              },
                            ),
                          ],
                        ),

                  SizedBox(height: responsivePadding * 2),
                  Text(
                    'Every drop counts, be a hero.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: taglineFontSize,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: responsivePadding * 3),
                ],
              ),
            ),
          ),
        ),
      ),
      // Fixed Navigation Bar at Bottom
      bottomNavigationBar: NavigationBar(
        height: isMobile ? 65 : 75,
        backgroundColor: Colors.white,
        indicatorColor: Colors.red[100],
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const Home()));
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AboutUsPage()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => Profile()));
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home, size: isMobile ? 24 : 28),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline, size: isMobile ? 24 : 28),
            label: 'About',
          ),
          NavigationDestination(
            icon: Icon(Icons.person, size: isMobile ? 24 : 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String buttonText;
  final VoidCallback onPressed;

  const ServiceCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = ResponsiveHelper.getResponsiveCardWidth(context);
    final imageSizeValue = ResponsiveHelper.getResponsiveImageSize(context, mobileSize: 60, tabletSize: 80, desktopSize: 100);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 13, tabletSize: 15, desktopSize: 17);
    final buttonFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 12, tabletSize: 14, desktopSize: 16);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100,
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(imagePath, height: imageSizeValue, fit: BoxFit.contain),
          SizedBox(height: isMobile ? 12 : 15),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 10 : 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 8 : 10,
              ),
            ),
            onPressed: onPressed,
            child: Text(
              buttonText,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: buttonFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'chat_screen.dart';
import 'donor_details.dart';
import 'drawer.dart';

// Responsive helper class
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 12;
    if (isTablet(context)) return 16;
    return 20;
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize ?? mobileSize * 1.1;
    return desktopSize ?? mobileSize * 1.2;
  }

  static double getResponsiveImageSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    if (isMobile(context)) return mobileSize;
    if (isTablet(context)) return tabletSize ?? mobileSize * 1.2;
    return desktopSize ?? mobileSize * 1.4;
  }
}


class AllDonors extends StatefulWidget {
  const AllDonors({super.key});

  @override
  State<AllDonors> createState() => _AllDonorsState();
}

class _AllDonorsState extends State<AllDonors> {
  int selectedIndex = 0;
  final TextEditingController _searchControllerDonors = TextEditingController();
  String searchQueryDonors = '';
  Timer? _searchDebounceTimer;
  late FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for filtered results to avoid unnecessary rebuilds
  List<QueryDocumentSnapshot>? _cachedDonors;
  String? _cachedSearchQuery;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _searchControllerDonors.addListener(_onSearchChanged);
  }

  // Debounce search to avoid excessive rebuilds
  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQueryDonors = _searchControllerDonors.text.toLowerCase();
        _cachedSearchQuery = null; // Invalidate cache on search change
      });
    });
  }

  @override
  void dispose() {
    _searchControllerDonors.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  // Efficient filtering with caching
  List<QueryDocumentSnapshot> _filterAndSortDonors(List<QueryDocumentSnapshot> docs) {
    // Return cached results if search query hasn't changed
    if (_cachedDonors != null && _cachedSearchQuery == searchQueryDonors) {
      return _cachedDonors!;
    }

    final filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toLowerCase();
      final bloodGroup = (data['bloodGroup'] ?? '').toLowerCase();
      return name.contains(searchQueryDonors) || bloodGroup.contains(searchQueryDonors);
    }).toList();

    // Sort by createdAt in descending order (newest first)
    filtered.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    // Cache the results
    _cachedDonors = filtered;
    _cachedSearchQuery = searchQueryDonors;

    return filtered;
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 16, tabletSize: 18, desktopSize: 20);
    final headingFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 18, tabletSize: 20, desktopSize: 22);
    final cardTitleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 16, tabletSize: 17, desktopSize: 18);
    final subtitleFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 13, tabletSize: 14, desktopSize: 15);
    final bloodGroupFontSize = ResponsiveHelper.getResponsiveFontSize(context, mobileSize: 16, tabletSize: 18, desktopSize: 20);
    final avatarRadius = ResponsiveHelper.getResponsiveImageSize(context, mobileSize: 30, tabletSize: 35, desktopSize: 40);

    final Stream<QuerySnapshot> donationCollection =
        FirebaseFirestore.instance.collection('donors').where('activity', isEqualTo: true).snapshots();

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Donors",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: titleFontSize,
            ),
          ),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: isMobile ? 24 : 28,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          backgroundColor: Colors.red[900],
          centerTitle: true,
          elevation: 2,
        ),
        drawer: SideDrawer(),
        body: SizedBox(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(responsivePadding),
                child: Text(
                  'All Donors List',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: headingFontSize,
                    color: Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsivePadding, vertical: responsivePadding * 0.5),
                child: TextField(
                  controller: _searchControllerDonors,
                  decoration: InputDecoration(
                    labelText: "Search by name or blood group",
                    labelStyle: GoogleFonts.poppins(fontSize: subtitleFontSize),
                    prefixIcon: Icon(Icons.search, size: isMobile ? 20 : 24),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16, horizontal: 12),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: donationCollection,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.poppins(fontSize: subtitleFontSize),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No donations found.',
                          style: GoogleFonts.poppins(fontSize: subtitleFontSize),
                        ),
                      );
                    }

                    // Use efficient filtering with caching
                    final donors = _filterAndSortDonors(snapshot.data!.docs);

                    if (donors.isEmpty) {
                      return Center(
                        child: Text(
                          'No matching donors found.',
                          style: GoogleFonts.poppins(fontSize: subtitleFontSize),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: donors.length,
                      padding: EdgeInsets.symmetric(horizontal: responsivePadding * 0.5, vertical: responsivePadding * 0.5),
                      // Enable caching for better performance
                      cacheExtent: 500,
                      itemBuilder: (context, index) {
                        final donor = donors[index];
                        final data = donor.data() as Map<String, dynamic>;

                        return _buildDonorCard(
                          data: data,
                          isMobile: isMobile,
                          responsivePadding: responsivePadding,
                          subtitleFontSize: subtitleFontSize,
                          bloodGroupFontSize: bloodGroupFontSize,
                          avatarRadius: avatarRadius,
                          cardTitleFontSize: cardTitleFontSize,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Extract donor card to a separate method for better performance
  Widget _buildDonorCard({
    required Map<String, dynamic> data,
    required bool isMobile,
    required double responsivePadding,
    required double subtitleFontSize,
    required double bloodGroupFontSize,
    required double avatarRadius,
    required double cardTitleFontSize,
  }) {
    // Get createdAt timestamp
    var createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    var timeAgo = timeago.format(createdAt);

    // Calculate elapsed time in seconds
    int elapsedSeconds = DateTime.now().difference(createdAt).inSeconds;
    double glowIntensity = (300 - elapsedSeconds) / 30; // Fade over 5 mins (300 sec)
    glowIntensity = glowIntensity.clamp(0, 10);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: responsivePadding * 0.5, vertical: responsivePadding * 0.3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            if (glowIntensity > 0)
              BoxShadow(
                color: Colors.yellow.withOpacity(glowIntensity / 10),
                blurRadius: glowIntensity,
                spreadRadius: glowIntensity / 2,
              ),
          ],
        ),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: EdgeInsets.all(responsivePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Time ago and blood group row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(isMobile ? 8.0 : 10.0),
                      child: Text(
                        data['bloodGroup'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: bloodGroupFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsivePadding * 0.5),
                // Donor info with avatar
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child: data['profileUrl'] != null && data['profileUrl'].isNotEmpty
                          ? Image.network(
                              data['profileUrl'],
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              fit: BoxFit.cover,
                              cacheWidth: (avatarRadius * 2).toInt(),
                              cacheHeight: (avatarRadius * 2).toInt(),
                            )
                          : Icon(Icons.person, color: Colors.blue[900], size: avatarRadius),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: cardTitleFontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: responsivePadding * 0.3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: subtitleFontSize),
                          SizedBox(width: responsivePadding * 0.3),
                          Expanded(
                            child: Text(
                              data['residence'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFontSize,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsivePadding * 0.3),
                      Text(
                        "${data['gender'] ?? 'N/A'} | ${data['donations_done'] ?? '0'} donations done",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: subtitleFontSize * 0.9,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
                SizedBox(height: responsivePadding * 0.5),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (data['userId'] != _auth.currentUser!.uid)
                      IconButton(
                        icon: Icon(Icons.message_outlined, size: isMobile ? 20 : 24),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                receiverId: data['userId'],
                                receiverName: data['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DonorDetails(
                              patient: data['name'],
                              contact: data['contact'],
                              residence: data['residence'],
                              bloodGroup: data['bloodGroup'],
                              gender: data['gender'],
                              noOfDonations: data['donations_done'],
                              details: data['details'],
                              weight: data['weight'],
                              age: data['age'],
                              firstDonated: data['firstDonated'],
                              lastDonated: data['lastDonated'],
                              donationFrequency: data['donationFrequency'],
                              highestEducation: data['highestEducation'],
                              currentOccupation: data['currentOccupation'],
                              currentLivingArrg: data['currentLivingArrg'],
                              eligibilityTest: data['eligibilityTest'],
                              futureDonationWillingness: data['futureDonationWillingness'],
                              profileImage: data['profileUrl'],
                              email: data['email'],
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Details',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }
}
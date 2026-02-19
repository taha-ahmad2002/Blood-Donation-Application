import 'dart:convert';
import 'dart:math';
import 'package:blood/views/user/payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../controllers/fireStoreDatabaseController.dart';
import 'chat_screen.dart';
import 'donor_details.dart';
import 'package:http/http.dart' as http;

class NearbyDonors extends StatefulWidget {
  const NearbyDonors({super.key});
  static const route = '/nearby-donors';

  @override
  State<NearbyDonors> createState() => _NearbyDonorsState();
}

class _NearbyDonorsState extends State<NearbyDonors> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final fireStoreDatabaseController firebaseDatabase = fireStoreDatabaseController();
  Position? currentPosition;
  List<Map<String, dynamic>> nearbyDonors = [];
  bool isLoading = false;
  String selectedBloodGroup = '';
  bool hasPaid = false;

  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  final Map<String, List<String>> compatibleBloodGroups = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
    'AB-': ['A-', 'B-', 'O-', 'AB-'],
  };

  Future<void> checkPaymentAndTrackLocation() async {
    if (selectedBloodGroup.isEmpty) return;

    setState(() => isLoading = true);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser?.uid)
        .get();

    hasPaid = userDoc.data()?['paid'] ?? false;

    await startLocationTracking();

    if (!hasPaid) {
      await showPaymentDialog();
    } else {
      await findNearbyDonors();
    }

    setState(() => isLoading = false);
  }

  Future<void> showPaymentDialog() async {
    final donorCount = nearbyDonors.length;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Required'),
        content: Text('There are $donorCount matching donors nearby. Please make a payment to view full details.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(),
                ),
              );            },
            child: const Text('Proceed to Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (await doesUserExist()) {
        await firebaseDatabase.updateDonorPosition(
            currentPosition!.longitude, currentPosition!.latitude);
      }

      await findNearbyDonors(); // Always fetch donor count
    } catch (e) {
      print("Location error: $e");
    }
  }

  Future<bool> doesUserExist() async {
    final doc = await FirebaseFirestore.instance
        .collection('donors')
        .doc(auth.currentUser?.uid)
        .get();
    return doc.exists;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> findNearbyDonors() async {
    if (currentPosition == null || selectedBloodGroup.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    double lat = currentPosition!.latitude;
    double lon = currentPosition!.longitude;
    double searchRadiusKm = 15;
    double latChange = searchRadiusKm / 111.12;
    double lonChange = searchRadiusKm / (111.12 * cos(lat * pi / 180));
    List<String> validBloodGroups = compatibleBloodGroups[selectedBloodGroup]!;

    try {
      final snapshot = await firestore
          .collection('donors')
          .where('latitude', isGreaterThanOrEqualTo: lat - latChange)
          .where('latitude', isLessThanOrEqualTo: lat + latChange)
          .where('longitude', isGreaterThanOrEqualTo: lon - lonChange)
          .where('longitude', isLessThanOrEqualTo: lon + lonChange)
          .where('activity', isEqualTo: true)
          .where('bloodGroup', whereIn: validBloodGroups)
          .where('userId', isNotEqualTo: auth.currentUser?.uid)
          .get();

      List<Map<String, dynamic>> usersNearby = snapshot.docs
          .map((doc) => doc.data())
          .where((data) {
        double userLat = data['latitude'];
        double userLon = data['longitude'];
        return calculateDistance(lat, lon, userLat, userLon) <= searchRadiusKm;
      }).toList();

      if (!hasPaid) {
        setState(() => nearbyDonors = usersNearby); // Only count
        return;
      }

      // API Model Preparation
      DateTime? parseDate(dynamic value) {
        if (value is Timestamp) return value.toDate();
        if (value is String) return DateTime.tryParse(value);
        return null;
      }

      List<Map<String, dynamic>> modelInput = usersNearby.map((donor) {
        final now = DateTime.now();
        DateTime? lastDonated = parseDate(donor['lastDonated']);
        DateTime? firstDonated = parseDate(donor['firstDonated']);
        double numDonations = double.tryParse(donor['donations_done']?.toString() ?? '0') ?? 0;

        int monthsSinceLast = lastDonated != null ? (now.difference(lastDonated).inDays / 30).floor() : 0;
        int monthsSinceFirst = firstDonated != null ? (now.difference(firstDonated).inDays / 30).floor() : 0;

        return {
          "id": donor['userId'] ?? '',
          "last_donation": monthsSinceLast.toDouble(),
          "months_since_first": monthsSinceFirst.toDouble(),
          "num_donations": numDonations,
        };
      }).toList();

      // Call AI Prediction API
      final url = Uri.parse('https://web-production-5141f.up.railway.app//predict');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": modelInput}),
      );

      if (response.statusCode == 200) {
        final predictions = List<Map<String, dynamic>>.from(jsonDecode(response.body)['predictions']);
        for (var donor in usersNearby) {
          final matching = predictions.firstWhere(
                (pred) => pred['id'] == donor['userId'],
            orElse: () => {"donation_probability": 0.0},
          );
          donor['donation_probability'] = matching['donation_probability'];
        }

        usersNearby.sort((a, b) => (b['donation_probability'] ?? 0.0)
            .compareTo(a['donation_probability'] ?? 0.0));
      }

      setState(() => nearbyDonors = usersNearby);
    } catch (e) {
      print("Error finding donors: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Donors", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red[900],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: "Select Blood Group",
                border: OutlineInputBorder(),
              ),
              value: selectedBloodGroup.isEmpty ? null : selectedBloodGroup,
              items: bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
              onChanged: (value) {
                setState(() => selectedBloodGroup = value!);
              },
            ),
          ),
          ElevatedButton(
            onPressed: isLoading || selectedBloodGroup.isEmpty ? null : checkPaymentAndTrackLocation,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Find Nearby Donors", style: TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: hasPaid
                ? (nearbyDonors.isEmpty
                ? const Center(child: Text("No nearby donors found"))
                : ListView.builder(
              itemCount: nearbyDonors.length,
              itemBuilder: (context, index) {
                final donor = nearbyDonors[index];
                var createdAt = donor['createdAt'] != null
                    ? (donor['createdAt'] as Timestamp).toDate()
                    : DateTime.now();
                var timeAgo = timeago.format(createdAt);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timeAgo, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            decoration: BoxDecoration(color: Colors.red[900], shape: BoxShape.circle),
                            padding: const EdgeInsets.all(8.0),
                            child: Text(donor['bloodGroup'] ?? 'N/A',
                                style: const TextStyle(color: Colors.white, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 5),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.black,
                            child: ClipOval(
                              child: donor['profileUrl'] != null && donor['profileUrl'].isNotEmpty
                                  ? Image.network(donor['profileUrl'], width: 100, height: 100, fit: BoxFit.cover)
                                  : const Icon(Icons.person, color: Colors.white, size: 40),
                            ),
                          ),
                          title: Text(donor['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(donor['residence'] ?? 'Unknown')),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  "${donor['gender'] ?? 'N/A'} | ${donor['donations_done'] ?? '0'} donations done",
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          donor['donation_probability'] != null
                              ? "Predicted Willingness: ${(donor['donation_probability'] * 100).toStringAsFixed(1)}%"
                              : "Predicted Willingness: N/A",
                          style: const TextStyle(color: Colors.green),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (donor['userId'] != auth.currentUser!.uid)
                              IconButton(
                                icon: const Icon(Icons.message_outlined),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                          receiverId: donor['userId'],
                                          receiverName: donor['name']),
                                    ),
                                  );
                                },
                              ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[900],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DonorDetails(
                                      patient: donor['name'],
                                      contact: donor['contact'],
                                      residence: donor['residence'],
                                      bloodGroup: donor['bloodGroup'],
                                      gender: donor['gender'],
                                      noOfDonations: donor['donations_done'],
                                      details: donor['details'],
                                      weight: donor['weight'],
                                      age: donor['age'],
                                      firstDonated: donor['firstDonated'],
                                      lastDonated: donor['lastDonated'],
                                      donationFrequency: donor['donationFrequency'],
                                      highestEducation: donor['highestEducation'],
                                      currentOccupation: donor['currentOccupation'],
                                      currentLivingArrg: donor['currentLivingArrg'],
                                      eligibilityTest: donor['eligibilityTest'],
                                      futureDonationWillingness: donor['futureDonationWillingness'],
                                      email: donor['email'],
                                      profileImage: donor['profileUrl'],
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Details', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ))
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

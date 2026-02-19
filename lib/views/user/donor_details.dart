import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appbar.dart';

class DonorDetails extends StatefulWidget {
  final dynamic patient;
  final dynamic contact;
  final dynamic residence;
  final dynamic noOfDonations;
  final dynamic bloodGroup;
  final dynamic gender;
  final dynamic details;
  final dynamic weight;
  final dynamic age;
  final dynamic lastDonated;
  final dynamic firstDonated;
  final dynamic donationFrequency;
  final dynamic highestEducation;
  final dynamic currentOccupation;
  final dynamic currentLivingArrg;
  final dynamic eligibilityTest;
  final dynamic futureDonationWillingness;
  final dynamic profileImage;
  final dynamic email;

  const DonorDetails({
    super.key,
    required this.patient,
    required this.contact,
    required this.residence,
    required this.noOfDonations,
    required this.bloodGroup,
    required this.gender,
    required this.details,
    required this.weight,
    required this.age,
    required this.lastDonated,
    required this.firstDonated,
    required this.donationFrequency,
    required this.highestEducation,
    required this.currentOccupation,
    required this.currentLivingArrg,
    required this.eligibilityTest,
    required this.futureDonationWillingness,
    this.profileImage,
    required this.email,
  });

  @override
  DonorDetailsState createState() => DonorDetailsState();
}

class DonorDetailsState extends State<DonorDetails> {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;

    final String profileImage = widget.profileImage ?? '';
    final String email = widget.email ?? auth.currentUser?.email;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: CustomAppBar(title: 'Donor Details'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.red.shade900, Colors.red.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: profileImage.isNotEmpty
                                ? Image.network(
                              profileImage,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, size: 80),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildEmailContainer(email), // Styled email container
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Information Cards
              _infoCard("Donor Name", widget.patient),
              _infoCard("Gender", widget.gender),
              _infoCard("Location", widget.residence ?? "null"),
              _infoCard("Blood Group", widget.bloodGroup, highlight: true),
              _infoCard("Contact Number", widget.contact ?? "null", copyable: true),
              _infoCard("Weight (Kg)", widget.weight.toString()),
              _infoCard("Age", widget.age.toString()),
              _infoCard("Details", widget.details ?? "null"),
              _infoCard("First Donated", widget.firstDonated),
              _infoCard("Last Donated", widget.lastDonated),
              _infoCard("Donation Frequency", widget.donationFrequency),
              _infoCard("Highest Education", widget.highestEducation),
              _infoCard("Current Occupation", widget.currentOccupation),
              _infoCard("Living Arrangement", widget.currentLivingArrg),
              _infoCard("Eligibility Test", widget.eligibilityTest),
              _infoCard("Donations Made", widget.noOfDonations.toString()),
              _infoCard("Future Donation Willingness", widget.futureDonationWillingness),

              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }

  // Styled Email Container
  Widget _buildEmailContainer(String email) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade900, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _infoCard(String title, String value, {bool highlight = false, bool copyable = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: copyable
                    ? () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title copied to clipboard!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
                    : null,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: highlight ? Colors.red[900] : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 40,
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Styled Call & Message Buttons
  // Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
  //   return GestureDetector(
  //     onTap: onPressed,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [Colors.red.shade900, Colors.red.shade400],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.red.withOpacity(0.3),
  //             blurRadius: 8,
  //             spreadRadius: 2,
  //             offset: const Offset(2, 4),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(icon, color: Colors.white),
  //           const SizedBox(width: 10),
  //           Text(
  //             label,
  //             style: const TextStyle(color: Colors.white, fontSize: 16),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

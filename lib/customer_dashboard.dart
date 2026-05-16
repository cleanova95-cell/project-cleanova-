import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'booking_page.dart';
import 'BookingHistoryPage.dart';
import 'customer_profile_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {

  int currentIndex = 0;

  final List pages = [
    const HomePage(),
    const BookingPage(),
    const BookingHistoryPage(),
    const CustomerProfilePage(),
  ];

  Future<void> logoutUser() async {

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Color(0xFF43A047)),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: currentIndex == 0
          ? AppBar(
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logoutUser,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Customer Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          : null,
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.cleaning_services), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Map<String, dynamic> prices = {};
  bool isLoadingPrices = true;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('service_prices')
        .get();

    Map<String, dynamic> loadedPrices = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      loadedPrices[doc.id] = {
        'Small': data['smallPrice'] ?? 0,
        'Medium': data['mediumPrice'] ?? 0,
        'Large': data['largePrice'] ?? 0,
      };
    }

    setState(() {
      prices = loadedPrices;
      isLoadingPrices = false;
    });
  }

  Future<String> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Customer';

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (snapshot.exists) {
      return snapshot['full_name'] ?? 'Customer';
    }

    return 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserName(),
      builder: (context, snapshot) {
        String userName = snapshot.data ?? 'Customer';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Welcome Back, $userName 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Book your cleaning service easily',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 25),

              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/image/cleaner_main.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Cleaning Services',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  serviceCard('House', imagePath: 'assets/image/house_icon.png'),
                  serviceCard('Office', imagePath: 'assets/image/office_icon.png'),
                  serviceCard('Deep Cleaning', imagePath: 'assets/image/deep1_icon.png'),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                'Popular Services',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              isLoadingPrices
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : Column(
                children: [
                  popularCard(
                    'House Cleaning',
                    'Sweep, mop & sanitise your home',
                    Icons.home_outlined,
                    prices['House Cleaning'] ?? {},
                  ),
                  const SizedBox(height: 15),
                  popularCard(
                    'Office Cleaning',
                    'Keep your workplace clean & professional',
                    Icons.business_center_outlined,
                    prices['Office Cleaning'] ?? {},
                  ),
                  const SizedBox(height: 15),
                  popularCard(
                    'Deep Cleaning',
                    'Top-to-bottom thorough clean',
                    Icons.auto_fix_high_outlined,
                    prices['Deep Cleaning'] ?? {},
                  ),
                ],
              ),

            ],
          ),
        );
      },
    );
  }

  Widget serviceCard(String title, {IconData? icon, String? imagePath}) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          imagePath != null
              ? Image.asset(
            imagePath,
            width: 75,
            height: 75,
            fit: BoxFit.contain,
          )
              : Icon(icon, color: Colors.green, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget popularCard(String title, String description, IconData icon, Map<String, dynamic> servicePrices) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.green, size: 35),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                if (servicePrices.isNotEmpty)
                  Row(
                    children: [
                      _priceChip('S', 'RM${servicePrices['Small'] ?? 0}'),
                      const SizedBox(width: 6),
                      _priceChip('M', 'RM${servicePrices['Medium'] ?? 0}'),
                      const SizedBox(width: 6),
                      _priceChip('L', 'RM${servicePrices['Large'] ?? 0}'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceChip(String size, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(
        '$size: $price',
        style: TextStyle(
          fontSize: 11,
          color: Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
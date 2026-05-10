import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'booking_page.dart';
import 'BookingHistoryPage.dart';
import 'customer_profile_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() =>
      _CustomerDashboardState();
}

class _CustomerDashboardState
    extends State<CustomerDashboard> {

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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
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
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
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
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF1FFF3),

      appBar: currentIndex == 0

          ? AppBar(

        elevation: 0,
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: logoutUser,
          ),
        ],

        flexibleSpace: Container(

          decoration: const BoxDecoration(

            gradient: LinearGradient(

              colors: [

                Color(0xFF43A047),
                Color(0xFF66BB6A),

              ],

              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        title: const Text(

          'Customer Dashboard',

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      )

          : null,

      body: pages[currentIndex],

      bottomNavigationBar:
      BottomNavigationBar(

        currentIndex: currentIndex,

        selectedItemColor:
        Colors.green,

        unselectedItemColor:
        Colors.grey,

        backgroundColor:
        Colors.white,

        onTap: (index) {

          setState(() {
            currentIndex = index;
          });

        },

        items: const [

          BottomNavigationBarItem(

            icon: Icon(Icons.home),
            label: 'Home',

          ),

          BottomNavigationBarItem(

            icon: Icon(
              Icons.cleaning_services,
            ),

            label: 'Booking',
          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.history),
            label: 'History',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.person),
            label: 'Profile',

          ),

        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(20),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          const Text(

            'Welcome Back 👋',

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(

            'Find your best cleaning service',

            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          Container(

            padding: const EdgeInsets.all(25),

            decoration: BoxDecoration(

              gradient:
              const LinearGradient(

                colors: [

                  Color(0xFF43A047),
                  Color(0xFF66BB6A),

                ],

                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              borderRadius:
              BorderRadius.circular(25),

              boxShadow: [

                BoxShadow(
                  color:
                  Colors.green.withValues(
                    alpha: 0.3,
                  ),

                  blurRadius: 10,

                  offset:
                  const Offset(0, 5),
                ),

              ],
            ),

            child: const Row(

              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,

              children: [

                Expanded(

                  child: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      Text(

                        'Need Cleaning?',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10),

                      Text(

                        'Book trusted cleaners easily and quickly.',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),

                    ],
                  ),
                ),

                SizedBox(width: 10),

                Icon(

                  Icons.cleaning_services,

                  color: Colors.white,
                  size: 65,

                ),

              ],
            ),
          ),

          const SizedBox(height: 30),

          const Text(

            'Cleaning Services',

            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(

            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

            children: [

              serviceCard(
                Icons.home,
                'House',
              ),

              serviceCard(
                Icons.business,
                'Office',
              ),

              serviceCard(
                Icons.kitchen,
                'Kitchen',
              ),

            ],
          ),

          const SizedBox(height: 30),

          const Text(

            'Popular Services',

            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          popularCard(

            'Full House Cleaning',
            'RM120',

            Icons.cleaning_services,
          ),

          const SizedBox(height: 15),

          popularCard(

            'Office Cleaning',
            'RM200',

            Icons.business_center,
          ),

        ],
      ),
    );
  }

  Widget serviceCard(
      IconData icon,
      String title,
      ) {

    return Container(

      width: 105,

      padding: const EdgeInsets.symmetric(
        vertical: 20,
      ),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
          ),

        ],
      ),

      child: Column(

        children: [

          Icon(

            icon,

            color: Colors.green,
            size: 40,

          ),

          const SizedBox(height: 12),

          Text(

            title,

            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

        ],
      ),
    );
  }

  Widget popularCard(
      String title,
      String price,
      IconData icon,
      ) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
          ),

        ],
      ),

      child: Row(

        children: [

          Container(

            padding:
            const EdgeInsets.all(15),

            decoration: BoxDecoration(

              color: Colors.green.shade100,

              borderRadius:
              BorderRadius.circular(15),
            ),

            child: Icon(

              icon,

              color: Colors.green,
              size: 35,

            ),
          ),

          const SizedBox(width: 20),

          Expanded(

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(

                  price,

                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}
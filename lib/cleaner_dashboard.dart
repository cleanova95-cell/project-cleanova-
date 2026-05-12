import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'job_page.dart';

class CleanerDashboard extends StatefulWidget {
  const CleanerDashboard({super.key});

  @override
  State<CleanerDashboard> createState() =>
      _CleanerDashboardState();
}

class _CleanerDashboardState
    extends State<CleanerDashboard> {

  int currentIndex = 0;

  final List pages = [

    const CleanerHomePage(),

    const JobsPage(),

    const CleanerHistoryPage(),

    const CleanerProfilePage(),
  ];

  Future<void> logoutUser() async {

    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(
        builder: (context) =>
        const LoginPage(),
      ),

          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF1FFF3),

      appBar: AppBar(

        elevation: 0,
        centerTitle: true,

        leading: IconButton(

          icon: const Icon(
            Icons.logout,
            color: Colors.white,
          ),

          onPressed: logoutUser,
        ),

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

          'Cleaner Dashboard',

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: pages[currentIndex],
      ),

      bottomNavigationBar:
      BottomNavigationBar(

        currentIndex: currentIndex,

        selectedItemColor:
        Colors.green,

        unselectedItemColor:
        Colors.grey,

        backgroundColor:
        Colors.white,

        type: BottomNavigationBarType.fixed,

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
            icon: Icon(Icons.work),
            label: 'Jobs',
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

class CleanerHomePage extends StatelessWidget {

  const CleanerHomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          const Text(

            'Welcome Back Cleaner 👋',

            style: TextStyle(
              fontSize: 28,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(

            'Manage your assigned cleaning jobs',

            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          Container(

            padding:
            const EdgeInsets.all(25),

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
                  Colors.green.withOpacity(
                    0.3,
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

                        'Today Jobs',

                        style: TextStyle(
                          color:
                          Colors.white,

                          fontSize: 24,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10),

                      Text(

                        'Check your assigned jobs and complete tasks on time.',

                        style: TextStyle(
                          color:
                          Colors.white,

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

            'Quick Overview',

            style: TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(

            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

            children: [

              statCard(
                context,
                'Assigned',
                '5',
                Icons.assignment,
              ),

              statCard(
                context,
                'Completed',
                '12',
                Icons.check_circle,
              ),

            ],
          ),

          const SizedBox(height: 15),

          Row(

            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

            children: [

              statCard(
                context,
                'Pending',
                '2',
                Icons.pending_actions,
              ),

              statCard(
                context,
                'This Month',
                '18',
                Icons.calendar_month,
              ),

            ],
          ),

          const SizedBox(height: 30),

          const Text(

            'Recent Assigned Jobs',

            style: TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          jobCard(
            'House Cleaning',
            'Taman Melawati',
            'Pending',
          ),

          const SizedBox(height: 15),

          jobCard(
            'Office Cleaning',
            'Ampang',
            'In Progress',
          ),

        ],
      ),
    );
  }

  Widget statCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      ) {

    return Container(

      width:
      MediaQuery.of(context)
          .size
          .width *
          0.42,

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(
            color:
            Colors.grey.shade200,

            blurRadius: 8,
          ),
        ],
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color: Colors.green,
            size: 35,
          ),

          const SizedBox(height: 12),

          Text(

            value,

            style: const TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(

            title,

            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

        ],
      ),
    );
  }


  Widget jobCard(
      String service,
      String location,
      String status,
      ) {

    return Container(

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(20),

        boxShadow: [

          BoxShadow(
            color:
            Colors.grey.shade200,

            blurRadius: 8,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Row(

            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

            children: [

              Expanded(

                child: Text(

                  service,

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              Container(

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration: BoxDecoration(

                  color:
                  Colors.green.shade100,

                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                child: Text(

                  status,

                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [

              const Icon(
                Icons.location_on,
                size: 18,
                color: Colors.grey,
              ),

              const SizedBox(width: 8),

              Text(location),

            ],
          ),

          const SizedBox(height: 18),

          SizedBox(

            width: double.infinity,
            height: 45,

            child: ElevatedButton(

              onPressed: () {},

              style:
              ElevatedButton.styleFrom(

                backgroundColor:
                Colors.green,

                shape:
                RoundedRectangleBorder(

                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
              ),

              child: const Text(

                'View Details',

                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}


class CleanerHistoryPage
    extends StatelessWidget {

  const CleanerHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {

    return const Center(

      child: Text(

        'Completed Jobs History',

        style: TextStyle(
          fontSize: 24,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }
}

class CleanerProfilePage
    extends StatelessWidget {

  const CleanerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    return const Center(

      child: Text(

        'Cleaner Profile',

        style: TextStyle(
          fontSize: 24,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }
}
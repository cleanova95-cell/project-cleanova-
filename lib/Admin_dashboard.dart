import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'booking_management_page.dart';
import 'admin_profile_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState
    extends State<AdminDashboard> {

  int currentIndex = 0;

  final List pages = [

    const AdminHomePage(),

    const UsersPage(),

    const BookingManagementPage(),

    const AdminProfilePage(),

  ];

  Future<void> logoutUser() async {

    final bool? confirmed =
    await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),

          title: const Text(
            'Log Out',
          ),

          content: const Text(
            'Are you sure you want to log out?',
          ),

          actions: [

            TextButton(

              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.green,
              ),

              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(

                'Log Out',

                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),

          ],
        );
      },
    );

    if (confirmed == true) {

      await FirebaseAuth.instance
          .signOut();

      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(
          builder: (context) =>
          const LoginPage(),
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

          'Admin Dashboard',

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      )

          : null,

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

        type:
        BottomNavigationBarType.fixed,

        onTap: (index) {

          setState(() {
            currentIndex = index;
          });
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Bookings',
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

class AdminHomePage
    extends StatelessWidget {

  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(

      stream:
      FirebaseFirestore.instance
          .collection('users')
          .snapshots(),

      builder: (context, userSnapshot) {

        int customerCount = 0;
        int cleanerCount = 0;

        if (userSnapshot.hasData) {

          final users =
              userSnapshot.data!.docs;

          for (var user in users) {

            final data =
            user.data()
            as Map<String, dynamic>;

            if (data['role'] ==
                'customer') {

              customerCount++;
            }

            if (data['role'] ==
                'cleaner') {

              cleanerCount++;
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(

          stream:
          FirebaseFirestore.instance
              .collection('bookings')
              .snapshots(),

          builder:
              (context, bookingSnapshot) {

            int bookingCount = 0;
            int completedCount = 0;

            if (bookingSnapshot.hasData) {

              final bookings =
                  bookingSnapshot
                      .data!.docs;

              bookingCount =
                  bookings.length;

              for (var booking
              in bookings) {

                final data =
                booking.data()
                as Map<String,
                    dynamic>;

                if (data['status'] ==
                    'Completed') {

                  completedCount++;
                }
              }
            }

            return SingleChildScrollView(

              padding:
              const EdgeInsets.all(
                20,
              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [

                  const Text(

                    'Welcome Admin 👋',

                    style:
                    TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(

                    'Manage customers, cleaners and bookings',

                    style:
                    TextStyle(
                      fontSize: 16,
                      color:
                      Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  Container(

                    padding:
                    const EdgeInsets
                        .all(25),

                    decoration:
                    BoxDecoration(

                      gradient:
                      const LinearGradient(

                        colors: [

                          Color(
                            0xFF43A047,
                          ),

                          Color(
                            0xFF66BB6A,
                          ),

                        ],

                        begin:
                        Alignment
                            .topLeft,

                        end:
                        Alignment
                            .bottomRight,
                      ),

                      borderRadius:
                      BorderRadius
                          .circular(
                        25,
                      ),

                      boxShadow: [

                        BoxShadow(
                          color: Colors
                              .green
                              .withValues(
                            alpha: 0.3,
                          ),

                          blurRadius:
                          10,

                          offset:
                          const Offset(
                            0,
                            5,
                          ),
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

                                'System Overview',

                                style:
                                TextStyle(
                                  color: Colors
                                      .white,

                                  fontSize:
                                  24,

                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),

                              SizedBox(
                                height:
                                10,
                              ),

                              Text(

                                'Track all bookings and cleaners activity.',

                                style:
                                TextStyle(
                                  color: Colors
                                      .white,

                                  fontSize:
                                  15,
                                ),
                              ),

                            ],
                          ),
                        ),

                        SizedBox(
                          width: 10,
                        ),

                        Icon(

                          Icons
                              .admin_panel_settings,

                          color:
                          Colors.white,

                          size: 65,
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  const Text(

                    'Quick Overview',

                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                    children: [

                      statCard(
                        context,
                        'Customers',
                        customerCount
                            .toString(),
                        Icons.people,
                      ),

                      statCard(
                        context,
                        'Cleaners',
                        cleanerCount
                            .toString(),
                        Icons.cleaning_services,
                      ),

                    ],
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                    children: [

                      statCard(
                        context,
                        'Bookings',
                        bookingCount
                            .toString(),
                        Icons.assignment,
                      ),

                      statCard(
                        context,
                        'Completed',
                        completedCount
                            .toString(),
                        Icons.check_circle,
                      ),

                    ],
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  const Text(

                    'Recent Activities',

                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  activityCard(
                    'New Booking Received',
                    'Customer booked cleaning service',
                    Icons.notifications_active,
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  activityCard(
                    'Cleaner Completed Job',
                    'Cleaning service completed successfully',
                    Icons.check_circle,
                  ),

                ],
              ),
            );
          },
        );
      },
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

          const SizedBox(
            height: 12,
          ),

          Text(

            value,

            style: const TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

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

  Widget activityCard(
      String title,
      String subtitle,
      IconData icon,
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

      child: Row(

        children: [

          Container(

            padding:
            const EdgeInsets.all(15),

            decoration: BoxDecoration(

              color:
              Colors.green.shade100,

              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),

            child: Icon(
              icon,
              color: Colors.green,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                Text(

                  title,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(

                  subtitle,

                  style: const TextStyle(
                    color: Colors.grey,
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

class UsersPage
    extends StatelessWidget {

  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {

    return const Center(

      child: Text(

        'Manage Customers & Cleaners',

        style: TextStyle(
          fontSize: 24,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }
}

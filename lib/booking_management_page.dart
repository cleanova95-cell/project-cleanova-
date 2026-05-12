import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});

  @override
  State<BookingManagementPage> createState() =>
      _BookingManagementPageState();
}

class _BookingManagementPageState
    extends State<BookingManagementPage> {

  final Color primaryGreen =
  const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF5FFF6),

      body: Column(

        children: [

          Container(

            width: double.infinity,

            padding: const EdgeInsets.fromLTRB(
              20,
              25,
              20,
              20,
            ),

            decoration: BoxDecoration(

              gradient: LinearGradient(
                colors: [
                  primaryGreen,
                  Colors.green.shade400,
                ],

                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              borderRadius:
              const BorderRadius.only(
                bottomLeft:
                Radius.circular(30),
                bottomRight:
                Radius.circular(30),
              ),
            ),

            child: const Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  'Booking Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Manage all customer bookings',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 15),

          Expanded(

            child:
            StreamBuilder<QuerySnapshot>(

              stream:
              FirebaseFirestore.instance
                  .collection('bookings')
                  .orderBy(
                'created_at',
                descending: true,
              )
                  .snapshots(),

              builder:
                  (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState
                        .waiting) {

                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot
                        .data!.docs.isEmpty) {

                  return const Center(
                    child: Text(
                      'No bookings found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  );
                }

                final bookings =
                    snapshot.data!.docs;

                return ListView.builder(

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),

                  itemCount:
                  bookings.length,

                  itemBuilder:
                      (context, index) {

                    final booking =
                    bookings[index];

                    final data =
                    booking.data()
                    as Map<String, dynamic>;

                    final bookingId =
                        booking.id;

                    final customerEmail =
                        data['email'] ??
                            'No Email';

                    final serviceType =
                        data['service'] ??
                            'No Service';

                    final propertySize =
                        data['size'] ??
                            'No Size';

                    final status =
                        data['status'] ??
                            'Pending';

                    final address =
                        data['address'] ??
                            'No Address';

                    final cleanerName =
                        data['cleanerName'] ??
                            'Not Assigned';

                    Timestamp? timestamp =
                    data['bookingDate'];

                    String bookingDate =
                        'No Date';

                    if (timestamp != null) {

                      DateTime date =
                      timestamp.toDate();

                      bookingDate =
                      '${date.day}/${date.month}/${date.year}';
                    }

                    return Container(

                      margin:
                      const EdgeInsets.only(
                        bottom: 18,
                      ),

                      decoration:
                      BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                        BorderRadius.circular(
                          25,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .grey
                                .shade200,
                            blurRadius: 10,
                            offset:
                            const Offset(
                              0,
                              5,
                            ),
                          ),
                        ],
                      ),

                      child: Padding(

                        padding:
                        const EdgeInsets.all(
                          20,
                        ),

                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [

                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,

                              children: [

                                Expanded(
                                  child: Text(
                                    customerEmail,
                                    style:
                                    const TextStyle(
                                      fontSize:
                                      20,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                ),

                                Container(

                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal:
                                    14,
                                    vertical:
                                    8,
                                  ),

                                  decoration:
                                  BoxDecoration(
                                    color:
                                    getStatusColor(
                                      status,
                                    ),

                                    borderRadius:
                                    BorderRadius.circular(
                                      20,
                                    ),
                                  ),

                                  child: Text(
                                    status,
                                    style:
                                    const TextStyle(
                                      color: Colors
                                          .white,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                ),

                              ],
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            bookingInfo(
                              Icons
                                  .cleaning_services,
                              'Service Type',
                              serviceType,
                            ),

                            bookingInfo(
                              Icons.home_work,
                              'Property Size',
                              propertySize,
                            ),

                            bookingInfo(
                              Icons
                                  .calendar_month,
                              'Booking Date',
                              bookingDate,
                            ),

                            bookingInfo(
                              Icons.location_on,
                              'Address',
                              address,
                            ),

                            bookingInfo(
                              Icons.person,
                              'Cleaner',
                              cleanerName,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            Row(
                              children: [

                                Expanded(

                                  child:
                                  ElevatedButton
                                      .icon(

                                    style:
                                    ElevatedButton
                                        .styleFrom(
                                      backgroundColor:
                                      Colors.blue,

                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        vertical:
                                        14,
                                      ),

                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                          15,
                                        ),
                                      ),
                                    ),

                                    onPressed: () {

                                      showStatusDialog(
                                        context,
                                        bookingId,
                                        status,
                                      );
                                    },

                                    icon:
                                    const Icon(
                                      Icons.update,
                                      color: Colors
                                          .white,
                                    ),

                                    label:
                                    const Text(
                                      'Update',
                                      style:
                                      TextStyle(
                                        color: Colors
                                            .white,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Expanded(

                                  child:
                                  ElevatedButton
                                      .icon(

                                    style:
                                    ElevatedButton
                                        .styleFrom(
                                      backgroundColor:
                                      primaryGreen,

                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        vertical:
                                        14,
                                      ),

                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                          15,
                                        ),
                                      ),
                                    ),

                                    onPressed: () {

                                      showAssignCleanerDialog(
                                        context,
                                        bookingId,
                                      );
                                    },

                                    icon:
                                    const Icon(
                                      Icons.person_add,
                                      color: Colors
                                          .white,
                                    ),

                                    label:
                                    const Text(
                                      'Assign',
                                      style:
                                      TextStyle(
                                        color: Colors
                                            .white,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Expanded(

                                  child:
                                  ElevatedButton
                                      .icon(

                                    style:
                                    ElevatedButton
                                        .styleFrom(
                                      backgroundColor:
                                      Colors.red,

                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        vertical:
                                        14,
                                      ),

                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                          15,
                                        ),
                                      ),
                                    ),

                                    onPressed: () {

                                      cancelBooking(
                                        bookingId,
                                      );
                                    },

                                    icon:
                                    const Icon(
                                      Icons.cancel,
                                      color: Colors
                                          .white,
                                    ),

                                    label:
                                    const Text(
                                      'Cancel',
                                      style:
                                      TextStyle(
                                        color: Colors
                                            .white,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            ),

                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }

  Widget bookingInfo(
      IconData icon,
      String title,
      String value,
      ) {

    return Padding(

      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: primaryGreen,
            size: 24,
          ),

          const SizedBox(width: 12),

          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight:
              FontWeight.bold,
              fontSize: 15,
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Color getStatusColor(String status) {

    switch (status) {

      case 'Pending':
        return Colors.orange;

      case 'Assigned':
        return Colors.blue;

      case 'Completed':
        return Colors.green;

      case 'Cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  void showStatusDialog(
      BuildContext context,
      String bookingId,
      String currentStatus,
      ) {

    String selectedStatus =
        currentStatus;

    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),

          title: const Text(
            'Update Booking Status',
          ),

          content:
          StatefulBuilder(

            builder:
                (context, setState) {

              return DropdownButton<String>(

                value:
                selectedStatus,

                isExpanded: true,

                items: [

                  'Pending',
                  'Assigned',
                  'Completed',
                  'Cancelled',

                ].map((status) {

                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),

                onChanged: (value) {

                  setState(() {
                    selectedStatus =
                    value!;
                  });
                },
              );
            },
          ),

          actions: [

            TextButton(

              onPressed: () {
                Navigator.pop(
                    context);
              },

              child:
              const Text(
                  'Cancel'),
            ),

            ElevatedButton(

              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                primaryGreen,
              ),

              onPressed:
                  () async {

                await FirebaseFirestore
                    .instance
                    .collection(
                    'bookings')
                    .doc(bookingId)
                    .update({

                  'status':
                  selectedStatus,

                  'updated_at':
                  Timestamp.now(),

                });

                Navigator.pop(
                    context);
              },

              child: const Text(
                'Save',
                style: TextStyle(
                  color:
                  Colors.white,
                ),
              ),
            ),

          ],
        );
      },
    );
  }

  void showAssignCleanerDialog(
      BuildContext context,
      String bookingId,
      ) {

    String selectedCleanerName = '';
    String selectedCleanerId = '';
    String selectedCleanerEmail = '';

    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),

          title: const Text(
            'Assign Cleaner',
          ),

          content:
          StreamBuilder<QuerySnapshot>(

            stream:
            FirebaseFirestore.instance
                .collection('users')
                .where(
              'role',
              isEqualTo: 'cleaner',
            )
                .snapshots(),

            builder:
                (context, snapshot) {

              if (!snapshot.hasData) {

                return const SizedBox(
                  height: 80,
                  child: Center(
                    child:
                    CircularProgressIndicator(),
                  ),
                );
              }

              final cleaners =
                  snapshot.data!.docs;

              if (cleaners.isEmpty) {

                return const Text(
                  'No cleaner found',
                );
              }

              return DropdownButtonFormField<String>(

                decoration:
                const InputDecoration(
                  labelText:
                  'Select Cleaner',
                  border:
                  OutlineInputBorder(),
                ),

                items:
                cleaners.map((cleaner) {

                  final data =
                  cleaner.data()
                  as Map<String, dynamic>;

                  return DropdownMenuItem(

                    value: cleaner.id,

                    child: Text(
                      data['full_name'] ??
                          'No Name',
                    ),
                  );
                }).toList(),

                onChanged: (value) {

                  final cleaner =
                  cleaners.firstWhere(
                        (doc) =>
                    doc.id == value,
                  );

                  final data =
                  cleaner.data()
                  as Map<String, dynamic>;

                  selectedCleanerId =
                      cleaner.id;

                  selectedCleanerName =
                  data['full_name'];

                  selectedCleanerEmail =
                  data['email'];
                },
              );
            },
          ),

          actions: [

            TextButton(

              onPressed: () {
                Navigator.pop(
                    context);
              },

              child:
              const Text(
                  'Cancel'),
            ),

            ElevatedButton(

              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                primaryGreen,
              ),

              onPressed:
                  () async {

                if (selectedCleanerId
                    .isEmpty) {
                  return;
                }

                await FirebaseFirestore
                    .instance
                    .collection(
                    'bookings')
                    .doc(bookingId)
                    .update({

                  'cleanerId':
                  selectedCleanerId,

                  'cleanerName':
                  selectedCleanerName,

                  'cleanerEmail':
                  selectedCleanerEmail,

                  'status':
                  'Assigned',

                  'updated_at':
                  Timestamp.now(),

                });

                Navigator.pop(
                    context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(

                  const SnackBar(
                    content: Text(
                      'Cleaner Assigned Successfully',
                    ),
                    backgroundColor:
                    Colors.green,
                  ),
                );
              },

              child: const Text(
                'Assign',
                style: TextStyle(
                  color:
                  Colors.white,
                ),
              ),
            ),

          ],
        );
      },
    );
  }

  Future<void> cancelBooking(
      String bookingId,
      ) async {

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({

      'status': 'Cancelled',

      'updated_at':
      Timestamp.now(),

    });
  }
}
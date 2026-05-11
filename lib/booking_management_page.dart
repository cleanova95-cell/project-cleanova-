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

          // HEADER
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

          // BOOKING LIST
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

                // LOADING
                if (snapshot.connectionState ==
                    ConnectionState
                        .waiting) {

                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                // NO DATA
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
                    data.containsKey(
                        'cleanerName')
                        ? data['cleanerName']
                        : 'Not Assigned';

                    // DATE FORMAT
                    Timestamp timestamp =
                    data['bookingDate'];

                    DateTime date =
                    timestamp.toDate();

                    final bookingDate =
                        '${date.day}/${date.month}/${date.year}';

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

                            // EMAIL + STATUS
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

                            // INFO
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

                            // BUTTONS
                            Row(
                              children: [

                                // UPDATE BUTTON
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

                                      showStatusDialog(
                                        context,
                                        bookingId,
                                      );
                                    },

                                    icon:
                                    const Icon(
                                      Icons.edit,
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

                                // CANCEL BUTTON
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

  // INFO ROW
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

  // STATUS COLOR
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

  // UPDATE STATUS
  void showStatusDialog(
      BuildContext context,
      String bookingId,
      ) {

    String selectedStatus =
        'Pending';

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

  // CANCEL BOOKING
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
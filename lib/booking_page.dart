import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {

  String selectedService = 'House Cleaning';
  String selectedSize = 'Small';

  DateTime? selectedDate;

  final TextEditingController addressController =
  TextEditingController();

  Map<String, Map<String, int>> prices = {

    'House Cleaning': {
      'Small': 80,
      'Medium': 120,
      'Large': 180,
    },

    'Deep Cleaning': {
      'Small': 150,
      'Medium': 220,
      'Large': 300,
    },

    'Office Cleaning': {
      'Small': 200,
      'Medium': 350,
      'Large': 500,
    },

  };

  Future<void> pickDate() async {

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {

      setState(() {
        selectedDate = pickedDate;
      });

    }
  }

  Future<void> saveBooking() async {

    if (selectedDate == null ||
        addressController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            'Please complete all booking details',
          ),
          backgroundColor: Colors.red,
        ),

      );

      return;
    }

    User? user =
        FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance
        .collection('bookings')
        .add({

      'userId': user!.uid,
      'email': user.email,

      'service': selectedService,
      'size': selectedSize,

      'price':
      prices[selectedService]![selectedSize],

      'address': addressController.text,

      'bookingDate': selectedDate,

      'status': 'Pending',

      'created_at': Timestamp.now(),
      'updated_at': Timestamp.now(),

    });

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(
        content: Text('Booking Successful'),
        backgroundColor: Colors.green,
      ),

    );

    addressController.clear();

    setState(() {
      selectedDate = null;
      selectedService = 'House Cleaning';
      selectedSize = 'Small';
    });
  }

  @override
  Widget build(BuildContext context) {

    int totalPrice =
    prices[selectedService]![selectedSize]!;

    return Scaffold(

      backgroundColor: const Color(0xFFF1FFF3),

      appBar: AppBar(

        automaticallyImplyLeading: false,

        elevation: 0,

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
          'Book Cleaning Service',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              'Select Service',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            serviceCard(
              'House Cleaning',
              Icons.home,
            ),

            const SizedBox(height: 15),

            serviceCard(
              'Deep Cleaning',
              Icons.cleaning_services,
            ),

            const SizedBox(height: 15),

            serviceCard(
              'Office Cleaning',
              Icons.business,
            ),

            const SizedBox(height: 30),

            const Text(
              'Select Size',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

              children: [

                sizeButton('Small'),
                sizeButton('Medium'),
                sizeButton('Large'),

              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Booking Date',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            GestureDetector(

              onTap: pickDate,

              child: Container(

                width: double.infinity,
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

                    const Icon(
                      Icons.calendar_month,
                      color: Colors.green,
                    ),

                    const SizedBox(width: 15),

                    Text(

                      selectedDate == null
                          ? 'Select Booking Date'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',

                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Address',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            TextField(

              controller: addressController,
              maxLines: 3,

              decoration: InputDecoration(

                hintText: 'Enter your address',

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(20),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Container(

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(

                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF43A047),
                    Color(0xFF66BB6A),
                  ],
                ),

                borderRadius:
                BorderRadius.circular(25),
              ),

              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  const Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        'Total Price',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),

                      SizedBox(height: 8),

                    ],
                  ),

                  Text(
                    'RM$totalPrice',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(

              width: double.infinity,
              height: 60,

              child: ElevatedButton(

                onPressed: () async {

                  await saveBooking();

                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),

                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }

  Widget serviceCard(
      String title,
      IconData icon,
      ) {

    bool isSelected =
        selectedService == title;

    return GestureDetector(

      onTap: () {

        setState(() {
          selectedService = title;
        });

      },

      child: Container(

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          color:
          isSelected
              ? Colors.green.shade100
              : Colors.white,

          borderRadius:
          BorderRadius.circular(20),

          border: Border.all(
            color:
            isSelected
                ? Colors.green
                : Colors.transparent,
            width: 2,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
            ),
          ],
        ),

        child: Row(
          children: [

            Icon(
              icon,
              color: Colors.green,
              size: 35,
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),

          ],
        ),
      ),
    );
  }

  Widget sizeButton(String size) {

    bool isSelected =
        selectedSize == size;

    return GestureDetector(

      onTap: () {

        setState(() {
          selectedSize = size;
        });

      },

      child: Container(

        width: 100,

        padding: const EdgeInsets.symmetric(
          vertical: 15,
        ),

        decoration: BoxDecoration(

          gradient: isSelected
              ? const LinearGradient(
            colors: [
              Color(0xFF43A047),
              Color(0xFF66BB6A),
            ],
          )
              : null,

          color:
          isSelected
              ? null
              : Colors.white,

          borderRadius:
          BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
            ),
          ],
        ),

        child: Center(
          child: Text(
            size,
            style: TextStyle(
              color:
              isSelected
                  ? Colors.white
                  : Colors.black,

              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
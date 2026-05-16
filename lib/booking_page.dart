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

  final TextEditingController addressController = TextEditingController();

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
    if (selectedDate == null || addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all booking details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int totalPrice = 0;
    if (prices.isNotEmpty && prices[selectedService] != null) {
      totalPrice = prices[selectedService][selectedSize] ?? 0;
    }

    User? user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('bookings').add({
      'userId': user!.uid,
      'email': user.email,
      'service': selectedService,
      'size': selectedSize,
      'price': totalPrice,
      'address': addressController.text,
      'bookingDate': Timestamp.fromDate(selectedDate!),
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

    int totalPrice = 0;
    if (prices.isNotEmpty && prices[selectedService] != null) {
      totalPrice = prices[selectedService][selectedSize] ?? 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
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
          'Book Cleaning Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoadingPrices
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Select Service',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            serviceCard(
              'House Cleaning',
              Icons.home_outlined,
              'House Cleaning',
              'A standard cleaning to keep your home fresh and tidy. Includes:\n\n• Sweeping & mopping all floors\n• Wiping down surfaces & tables\n• Bathroom cleaning (sink, toilet, shower)\n• Kitchen wipe-down (counters, stovetop, sink)\n• Emptying rubbish bins\n• Vacuuming carpets & rugs\n\nPerfect for regular upkeep of your home.',
            ),

            const SizedBox(height: 15),

            serviceCard(
              'Deep Cleaning',
              Icons.auto_fix_high_outlined,
              'Deep Cleaning',
              'A thorough, top-to-bottom clean — everything in House Cleaning, plus:\n\n• Inside oven, fridge & microwave\n• Scrubbing tile grout & bathroom corners\n• Cleaning window tracks & sills\n• Inside kitchen cabinets & drawers\n• Removing cobwebs from ceilings & corners\n• Disinfecting high-touch surfaces (switches, door handles)\n• Behind and under furniture\n\nIdeal for move-in/move-out or a seasonal deep clean.',
            ),

            const SizedBox(height: 15),

            serviceCard(
              'Office Cleaning',
              Icons.business_center_outlined,
              'Office Cleaning',
              'Professional cleaning for your workplace. Includes:\n\n• Wiping desks, workstations & monitors\n• Cleaning keyboards, phones & office equipment\n• Vacuuming & mopping floors\n• Restroom cleaning & sanitising\n• Pantry & kitchen area cleaning\n• Glass partition & window cleaning\n• Disinfecting high-touch areas (door handles, buttons, railings)\n• Emptying all bins\n\nKeeps your workspace clean, hygienic and professional.',
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                const Text(
                  'Select Size',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final bool isOffice = selectedService == 'Office Cleaning';
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              isOffice ? Icons.business_outlined : Icons.home_outlined,
                              color: const Color(0xFF43A047),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOffice ? 'Office Size Guide' : 'Home Size Guide',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isOffice
                                    ? 'Not sure what size your office is? Use this guide:'
                                    : 'Not sure what size your home is? Use this guide:',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              if (isOffice) ...[
                                const _SizeGuideRow(
                                  label: '🏢 Small Office',
                                  sqm: 'Up to 50 m² (up to ~540 sq ft)',
                                  desc: 'Small shop lot, single-room office, freelancer studio, or 1–5 workstations',
                                  color: Color(0xFFE8F5E9),
                                ),
                                const SizedBox(height: 10),
                                const _SizeGuideRow(
                                  label: '🏬 Medium Office',
                                  sqm: '50 – 150 m² (~540 – 1,600 sq ft)',
                                  desc: 'Small company office, co-working space, clinic, or 5–20 workstations',
                                  color: Color(0xFFC8E6C9),
                                ),
                                const SizedBox(height: 10),
                                const _SizeGuideRow(
                                  label: '🏙️ Large Office',
                                  sqm: '150 m² and above (~1,600 sq ft+)',
                                  desc: 'Full-floor corporate office, call centre, large co-working space, or 20+ workstations',
                                  color: Color(0xFFA5D6A7),
                                ),
                              ] else ...[
                                const _SizeGuideRow(
                                  label: '🏠 Small',
                                  sqm: 'Up to 100 m² (up to ~1,100 sq ft)',
                                  desc: 'Studio, flat, apartment, or 1–2 bedroom condo',
                                  color: Color(0xFFE8F5E9),
                                ),
                                const SizedBox(height: 10),
                                const _SizeGuideRow(
                                  label: '🏡 Medium',
                                  sqm: '100 – 200 m² (~1,100 – 2,150 sq ft)',
                                  desc: 'Single or double-storey terrace house, 3–4 bedrooms',
                                  color: Color(0xFFC8E6C9),
                                ),
                                const SizedBox(height: 10),
                                const _SizeGuideRow(
                                  label: '🏘️ Large',
                                  sqm: '200 m² and above (~2,150 sq ft+)',
                                  desc: 'Semi-D, bungalow, superlink house, 4+ bedrooms',
                                  color: Color(0xFFA5D6A7),
                                ),
                              ],
                              const SizedBox(height: 16),
                              const Text(
                                '💡 Tip: If you are unsure, choose the next size up for a more thorough clean.',
                                style: TextStyle(
                                  color: Color(0xFF43A047),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF43A047),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Got it!',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF43A047),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sizeButton('Small'),
                sizeButton('Medium'),
                sizeButton('Large'),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Booking Date',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.green),
                    const SizedBox(width: 15),
                    Text(
                      selectedDate == null
                          ? 'Select Booking Date'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Address',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
                    borderRadius: BorderRadius.circular(20),
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
      String infoTitle,
      String infoText,
      ) {
    bool isSelected = selectedService == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedService = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 35),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Row(
                      children: [
                        Icon(icon, color: const Color(0xFF43A047)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            infoTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Text(
                        infoText,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Got it!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF43A047),
                  size: 20,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.green),
            ],
          ],
        ),
      ),
    );
  }

  Widget sizeButton(String size) {
    bool isSelected = selectedSize == size;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = size;
        });
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
          )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
          ],
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeGuideRow extends StatelessWidget {
  final String label;
  final String sqm;
  final String desc;
  final Color color;

  const _SizeGuideRow({
    required this.label,
    required this.sqm,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sqm,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF43A047),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
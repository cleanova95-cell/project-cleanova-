import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingManagementPage extends StatefulWidget {
  const PricingManagementPage({super.key});

  @override
  State<PricingManagementPage> createState() =>
      _PricingManagementPageState();
}

class _PricingManagementPageState
    extends State<PricingManagementPage> {

  final Color primaryGreen = const Color(0xFF2E7D32);

  final List<Map<String, dynamic>> services = [
    {
      'id': 'House Cleaning',
      'title': 'House Cleaning',
      'icon': Icons.home,
    },
    {
      'id': 'Deep Cleaning',
      'title': 'Deep Cleaning',
      'icon': Icons.cleaning_services,
    },
    {
      'id': 'Office Cleaning',
      'title': 'Office Cleaning',
      'icon': Icons.business,
    },
  ];

  Map<String, Map<String, TextEditingController>> controllers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchPrices();
  }

  void _initControllers() {
    for (var service in services) {
      final id = service['id'] as String;
      controllers[id] = {
        'Small': TextEditingController(),
        'Medium': TextEditingController(),
        'Large': TextEditingController(),
      };
    }
  }

  Future<void> _fetchPrices() async {
    for (var service in services) {
      final id = service['id'] as String;
      final doc = await FirebaseFirestore.instance
          .collection('service_prices')
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        controllers[id]!['Small']!.text =
            (data['smallPrice'] ?? 0).toString();
        controllers[id]!['Medium']!.text =
            (data['mediumPrice'] ?? 0).toString();
        controllers[id]!['Large']!.text =
            (data['largePrice'] ?? 0).toString();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _savePrices(String serviceId) async {
    final small = int.tryParse(controllers[serviceId]!['Small']!.text) ?? 0;
    final medium = int.tryParse(controllers[serviceId]!['Medium']!.text) ?? 0;
    final large = int.tryParse(controllers[serviceId]!['Large']!.text) ?? 0;

    await FirebaseFirestore.instance
        .collection('service_prices')
        .doc(serviceId)
        .set({
      'smallPrice': small,
      'mediumPrice': medium,
      'largePrice': large,
      'updated_at': Timestamp.now(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$serviceId pricing updated!'),
        backgroundColor: primaryGreen,
      ),
    );
  }

  @override
  void dispose() {
    for (var service in services) {
      final id = service['id'] as String;
      controllers[id]!['Small']!.dispose();
      controllers[id]!['Medium']!.dispose();
      controllers[id]!['Large']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),

      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pricing Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Update service pricing',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          isLoading
              ? const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
              : Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final id = service['id'] as String;
                final icon = service['icon'] as IconData;
                final title = service['title'] as String;

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: primaryGreen,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _priceField('Small', controllers[id]!['Small']!),
                        const SizedBox(height: 12),
                        _priceField('Medium', controllers[id]!['Medium']!),
                        const SizedBox(height: 12),
                        _priceField('Large', controllers[id]!['Large']!),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => _savePrices(id),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text(
                              'Save Pricing',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'RM ',
              prefixStyle: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: const Color(0xFFF1FFF3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryGreen, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
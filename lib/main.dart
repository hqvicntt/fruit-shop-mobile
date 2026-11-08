import 'package:flutter/material.dart';

void main() {
  // The entry point of the mobile application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Turn off the debug banner in the top right corner
      debugShowCheckedModeBanner: false,
      title: 'Cửa Hàng Trái Cây Của Mẹ',
      theme: ThemeData(
        // Set the primary theme color to green (like fresh fruits)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const FruitListScreen(),
    );
  }
}

class FruitListScreen extends StatefulWidget {
  const FruitListScreen({super.key});

  @override
  State<FruitListScreen> createState() => _FruitListScreenState();
}

class _FruitListScreenState extends State<FruitListScreen> {
  // Mock data for fruits list before connecting to the real Laravel API
  final List<Map<String, dynamic>> _mockFruits = [
    {'name': 'Xoài Cát Hòa Lộc', 'price': 60000, 'stock': 25.5},
    {'name': 'Măng Cụt Chợ Lách', 'price': 55000, 'stock': 15.0},
    {'name': 'Chuối Xiêm Chín', 'price': 15000, 'stock': 40.0},
    {'name': 'Vú Sữa Cần Thơ', 'price': 55000, 'stock': 15.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar located at the top of the mobile screen
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Trái Cây Của Mẹ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      // Body displays the list of fruits using ListView.builder
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: _mockFruits.length,
          itemBuilder: (context, index) {
            final fruit = _mockFruits[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                // Fruit title text
                title: Text(
                  fruit['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Subtitle displays price and stock information
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      'Giá: ${fruit['price']} đ / kg',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Còn lại: ${fruit['stock']} kg',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                // Action button on the right side of the item row
                trailing: ElevatedButton(
                  onPressed: () {
                    // Show a quick notification on screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã chọn mua ${fruit['name']}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Mua',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

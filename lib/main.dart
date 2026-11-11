import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

void main() {
  // The entry point of the mobile application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cửa Hàng Trái Cây',
      theme: ThemeData(
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
  // Dynamic list to store fruits fetched from Laravel API
  List<dynamic> _fruits = [];

  // Boolean variable to track the loading state
  bool _isLoading = true;

  // CRITICAL: Replace with your computer's real IPv4 address
  static const String computerIp = 'Your_Computer_IPv4_Address';

  // Function to fetch real-time fruit data from Laravel backend
  Future<void> _fetchFruitsFromBackend() async {
    const String apiUrl =
        'http://$computerIp:8000/api/products'; // Path to product list api

    try {
      // Send a GET request to the Laravel API
      final response = await http.get(Uri.parse(apiUrl));

      // Check if the HTTP status code is 200 OK
      if (response.statusCode == 200) {
        // Decode the JSON string into a Dart Map structure
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Update the state with the real data array from MySQL
          setState(() {
            _fruits = responseData['data'];
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      // Show an error pop-up if the network connection fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi kết nối mạng: Khởi chạy Laravel Herd chưa? $error',
          ),
        ),
      );
    }
  }

  // Function to send a DELETE request to Laravel backend
  Future<void> _deleteFruitFromBackend(int id) async {
    final String apiUrl = 'http://$computerIp:8000/api/products/$id'; // Endpoint with specific fruit ID

    try {
      // Send the HTTP DELETE request to the server
      final response = await http.delete(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Show a quick success notification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa trái cây thành công!')),
          );
          // Refresh the list immediately
          _fetchFruitsFromBackend();
        }
      } else {
        throw Exception('Không thể xóa sản phẩm trên Server');
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa trái cây: $error')));
    }
  }

  // Lifecycle method that runs when the screen is first loaded
  @override
  void initState() {
    super.initState();
    _fetchFruitsFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Cửa Hàng Trái Cây',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      // Display a circular progress bar if data is still loading
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: _fruits.isEmpty
                  ? const Center(
                      child: Text(
                        'Kho hàng đang trống. Hãy thêm trái cây trên Web Admin!',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _fruits.length,
                      itemBuilder: (context, index) {
                        final fruit = _fruits[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              fruit['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  'Giá: ${fruit['price'].toString()} đ / kg',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Còn lại: ${fruit['stock'].toString()} kg',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            // Trailing option containing both Buy button and Delete icon
                            trailing: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Keep row as small as its children
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã chọn mua ${fruit['name']}',
                                        ),
                                      ),
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
                                const SizedBox(width: 8), // Gap between buttons
                                // Red trash bin icon button for deletion
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    // Show native confirmation dialog on mobile screen
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Xác nhận xóa'),
                                          content: Text(
                                            'Bạn có chắc chắn muốn xóa "${fruit['name']}" không?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(), // Close pop-up
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Close pop-up
                                                _deleteFruitFromBackend(
                                                  fruit['id'],
                                                ); // Run delete function
                                              },
                                              child: const Text(
                                                'Xóa',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

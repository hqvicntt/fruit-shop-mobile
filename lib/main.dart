import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Load the .env file before starting the app
  await dotenv.load(fileName: ".env");

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

  // Shopping cart dictionary to store fruit id and its selected quantity
  final Map<int, double> _cart = {};

  // Read the computer IP from the .env file, fallback to empty string if not found
  static final String computerIp = dotenv.env['COMPUTER_IP'] ?? '';

  // Function to fetch real-time fruit data from Laravel backend
  Future<void> _fetchFruitsFromBackend() async {
    final String apiUrl =
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

  // Function to deduct stock quantities after a successful checkout
  Future<void> _processOrderAndDeductStock() async {
    // Show a brief processing indicator or message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang cập nhật số lượng kho hàng...')),
    );

    try {
      // Loop through each item in the shopping cart
      for (var entry in _cart.entries) {
        final int fruitId = entry.key;
        final double boughtQuantity = entry.value;

        // Find the current fruit object in the local list to get its current stock
        final fruit = _fruits.firstWhere(
          (item) => item['id'] == fruitId,
          orElse: () => null,
        );

        if (fruit != null) {
          final double currentStock = (fruit['stock'] as num).toDouble();
          // Calculate the remaining stock, ensuring it never goes below 0
          final double newStock = (currentStock - boughtQuantity) < 0
              ? 0.0
              : (currentStock - boughtQuantity);

          // Prepare the PUT API endpoint for updating this specific fruit
          final String apiUrl = 'http://$computerIp:8000/api/products/$fruitId';

          // Send PUT request with the new stock value to Laravel backend
          await http.put(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'stock': newStock}),
          );
        }
      }

      // Clear the cart and refresh the fruit list from the database
      setState(() {
        _cart.clear();
      });
      await _fetchFruitsFromBackend();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanh toán hoàn tất và đã cập nhật kho!'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật kho hàng: $error')),
      );
    }
  }

  // Lifecycle method that runs when the screen is first loaded
  @override
  void initState() {
    super.initState();
    _fetchFruitsFromBackend();
  }

  // Calculate the total price of all items currently in the cart
  double _calculateTotalAmount() {
    double total = 0;
    _cart.forEach((fruitId, quantity) {
      final fruit = _fruits.firstWhere(
        (item) => item['id'] == fruitId,
        orElse: () => null,
      );
      if (fruit != null) {
        total += (fruit['price'] as num) * quantity;
      }
    });
    return total;
  }

  // Generate standard VietQR text string for banking apps to decode
  String _generateVietQRString(double amount) {
    // Read bank credentials securely from the .env file
    final String bankId =
        dotenv.env['BANK_ID'] ?? ''; // Bank name (EX: vcb, mbbank, bidv)
    final String accountNo =
        dotenv.env['ACCOUNT_NO'] ?? ''; // Your bank account number
    final String accountName =
        dotenv.env['ACCOUNT_NAME'] ?? ''; // Account holder name

    final int amountInt = amount.toInt();

    return 'https://img.vietqr.io/image/'
        '$bankId-$accountNo-qr_only.png'
        '?amount=$amountInt'
        '&addInfo=Tien%20Trai%20Cay'
        '&accountName=${Uri.encodeComponent(accountName)}';
  }

  // Function to open the Checkout Bottom Sheet with dynamic QR code
  void _openCheckoutSheet() {
    final double totalAmount = _calculateTotalAmount();
    if (totalAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng đang trống! Vui lòng chọn ký trái cây.'),
        ),
      );
      return;
    }

    final String qrData = _generateVietQRString(totalAmount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'HÓA ĐƠN QUÉT MÃ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tổng tiền thanh toán:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                '${totalAmount.toInt().toString()} đ',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),

              // Display the generated QR code utilizing qr_flutter package
              Image.network(
                qrData,
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 16),
              const Text(
                'Khách mở App Ngân hàng quét mã này là xong nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Close the QR bottom sheet first
                  Navigator.pop(context);
                  // Execute the stock deduction function
                  await _processOrderAndDeductStock();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Hoàn Thành & Đóng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                        final int id = fruit['id'];
                        final double currentQty = _cart[id] ?? 0.0;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    fruit['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Giá: ${fruit['price']} đ/kg',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Text(
                                    'Kho: ${fruit['stock']} kg',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const Divider(),
                                // Interactive quantity selector row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Số lượng mua:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: currentQty > 0
                                              ? () => setState(() {
                                                  if (currentQty <= 0.5) {
                                                    _cart.remove(id);
                                                  } else {
                                                    _cart[id] =
                                                        currentQty - 0.5;
                                                  }
                                                })
                                              : null,
                                        ),
                                        Text(
                                          '$currentQty kg',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.green,
                                          ),
                                          onPressed:
                                              currentQty <
                                                  (fruit['stock'] as num)
                                                      .toDouble()
                                              ? () => setState(() {
                                                  _cart[id] = currentQty + 0.5;
                                                })
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng cộng:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '${_calculateTotalAmount().toInt().toString()} đ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _openCheckoutSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Tạo Mã QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

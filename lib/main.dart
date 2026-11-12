import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'revenue_report_screen.dart';

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

  // Function to send a POST request to add a new fruit to MySQL
  Future<void> _addNewFruitToBackend(
    String name,
    int price,
    double stock,
  ) async {
    final String apiUrl = 'http://$computerIp:8000/api/products';

    try {
      // Send HTTP POST request with fruit details in JSON format
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'name': name, 'price': price, 'stock': stock}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm trái cây mới thành công!')),
        );
        // Refresh the fruit list immediately
        await _fetchFruitsFromBackend();
      } else {
        throw Exception('Lỗi từ máy chủ: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thêm trái cây: $error')),
      );
    }
  }

  // Function to send a PUT request to update an existing fruit in MySQL
  Future<void> _updateFruitInBackend(
    int id,
    String name,
    int price,
    double stock,
  ) async {
    final String apiUrl = 'http://$computerIp:8000/api/products/$id';

    try {
      // Send HTTP PUT request with updated fruit details
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'name': name, 'price': price, 'stock': stock}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin trái cây thành công!'),
          ),
        );
        // Refresh the fruit list immediately
        await _fetchFruitsFromBackend();
      } else {
        throw Exception('Lỗi từ máy chủ: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật trái cây: $error')),
      );
    }
  }

  // Function to display a pop-up dialog pre-filled with existing fruit data for editing
  void _openEditFruitDialog(Map<String, dynamic> fruit) {
    // Pre-fill the controllers with the selected fruit's current data
    final TextEditingController nameController = TextEditingController(
      text: fruit['name'],
    );
    final TextEditingController priceController = TextEditingController(
      text: fruit['price'].toString(),
    );
    final TextEditingController stockController = TextEditingController(
      text: fruit['stock'].toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Sửa Thông Tin Trái Cây',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên trái cây',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá bán mới (đ/kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Số lượng kho mới (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                final String name = nameController.text.trim();
                final int? price = int.tryParse(priceController.text.trim());
                final double? stock = double.tryParse(
                  stockController.text.trim(),
                );

                // Basic input validation
                // Xác thực dữ liệu đầu vào cơ bản
                if (name.isEmpty || price == null || stock == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đúng và đủ thông tin!'),
                    ),
                  );
                  return;
                }

                // Close the dialog and call the update API
                Navigator.of(context).pop();
                await _updateFruitInBackend(fruit['id'], name, price, stock);
              },
              child: const Text(
                'Lưu Thay Đổi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to display a pop-up dialog for adding a new fruit
  void _openAddFruitDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Nhập Trái Cây Mới',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên trái cây (VD: Chôm chôm)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá bán (đ/kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  // Allow decimal numbers like 15.5 kg
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Số lượng nhập kho (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final String name = nameController.text.trim();
                final int? price = int.tryParse(priceController.text.trim());
                final double? stock = double.tryParse(
                  stockController.text.trim(),
                );

                // Basic input validation
                if (name.isEmpty || price == null || stock == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đúng và đủ thông tin!'),
                    ),
                  );
                  return;
                }

                // Close the dialog and call the API
                Navigator.of(context).pop();
                await _addNewFruitToBackend(name, price, stock);
              },
              child: const Text(
                'Lưu Vào Kho',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to deduct stock quantities AND save the order to MySQL
  Future<void> _processOrderAndDeductStock(
    int totalAmount,
    int cashAmount,
    int transferAmount,
  ) async {
    // Show a brief processing indicator or message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang lưu đơn hàng và cập nhật kho...')),
    );

    // List to store summary text of each bought item (e.g., "Xoài Cát (2.0 kg)")
    List<String> summaryItems = [];

    try {
      // Loop through cart to deduct stock in 'products' table
      for (var entry in _cart.entries) {
        final int fruitId = entry.key;
        final double boughtQuantity = entry.value;

        // Find the current fruit object in the local list to get its current stock
        final fruit = _fruits.firstWhere(
          (item) => item['id'] == fruitId,
          orElse: () => null,
        );

        if (fruit != null) {
          // Add item name and quantity to summary list
          summaryItems.add('${fruit['name']} ($boughtQuantity kg)');
          final double currentStock = (fruit['stock'] as num).toDouble();
          // Calculate the remaining stock, ensuring it never goes below 0
          final double newStock = (currentStock - boughtQuantity) < 0
              ? 0.0
              : (currentStock - boughtQuantity);

          // Prepare the PUT API endpoint for updating this specific fruit
          final String updateProductUrl =
              'http://$computerIp:8000/api/products/$fruitId';

          // Send PUT request with the new stock value to Laravel backend
          await http.put(
            Uri.parse(updateProductUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'stock': newStock}),
          );
        }
      }

      // 2. Send POST request to save order history in 'orders' table
      final String createOrderUrl = 'http://$computerIp:8000/api/orders';
      final String itemsSummaryText = summaryItems.join(', ');

      await http.post(
        Uri.parse(createOrderUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'total_amount': totalAmount,
          'cash_amount': cashAmount,
          'transfer_amount': transferAmount,
          'items_summary': itemsSummaryText,
        }),
      );

      // Clear the cart and refresh the fruit list from the database
      setState(() {
        _cart.clear();
      });
      await _fetchFruitsFromBackend();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu hóa đơn và cập nhật kho thành công!'),
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

  // Function to open the Checkout Bottom Sheet with cash input & dynamic QR code
  void _openCheckoutSheet() {
    final int totalAmount = _calculateTotalAmount().toInt();
    if (totalAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng đang trống! Vui lòng chọn ký trái cây.'),
        ),
      );
      return;
    }

    // Controller to read the cash amount entered by mom
    final TextEditingController cashController = TextEditingController();
    int cashAmount = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // StatefulBuilder allows updating the UI inside the BottomSheet dynamically
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Calculate remaining transfer amount (never less than 0)
            int transferAmount = totalAmount - cashAmount;
            if (transferAmount < 0) transferAmount = 0;

            final String qrData = _generateVietQRString(
              transferAmount.toDouble(),
            );

            // Padding adjusts automatically when the mobile keyboard pops up
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
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
                      'THANH TOÁN ĐƠN HÀNG',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng hóa đơn: $totalAmount đ',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Text field to enter cash received from customer
                    TextField(
                      controller: cashController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tiền mặt khách đưa (đ)',
                        hintText: 'Bỏ trống nếu khách chuyển khoản hết',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money, color: Colors.green),
                      ),
                      onChanged: (value) {
                        // Update cashAmount and redraw modal whenever mom types
                        setModalState(() {
                          cashAmount = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Display the remaining amount that needs to be transferred
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cần chuyển khoản:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$transferAmount đ',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Only show the QR Code if transferAmount is greater than 0
                    if (transferAmount > 0) ...[
                      Image.network(
                        qrData,
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Khách mở App Ngân hàng quét mã này là xong nhé!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Khách đã trả đủ bằng tiền mặt!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        // Close bottom sheet
                        Navigator.pop(context);

                        // Ensure cashAmount saved does not exceed totalAmount (in case customer gave extra cash)
                        int actualCashRevenue = cashAmount > totalAmount
                            ? totalAmount
                            : cashAmount;

                        // Deduct stock and save order to MySQL
                        await _processOrderAndDeductStock(
                          totalAmount,
                          actualCashRevenue,
                          transferAmount,
                        );
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
              ),
            );
          },
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
        // Add an icon button on the right side of the AppBar to open Revenue Report
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
            tooltip: 'Thêm trái cây mới',
            onPressed: _openAddFruitDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white, size: 28),
            tooltip: 'Xem doanh thu hôm nay',
            onPressed: () {
              // Navigate to RevenueReportScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RevenueReportScreen(),
                ),
              );
            },
          ),
        ],
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Kho: ${fruit['stock']} kg',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Edit icon button to open the edit dialog
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                          size: 22,
                                        ),
                                        tooltip: 'Sửa giá hoặc số ký',
                                        onPressed: () =>
                                            _openEditFruitDialog(fruit),
                                      ),
                                    ],
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

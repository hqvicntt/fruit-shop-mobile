import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  // Variables to store today's revenue summary
  int _totalRevenue = 0;
  int _totalCash = 0;
  int _totalTransfer = 0;

  // List of orders created today
  List<dynamic> _orders = [];
  bool _isLoading = true;

  // Fetch today's orders and revenue summary from Laravel API
  Future<void> _fetchTodayReport() async {
    final String computerIp = dotenv.env['COMPUTER_IP'] ?? '';
    final String apiUrl = 'http://$computerIp:8000/api/orders';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          setState(() {
            _totalRevenue = responseData['summary']['total_revenue'];
            _totalCash = responseData['summary']['total_cash'];
            _totalTransfer = responseData['summary']['total_transfer'];
            _orders = responseData['data'];
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load revenue report');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải báo cáo doanh thu: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTodayReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text(
          'Doanh Thu Hôm Nay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card showing Total, Cash, and Bank Transfer
                  Card(
                    color: Colors.green.shade50,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.green, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'TỔNG DOANH THU NGÀY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_totalRevenue đ',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Cash column / Cột tiền mặt
                              Column(
                                children: [
                                  const Text(
                                    'Tiền mặt trong túi',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_totalCash đ',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              // Bank Transfer column
                              Column(
                                children: [
                                  const Text(
                                    'Tiền chuyển khoản',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_totalTransfer đ',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chi tiết các đơn đã bán:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // List of today's orders
                  Expanded(
                    child: _orders.isEmpty
                        ? const Center(
                            child: Text(
                              'Hôm nay chưa có đơn hàng nào được lưu.',
                            ),
                          )
                        : ListView.builder(
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Text(
                                      '#${order['id']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    order['items_summary'] ??
                                        'Đơn hàng trái cây',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Tiền mặt: ${order['cash_amount']}đ | CK: ${order['transfer_amount']}đ',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  trailing: Text(
                                    '${order['total_amount']} đ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

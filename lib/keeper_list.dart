import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'keeper_form.dart';

class BeeKeeperListPage extends StatefulWidget {
  const BeeKeeperListPage({super.key});

  @override
  State<BeeKeeperListPage> createState() => _BeeKeeperListPageState();
}

class _BeeKeeperListPageState extends State<BeeKeeperListPage> {
  final String _baseUrl = "http://10.10.37.179/api_bee";
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> beeKeepers = [];

  @override
  void initState() {
    super.initState();
    fetchBeeKeepers();
  }

  Future<void> fetchBeeKeepers() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final url = Uri.parse("$_baseUrl/getdatabeekeeper.php");
      final response = await http.post(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          beeKeepers = List<Map<String, dynamic>>.from(data);
          setState(() {
            isLoading = false;
            error = null;
          });
        } else {
          setState(() {
            isLoading = false;
            error = 'รูปแบบข้อมูลไม่ถูกต้องจากเซิร์ฟเวอร์';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          error = 'เกิดข้อผิดพลาด: $e';
        });
      }
    }
  }

  void _openBeeKeeperForm({Map<String, dynamic>? beeKeeper}) {
    final formPage = BeeKeeperPage(
      xcase: beeKeeper == null ? 1 : 2,
      userId: beeKeeper?['ID']?.toString(),
      idCard: beeKeeper?['ID_card']?.toString(),
      firstName: beeKeeper?['First_name']?.toString(),
      lastName: beeKeeper?['Last_name']?.toString(),
      address: beeKeeper?['address']?.toString(),
      phone: beeKeeper?['phone']?.toString(),
      email: beeKeeper?['E_Mail']?.toString(),
      latitude: beeKeeper?['latitude']?.toString(),
      longitude: beeKeeper?['longitude']?.toString(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => formPage),
    ).then((_) {
      fetchBeeKeepers();
    });
  }

  Future<void> _deleteBeeKeeper(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจว่าต้องการลบผู้เลี้ยงผึ้งนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/deletebeekeeper.php"),
        body: {
          "userId": userId,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'ลบสำเร็จ')),
          );
          fetchBeeKeepers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'ลบไม่สำเร็จ')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายชื่อผู้เลี้ยงผึ้ง'),
        backgroundColor: Colors.orange,
        actions: [
          TextButton.icon(
            onPressed: () => _openBeeKeeperForm(),
            icon: Icon(Icons.add, color: Colors.white),
            label: const Text(
              'เพิ่ม',
              style: TextStyle(color: Colors.white),
            ),  
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchBeeKeepers,
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                )
              : (beeKeepers.isEmpty
                  ? const Center(
                      child: Text('ไม่มีข้อมูลผู้เลี้ยงผึ้ง'),
                    )
                  : ListView.builder(
                      itemCount: beeKeepers.length,
                      itemBuilder: (context, index) {
                        final bk = beeKeepers[index];
                        final firstName = bk['First_name'] ?? '-';
                        final lastName = bk['Last_name'] ?? '-';
                        final fullName = '$firstName $lastName';
                        final phone = bk['phone'] ?? '-';
                        final userId = bk['ID']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Text(fullName),
                            subtitle: Text('โทร: $phone'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _openBeeKeeperForm(beeKeeper: bk),
                                  child: const Text('แก้ไข', style:  TextStyle(color: Colors.blue)),
                                ),
                                TextButton(
                                  onPressed: () => _deleteBeeKeeper(userId),
                                  child: const Text('ลบ', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                            onTap: () => _openBeeKeeperForm(beeKeeper: bk),
                          ),
                        );
                      },
                    ))),
    );
  }
}

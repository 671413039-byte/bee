import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'harvest_records_form_page.dart';

class HarvestRecordsListPage extends StatefulWidget {
  final int? selectedMemberId;

  const HarvestRecordsListPage({
    super.key,
    this.selectedMemberId,
  });

  @override
  State<HarvestRecordsListPage> createState() => _HarvestRecordsListPageState();
}

class _HarvestRecordsListPageState extends State<HarvestRecordsListPage> {
  List<Map<String, dynamic>> records = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("http://10.10.37.179/api_bee/getallharvest_records.php"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            records = List<Map<String, dynamic>>.from(data["data"] ?? []);
            debugPrint("Loaded ${records.length} records");
            for (var record in records) {
              debugPrint("Record: ID=${record['ID']} (${record['ID'].runtimeType}), Date=${record['harvest_date']} (${record['harvest_date'].runtimeType}), BeehiveCount=${record['beehive_count']}, YieldBottles=${record['yield_bottles']}, Name=${record['member_name']}");
            }
          });
        } else {
          setState(() {
            errorMessage = data["message"] ?? "ไม่สามารถโหลดข้อมูล";
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาด: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteRecord(int recordId, String harvestDate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณแน่ใจหรือว่าต้องการลบข้อมูลนี้?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ลบ"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint("Deleting record: ID=$recordId, Date=$harvestDate");
      
      final response = await http.post(
        Uri.parse("http://10.10.37.179/api_bee/saveharvest_records.php"),
        body: {
          "xcase": "3",
          "recordId": recordId.toString(),
          "harvestDate": harvestDate,
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint("Delete response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "ลบสำเร็จ")),
          );
          _loadRecords();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "ลบไม่สำเร็จ")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  void _openForm({
    int? recordId,
    String? harvestDate,
    int? beehiveCount,
    int? yieldBottles,
    int? memberId,
    String? memberName,
    int? xcase,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => HarvestRecordsFormPage(
          recordId: recordId,
          harvestDate: harvestDate,
          beehiveCount: beehiveCount,
          yieldBottles: yieldBottles,
          memberId: memberId,
          memberName: memberName,
          xcase: xcase,
        ),
      ),
    );

    if (result == true) {
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("บันทึกการเก็บเกี่ยว"),
        backgroundColor: Colors.orange,
        actions: [
          TextButton.icon(
            onPressed: () => _openForm(xcase: 1),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'เพิ่ม',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecords,
                        child: const Text("ลองใหม่"),
                      ),
                    ],
                  ),
                )
              : records.isEmpty
                  ? const Center(
                      child: Text("ไม่มีข้อมูลการเก็บเกี่ยว"),
                    )
                  : ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final recordId = record['ID'] is int ? record['ID'] : int.parse(record['ID'].toString());
                        final beehiveCount = record['beehive_count'] is int ? record['beehive_count'] : int.parse(record['beehive_count'].toString());
                        final yieldBottles = record['yield_bottles'] is int ? record['yield_bottles'] : int.parse(record['yield_bottles'].toString());
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Text("${record['member_name'] ?? 'ไม่ระบุ'}"),
                            subtitle: Text(
                              "วันที่: ${record['harvest_date']} | รัง: ${record['beehive_count']} | ขวด: ${record['yield_bottles']}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _openForm(
                                      recordId: recordId,
                                      harvestDate: record['harvest_date'],
                                      beehiveCount: beehiveCount,
                                      yieldBottles: yieldBottles,
                                      memberId: recordId,
                                      memberName: record['member_name'],
                                      xcase: 2,
                                    );
                                  },
                                  child: const Text(
                                    'แก้ไข',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _deleteRecord(recordId, record['harvest_date']),
                                  child: const Text(
                                    'ลบ',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

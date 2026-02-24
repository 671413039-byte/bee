import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'harvest_report_form_page.dart';

class HarvestReportListPage extends StatefulWidget {
  const HarvestReportListPage({super.key});

  @override
  State<HarvestReportListPage> createState() => _HarvestReportListPageState();
}

class _HarvestReportListPageState extends State<HarvestReportListPage> {
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> beekeepers = [];
  bool isLoading = false;
  bool isLoadingBeekeepers = false;
  String? errorMessage;
  
  String filterType = "all"; // "all" หรือ "individual"
  int? selectedMemberId;

  @override
  void initState() {
    super.initState();
    _loadBeekeepers();
    _loadReports();
  }

  Future<void> _loadBeekeepers() async {
    setState(() {
      isLoadingBeekeepers = true;
    });

    try {
      final response = await http.get(
        Uri.parse("http://10.10.37.179/api_bee/getallbeekeeper.php"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            beekeepers = List<Map<String, dynamic>>.from(data["data"] ?? []);
            debugPrint("Loaded ${beekeepers.length} beekeepers");
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading beekeepers: $e");
    } finally {
      setState(() {
        isLoadingBeekeepers = false;
      });
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String url = "http://10.10.37.179/api_bee/getallharvest_report.php";
      
      if (filterType == "individual" && selectedMemberId != null) {
        url += "?memberId=$selectedMemberId";
      }

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            reports = List<Map<String, dynamic>>.from(data["data"] ?? []);
            debugPrint("Loaded ${reports.length} reports");
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

  double _calculateTotalBeehives() {
    if (reports.isEmpty) return 0;
    double total = 0;
    for (var report in reports) {
      int count = report['beehive_count'] is int
          ? report['beehive_count']
          : int.parse(report['beehive_count'].toString());
      total += count;
    }
    return total;
  }

  double _calculateTotalYield() {
    if (reports.isEmpty) return 0;
    double total = 0;
    for (var report in reports) {
      int count = report['yield_bottles'] is int
          ? report['yield_bottles']
          : int.parse(report['yield_bottles'].toString());
      total += count;
    }
    return total;
  }

  Future<void> _deleteReport(int id, String harvestDate) async {
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
      debugPrint("Deleting report: ID=$id, HarvestDate=$harvestDate");
      
      final response = await http.post(
        Uri.parse("http://10.10.37.179/api_bee/saveharvest_report.php"),
        body: {
          "xcase": "3",
          "id": id.toString(),
          "oldHarvestDate": harvestDate,
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint("Delete response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "ลบสำเร็จ")),
          );
          _loadReports();
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
    int? memberId,
    String? harvestDate,
    int? beehiveCount,
    int? yieldBottles,
    String? memberName,
    int? xcase,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => HarvestReportFormPage(
          memberId: memberId,
          harvestDate: harvestDate,
          beehiveCount: beehiveCount,
          yieldBottles: yieldBottles,
          memberName: memberName,
          xcase: xcase,
        ),
      ),
    );

    if (result == true) {
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายงานผลผลิต"),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนตัวกรอง
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ตัวเลือกประเภทการกรอง
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ตัวกรองข้อมูล",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RadioListTile<String>(
                            title: const Text("ทั้งหมด"),
                            value: "all",
                            groupValue: filterType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  filterType = value;
                                  selectedMemberId = null;
                                });
                                _loadReports();
                              }
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text("ผู้เลี้ยงผึ้งรายบุคคล"),
                            value: "individual",
                            groupValue: filterType,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  filterType = value;
                                });
                              }
                            },
                          ),
                          if (filterType == "individual")
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 12.0),
                              child: isLoadingBeekeepers
                                  ? const CircularProgressIndicator()
                                  : DropdownButtonFormField<int>(
                                      value: selectedMemberId,
                                      hint: const Text("เลือกผู้เลี้ยงผึ้ง"),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      items: beekeepers.map((bk) {
                                        int id = bk['ID'] is int
                                            ? bk['ID']
                                            : int.parse(bk['ID'].toString());
                                        String name =
                                            "${bk['First name']} ${bk['Last name']}";
                                        return DropdownMenuItem<int>(
                                          value: id,
                                          child: Text(name),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedMemberId = value;
                                          });
                                          _loadReports();
                                        }
                                      },
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ส่วนแสดงข้อมูล
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadReports,
                      child: const Text("ลองใหม่"),
                    ),
                  ],
                ),
              )
            else if (reports.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("ไม่มีข้อมูลการเก็บเกี่ยว"),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // ตารางแสดงข้อมูล
                    Card(
                      elevation: 4,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reports.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          final memberId = report['id'] is int ? report['id'] : int.parse(report['id'].toString());
                          final beehiveCount = report['beehive_count'] is int ? report['beehive_count'] : int.parse(report['beehive_count'].toString());
                          final yieldBottles = report['yield_bottles'] is int ? report['yield_bottles'] : int.parse(report['yield_bottles'].toString());
                          
                          return ListTile(
                            title: Text("${report['member_name'] ?? 'ไม่ระบุ'}"),
                            subtitle: Text(
                              "วันที่: ${report['harvest_date']} | รัง: ${report['beehive_count']} | ขวด: ${report['yield_bottles']}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _openForm(
                                      memberId: memberId,
                                      harvestDate: report['harvest_date'],
                                      beehiveCount: beehiveCount,
                                      yieldBottles: yieldBottles,
                                      memberName: report['member_name'],
                                      xcase: 2,
                                    );
                                  },
                                  child: const Text(
                                    'แก้ไข',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _deleteReport(memberId, report['harvest_date']),
                                  child: const Text(
                                    'ลบ',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

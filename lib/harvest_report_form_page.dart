import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class HarvestReportFormPage extends StatefulWidget {
  final int? memberId;
  final String? harvestDate;
  final int? beehiveCount;
  final int? yieldBottles;
  final String? memberName;
  final int? xcase;

  const HarvestReportFormPage({
    super.key,
    this.memberId,
    this.harvestDate,
    this.beehiveCount,
    this.yieldBottles,
    this.memberName,
    this.xcase,
  });

  @override
  State<HarvestReportFormPage> createState() => _HarvestReportFormPageState();
}

class _HarvestReportFormPageState extends State<HarvestReportFormPage> {
  late TextEditingController harvestDateController;
  late TextEditingController beehiveCountController;
  late TextEditingController yieldBottlesController;
  List<Map<String, dynamic>> beekeepers = [];
  bool isLoadingBeekeepers = false;
  int? selectedMemberId;

  @override
  void initState() {
    super.initState();
    harvestDateController = TextEditingController();
    beehiveCountController = TextEditingController();
    yieldBottlesController = TextEditingController();

    harvestDateController.text = widget.harvestDate ?? "";
    beehiveCountController.text = widget.beehiveCount?.toString() ?? "";
    yieldBottlesController.text = widget.yieldBottles?.toString() ?? "";
    
    // เมื่อแก้ไข ให้แปลง memberId เป็น int
    if (widget.xcase == 2 && widget.memberId != null) {
      selectedMemberId = widget.memberId is int 
          ? widget.memberId 
          : int.parse(widget.memberId.toString());
    } else {
      selectedMemberId = null;
    }

    _loadBeekeepers();
  }

  @override
  void dispose() {
    harvestDateController.dispose();
    beehiveCountController.dispose();
    yieldBottlesController.dispose();
    super.dispose();
  }

  int? _getSelectedValue() {
    if (selectedMemberId == null) return null;
    if (beekeepers.isEmpty) return selectedMemberId;
    
    // ตรวจสอบว่า selectedMemberId มีอยู่ในรายการหรือไม่
    for (var bk in beekeepers) {
      int id = bk['ID'] is int ? bk['ID'] : int.parse(bk['ID'].toString());
      if (id == selectedMemberId) {
        return selectedMemberId;
      }
    }
    
    // ถ้าไม่พบ ให้คืน null
    return null;
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
            debugPrint("selectedMemberId: $selectedMemberId");
            
            // เมื่อแก้ไข ให้ตรวจสอบผู้เลี้ยง
            if (widget.xcase == 2 && selectedMemberId != null) {
              for (var bk in beekeepers) {
                int id = bk['ID'] is int ? bk['ID'] : int.parse(bk['ID'].toString());
                debugPrint("Checking beekeeper ID: $id vs selectedMemberId: $selectedMemberId");
                if (id == selectedMemberId) {
                  debugPrint("Found matching beekeeper!");
                  break;
                }
              }
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e")),
      );
    } finally {
      setState(() {
        isLoadingBeekeepers = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: harvestDateController.text.isNotEmpty
          ? DateTime.parse(harvestDateController.text)
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        harvestDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitRecord() async {
    final dateText = harvestDateController.text.trim();
    final beehiveCountText = beehiveCountController.text.trim();
    final yieldBottlesText = yieldBottlesController.text.trim();

    if (dateText.isEmpty || beehiveCountText.isEmpty || yieldBottlesText.isEmpty || selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วน")),
      );
      return;
    }

    if (widget.xcase == null || widget.xcase == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาด: ไม่สามารถระบุชนิดการดำเนินการได้")),
      );
      return;
    }

    try {
      debugPrint("Submitting record - xcase: ${widget.xcase}, id: $selectedMemberId, Date: $dateText, BeehiveCount: $beehiveCountText, YieldBottles: $yieldBottlesText");
      
      final Map<String, String> body = {
        "xcase": widget.xcase.toString(),
        "id": selectedMemberId.toString(),
        "harvestDate": dateText,
        "beehiveCount": beehiveCountText,
        "yieldBottles": yieldBottlesText,
      };
      
      // สำหรับแก้ไข ต้องส่ง oldHarvestDate เพื่อจัดการ composite key
      if (widget.xcase == 2 && widget.harvestDate != null) {
        body["oldHarvestDate"] = widget.harvestDate!;
      }
      
      final response = await http.post(
        Uri.parse("http://10.10.37.179/api_bee/saveharvest_report.php"),
        body: body,
      ).timeout(const Duration(seconds: 15));

      debugPrint("Save response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "บันทึกสำเร็จ")),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "บันทึกไม่สำเร็จ")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode} - ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = "";

    if (widget.xcase == 1) {
      titleText = "เพิ่มรายงานผลผลิต";
    } else if (widget.xcase == 2) {
      titleText = "แก้ไขรายงานผลผลิต";
    } else {
      titleText = "รายงานผลผลิต";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown เลือกผู้เลี้ยงผึ้ง
            if (isLoadingBeekeepers)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              )
            else if (beekeepers.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _getSelectedValue(),
                decoration: const InputDecoration(
                  labelText: "เลือกผู้เลี้ยงผึ้ง",
                  border: OutlineInputBorder(),
                ),
                items: beekeepers.map((bk) {
                  int id = bk['ID'] is int ? bk['ID'] : int.parse(bk['ID'].toString());
                  String name = "${bk['First name']} ${bk['Last name']}";
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: widget.xcase == 2 ? null : (value) {
                  if (value != null) {
                    setState(() {
                      selectedMemberId = value;
                    });
                  }
                },
              )
            else
              const Text("ไม่พบข้อมูลผู้เลี้ยงผึ้ง"),
            const SizedBox(height: 12),

            // วันที่เก็บเกี่ยว
            TextField(
              controller: harvestDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "วันที่เก็บเกี่ยว",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 12),

            // จำนวนรัง
            TextField(
              controller: beehiveCountController,
              decoration: const InputDecoration(
                labelText: "จำนวนรัง",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 12),

            // จำนวนขวด
            TextField(
              controller: yieldBottlesController,
              decoration: const InputDecoration(
                labelText: "จำนวนขวด",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 20),

            // ปุ่ม
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _submitRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("บันทึก"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text("ยกเลิก"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

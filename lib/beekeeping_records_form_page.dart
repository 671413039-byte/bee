import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class BeekeepingRecordsFormPage extends StatefulWidget {
  final int? recordId;
  final String? recordDate;
  final int? amount;
  final int? memberId;
  final String? memberName;
  final int? xcase;

  const BeekeepingRecordsFormPage({
    super.key,
    this.recordId,
    this.recordDate,
    this.amount,
    this.memberId,
    this.memberName,
    this.xcase,
  });

  @override
  State<BeekeepingRecordsFormPage> createState() => _BeekeepingRecordsFormPageState();
}

class _BeekeepingRecordsFormPageState extends State<BeekeepingRecordsFormPage> {
  late TextEditingController recordDateController;
  late TextEditingController amountController;
  List<Map<String, dynamic>> beekeepers = [];
  bool isLoadingBeekeepers = false;
  int? selectedMemberId;

  @override
  void initState() {
    super.initState();
    recordDateController = TextEditingController();
    amountController = TextEditingController();

    recordDateController.text = widget.recordDate ?? "";
    amountController.text = widget.amount?.toString() ?? "";
    
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
    recordDateController.dispose();
    amountController.dispose();
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
      initialDate: recordDateController.text.isNotEmpty
          ? DateTime.parse(recordDateController.text)
          : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        recordDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitRecord() async {
    final dateText = recordDateController.text.trim();
    final amountText = amountController.text.trim();

    if (dateText.isEmpty || amountText.isEmpty || selectedMemberId == null) {
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
      debugPrint("Submitting record - xcase: ${widget.xcase}, ID: ${widget.recordId}, OriginalDate: ${widget.recordDate}, NewDate: $dateText, Amount: $amountText, MemberId: $selectedMemberId");
      
      final response = await http.post(
        Uri.parse("http://10.10.37.179/api_bee/savebeekeeping_records.php"),
        body: {
          "xcase": widget.xcase.toString(),
          "recordId": widget.recordId?.toString() ?? "",
          "recordDate": widget.xcase == 2 ? (widget.recordDate ?? dateText) : dateText,
          "newRecordDate": widget.xcase == 2 ? dateText : "",
          "amount": amountText,
          "memberId": selectedMemberId.toString(),
        },
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
      titleText = "เพิ่มบันทึกการเลี้ยงผึ้ง";
    } else if (widget.xcase == 2) {
      titleText = "แก้ไขบันทึกการเลี้ยงผึ้ง";
    } else {
      titleText = "บันทึกการเลี้ยงผึ้ง";
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

            // วันที่
            TextField(
              controller: recordDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "วันที่ที่บันทึก",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 12),

            // จำนวน
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: "จำนวน",
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

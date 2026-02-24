

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';



class BeeKeeperPage extends StatefulWidget {
  final String? userId;
  final String? idCard;
  final String? firstName;
  final String? lastName;
  final String? address;
  final String? phone;
  final String? email;
  final String? latitude;
  final String? longitude;
  final int? xcase;

  const BeeKeeperPage({
    super.key,
    this.userId,
    this.idCard,
    this.firstName,
    this.lastName,
    this.address,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.xcase,
  });

  @override
  State<BeeKeeperPage> createState() => _BeeKeeperPageState();
}

class _BeeKeeperPageState extends State<BeeKeeperPage> {
  late TextEditingController userIdController;
  late TextEditingController idCardController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController latitudeController;
  late TextEditingController longitudeController;
  final MapController mapController = MapController();
  LatLng _markerPos = LatLng(15.87, 100.99);  

  @override
  void initState() {
    super.initState();
    userIdController = TextEditingController();
    idCardController = TextEditingController();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    addressController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    latitudeController = TextEditingController();
    longitudeController = TextEditingController();

    userIdController.text = widget.userId ?? "";
    idCardController.text = widget.idCard ?? "";
    firstNameController.text = widget.firstName ?? "";
    lastNameController.text = widget.lastName ?? "";
    addressController.text = widget.address ?? "";
    phoneController.text = widget.phone ?? "";
    emailController.text = widget.email ?? "";
    latitudeController.text = widget.latitude ?? "";
    longitudeController.text = widget.longitude ?? "";

    if (widget.latitude != null && widget.longitude != null) {
      double? lat = double.tryParse(widget.latitude ?? "");
      double? lng = double.tryParse(widget.longitude ?? "");
      if (lat != null && lng != null) {
        _markerPos = LatLng(lat, lng);
      }
    }
  }

  @override
  void dispose() {
    userIdController.dispose();
    idCardController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }


  Future<void> _setInitialLocationFromUser() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      if (result == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("กรุณาอนุญาต Location ในการตั้งค่าเครื่อง"),
          ),
        );
        return;
      }
    }
    
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng userLatLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _markerPos = userLatLng;
      latitudeController.text = position.latitude.toStringAsFixed(6);
      longitudeController.text = position.longitude.toStringAsFixed(6);
    });
    
    mapController.move(userLatLng, 16);
  }

  void _updateLatLng(LatLng point) {
    setState(() {
      _markerPos = point;
      latitudeController.text = point.latitude.toStringAsFixed(6);
      longitudeController.text = point.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _submitBeeKeeper() async {
    final firstNameText = firstNameController.text.trim();
    final lastNameText = lastNameController.text.trim();
    final addressText = addressController.text.trim();
    final phoneText = phoneController.text.trim();
    final emailText = emailController.text.trim();
    final lat = latitudeController.text.trim();
    final lng = longitudeController.text.trim();
    final idCardText = idCardController.text.trim();

    
    if (firstNameText.isEmpty ||
        lastNameText.isEmpty ||
        addressText.isEmpty ||
        phoneText.isEmpty ||
        emailText.isEmpty ||
        idCardText.isEmpty) {
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
      final response = await http.post(
        Uri.parse("http://10.10.37.179/api_bee/savedatabeekeeper.php"),
        body: {
          "xcase": widget.xcase.toString(),
          "userId": widget.userId ?? "",
          "idCard": idCardText,
          "firstName": firstNameText,
          "lastName": lastNameText,
          "address": addressText,
          "phone": phoneText,
          "email": emailText,
          "latitude": lat,
          "longitude": lng,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "บันทึกสำเร็จ")),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "บันทึกไม่สำเร็จ")),
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

  @override
  Widget build(BuildContext context) {
    
    List<TextInputFormatter> numericInputFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
    ];

    String titleText = "";

    if (widget.xcase == 1) {
      titleText = "เพิ่มผู้เลี้ยงผึ้ง";
    } else if (widget.xcase == 2) {
      titleText = "แก้ไขผู้เลี้ยงผึ้ง";
    } else if (widget.xcase == 3) {
      titleText = "ยกเลิกผู้เลี้ยงผึ้ง";
    } else {
      titleText = "ผู้เลี้ยงผึ้ง";
    }

    return Scaffold(
      appBar: AppBar(title: Text(titleText), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            
            TextField(
              controller: userIdController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: "รหัส",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            
            TextField(
              controller: idCardController,
              decoration: const InputDecoration(
                labelText: "รหัสประจำตัวประชาชน",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
            ),
            const SizedBox(height: 12),

            
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: "ชื่อจริง",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: "นามสกุล",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "ที่อยู่",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "เบอร์โทรศัพท์",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 12),

            
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "อีเมล",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            
            TextField(
              controller: latitudeController,
              decoration: InputDecoration(
                labelText: "ละติจูด",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _setInitialLocationFromUser,
                ),
              ),
              readOnly: true,
              inputFormatters: numericInputFormatter,
            ),
            const SizedBox(height: 12),

            
            TextField(
              controller: longitudeController,
              decoration: const InputDecoration(
                labelText: "ลองจิจูด",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              inputFormatters: numericInputFormatter,
            ),
            const SizedBox(height: 16),

            
            SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: _markerPos,
                  initialZoom: 13,
                  onTap: (tapPosition, latLng) => _updateLatLng(latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'bee_671413039',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _markerPos,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _submitBeeKeeper,
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

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BeeKeeperLocationPage extends StatefulWidget {
	const BeeKeeperLocationPage({super.key});

	@override
	State<BeeKeeperLocationPage> createState() => _BeeKeeperLocationPageState();
}

class _BeeKeeperLocationPageState extends State<BeeKeeperLocationPage> {
		final String _baseUrl = "http://192.168.171.1/api_bee";
	bool isLoading = true;
	String? error;
	List<Map<String, dynamic>> beeKeepers = [];
	MapController mapController = MapController();

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

	List<Marker> _buildMarkers() {
		final List<Marker> markers = [];
		for (final bk in beeKeepers) {
			try {
				final latVal = bk['latitude'];
				final lngVal = bk['longitude'];
				String latStr = latVal?.toString() ?? '';
				String lngStr = lngVal?.toString() ?? '';
				final lat = double.tryParse(latStr);
				final lng = double.tryParse(lngStr);
				if (lat != null && lng != null) {
					final firstName = bk['firstName'] ?? '-';
					final lastName = bk['lastName'] ?? '-';
					final fullName = '$firstName $lastName';
					
					markers.add(Marker(
						point: LatLng(lat, lng),
						width: 180,
						height: 90,
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Container(
									padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
									decoration: BoxDecoration(
										color: Colors.white,
										borderRadius: BorderRadius.circular(8),
										boxShadow: [
											BoxShadow(
												color: Colors.black.withOpacity(0.15),
												blurRadius: 4,
												offset: const Offset(0, 2),
											),
										],
									),
									child: Text(
										fullName,
										style: const TextStyle(
											color: Color(0xFF1976D2),
											fontWeight: FontWeight.bold,
											fontSize: 14,
										),
										textAlign: TextAlign.center,
										overflow: TextOverflow.ellipsis,
										maxLines: 2,
									),
								),
								GestureDetector(
									onTap: () => _showBeeKeeperDetail(bk),
									child: const Icon(
										Icons.location_on,
										size: 40,
										color: Colors.red,
									),
								),
							],
						),
					));
				}
			} catch (_) {
				continue;
			}
		}
		return markers;
	}

	void _showBeeKeeperDetail(Map<String, dynamic> bk) {
		showModalBottomSheet(
			context: context,
			builder: (context) {
				final firstName = bk['firstName'] ?? '-';
				final lastName = bk['lastName'] ?? '-';
				final fullName = '$firstName $lastName';
				
				return Padding(
					padding: const EdgeInsets.all(16.0),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								fullName,
								style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
							),
							const SizedBox(height: 8),
							Text('รหัสประจำตัว: ${bk['idCard'] ?? '-'}'),
							const SizedBox(height: 8),
							Text('ที่อยู่: ${bk['address'] ?? '-'}'),
							const SizedBox(height: 8),
							Text('โทร: ${bk['phone'] ?? '-'}'),
							const SizedBox(height: 8),
							Text('อีเมล: ${bk['email'] ?? '-'}'),
							const SizedBox(height: 12),
							Row(
								mainAxisAlignment: MainAxisAlignment.end,
								children: [
									TextButton(
										onPressed: () => Navigator.pop(context),
										child: const Text('ปิด'),
									),
								],
							),
						],
					),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final markers = _buildMarkers();

		LatLng initialCenter = LatLng(15.87, 100.99);
		if (markers.isNotEmpty) {
			initialCenter = markers.first.point;
		}

		return Scaffold(
			appBar: AppBar(
				title: const Text('แผนที่ผู้เลี้ยงผึ้ง'),
				backgroundColor: Colors.orange,
				actions: [
					IconButton(
						icon: const Icon(Icons.refresh),
						onPressed: fetchBeeKeepers,
					),
				],
			),
			body: isLoading
					? const Center(child: CircularProgressIndicator())
					: (error != null
							? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
							: FlutterMap(
									mapController: mapController,
									options: MapOptions(
										initialCenter: initialCenter,
										initialZoom: 6.5,
									),
									children: [
										TileLayer(
											urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
											subdomains: const ['a', 'b', 'c'],
											userAgentPackageName: 'bee_671413039',
										),
										MarkerLayer(markers: markers),
									],
								)),
		);
	}
}


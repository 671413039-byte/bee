import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'keeper_list.dart';
import 'keeper_Location.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {"title": "รายชื่อผู้เลี้ยงผึ้ง", "image": "images/honey-realistic-abstract-composition-with-bees-sitting-amber-honeycombs-vector-illustration_1284-84092.jpg"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("เมนูหลัก"),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.orange[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Quit',
            onPressed: () {
              if (Platform.isAndroid || Platform.isIOS) {
                SystemNavigator.pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;
            int crossAxisCount = (width < 400) ? 2 : (width < 700) ? 3 : 4;
            double fontSize = (width < 400) ? 14 : (width < 700) ? 16 : 18;

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return GestureDetector(
                    onTap: () {
                      switch (index) {
                        case 0:
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BeeKeeperListPage()));
                          break;
                        case 1:
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const BeeKeeperLocationPage()));
                          break;

                      }
                    },
                    child: Card(
                      color: Colors.amber[50],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.asset(
                                item['image'],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),

    );
  }
}
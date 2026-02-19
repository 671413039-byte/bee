import 'package:flutter/material.dart';
import 'menu.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'images/honey-realistic-abstract-composition-with-bees-sitting-amber-honeycombs-vector-illustration_1284-84092.jpg',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20.0),
            Text(
              'Welcome!!',
              style: TextStyle(
                fontSize: 30,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            SizedBox(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MenuPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  fixedSize: Size(300, 50),
                  side: BorderSide(
                    color: Color.fromARGB(255, 164, 128, 225),
                    width: 2.0,
                  ),
                  backgroundColor: Color.fromARGB(255, 164, 128, 225),
                ),
                child: Text(
                  'เริ่มใช้งาน',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
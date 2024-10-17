import 'package:flutter/material.dart';
import 'create_page.dart';

// 홈 페이지
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text("Let's work!",
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              )),

          // 아이콘 버튼 기능
          Center(
            child: IconButton(
              onPressed: () {
                // 버튼 클릭 시 수행할 작업
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePage()),
                );
              },
              icon: Icon(
                Icons.add_alarm,
                size: 100,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
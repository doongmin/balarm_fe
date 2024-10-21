import 'package:flutter/material.dart';
import 'create_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 홈 페이지
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isTokenMissing = false; // 토큰이 없는지 확인할 변수

  @override
  void initState() {
    super.initState();
    _checkToken(); // 페이지 로딩 시 토큰 확인
  }

  // 토큰 확인 함수
  Future<void> _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    setState(() {
      isTokenMissing = accessToken == null; // 토큰이 없으면 true, 있으면 false
    });
  }

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
                if (isTokenMissing) {
                  // 토큰이 없을 때는 팝업을 띄움
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          '로그인 필요',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          '계속하려면 로그인 해주세요.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 팝업 닫기
                            },
                            child: Text('확인'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // 버튼 클릭 시 수행할 작업
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreatePage()),
                  );
                }
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

import 'package:bungry_alarm/main.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bungry_alarm/login_page.dart';


class SettingsPage extends StatelessWidget {
  final Dio dio = Dio(); // Dio 인스턴스 생성

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: const Color.fromARGB(255, 185, 185, 185),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 화면 중앙에 위치
          children: [
            ElevatedButton(
              onPressed: () {
                // 로그아웃 버튼 클릭 시 수행할 로직
                _logout(context);
              },
              child: Text('로그아웃'),
              style: OutlinedButton.styleFrom(
                  minimumSize: Size(200, 50), // 버튼 크기 조정
                  side:
                      BorderSide(width: 2.0, color: Colors.blue), // 테두리 두께와 색상
                  textStyle: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20), // 버튼 사이 간격
            ElevatedButton(
              onPressed: () {
                // 회원탈퇴 버튼 클릭 시 수행할 로직
                _withdraw(context);
              },
              child: Text('회원탈퇴'),
              style: OutlinedButton.styleFrom(
                  minimumSize: Size(200, 50), // 버튼 크기 조정
                  side: BorderSide(
                      width: 2.0,
                      color: Color.fromARGB(255, 255, 0, 0)), // 테두리 두께와 색상
                  textStyle: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 로그아웃 기능
  void _logout(BuildContext context) async {
    try {
      // SharedPreferences에서 저장된 토큰 가져오기
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? refreshToken = prefs.getString('refresh_token');

      // API 요청 보내기
      final response = await dio.post(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/logout/', // 로그아웃 API URL
        data: {
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // 토큰 헤더에 추가
          },
        ),
      );

      if (response.statusCode == 205) {
        // 로그아웃 성공 시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 되었습니다.')),
        );

        // SharedPreferences에서 토큰 삭제
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');

        // 로그인 페이지로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(isLoggedIn: false,), // LoginPage로 이동
          ),
          (Route<dynamic> route) => false, // 모든 이전 라우트
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: ${response.statusMessage}')),
        );
        print(response.statusMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 오류: $e')),
      );
    }
  }

  // 회원탈퇴 기능
  void _withdraw(BuildContext context) async {
    try {
      // SharedPreferences에서 user_id 가져오기
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    int? user_id = prefs.getInt('user_id');

      // API 요청 보내기
      final response = await dio.post(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/withdraw/', // 회원탈퇴 API URL
        data: {
          "user_id": user_id,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // 토큰 헤더에 추가
          },
        ),
      );

      if (response.statusCode == 204) {
        // 회원탈퇴 성공 시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원탈퇴 되었습니다.')),
        );

        // SharedPreferences에서 토큰 삭제
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_id');

        // 로그인 페이지로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(), // LoginPage로 이동
          ),
          (Route<dynamic> route) => false, // 모든 이전 라우트를 제거
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원탈퇴 실패: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 오류: $e')),
      );
    }
  }
}

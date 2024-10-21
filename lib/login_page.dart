import 'package:bungry_alarm/main.dart';
import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:platform/platform.dart';


// 로그인 페이지
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // TextEditingController를 사용해 입력된 값을 가져옴
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Dio dio = Dio();
  final Platform platform = LocalPlatform(); // 플랫폼 정보 가져오기

// 토큰을 SharedPreferences에 저장하는 함수
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);

// 저장된 토큰을 콘솔에 출력 (테스트용)
    print('Access Token: $accessToken');
    print('Refresh Token: $refreshToken');
  }

  // user_id 저장하는 함수
  Future<void> saveUserId(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);

    // 저장된 user_id 출력 (테스트용)
    print('User ID: $userId');
  }

  // 로그인 함수 (추후 서버와 연동할 때 사용할 수 있음)
  Future<void> _login() async {
    String id = idController.text;
    String password = passwordController.text;

    if (id.isEmpty || password.isEmpty) {
      // 간단한 유효성 검사
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아이디와 비밀번호를 입력하세요.')),
      );
      return;
    } 

    // 기기 유형 확인
    String deviceType = platform.isIOS ? 'ios' : 'android';

      // 서버로 보낼 데이터
      Map<String, dynamic> requestData = {
        "b_id": id,
        "password": password,
        "device_type": deviceType,
      };

      // requestData 출력
      print('Request Data: $requestData');

      try {
        // POST 요청 보내기
        Response response = await dio.post(
          'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/token/', // 회원가입 API URL
          data: requestData,
          options: Options(
            validateStatus: (status) => true, // 모든 상태 코드 허용
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          String accessToken = data['access'];
          String refreshToken = data['refresh'];
          int userId = data['user_id'];

          await saveUserId(userId); // user_id 저장
          await saveTokens(accessToken, refreshToken); // 토큰 저장

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 성공!')),
          );

          // 성공 시 다음 페이지로 이동 또는 다른 작업
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage(isLoggedIn: true,)),
          );
        } else if (response.statusCode == 401) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('로그인 오류'),
                content: Text('아이디와 비밀번호를 다시 확인해 주세요.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // 다이얼로그 닫기
                    },
                    child: Text('확인'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 실패. 다시 시도하세요.')),
          );
        }
      } on DioError catch (e) {
        print('DioError: $e'); // 오류가 발생한 경우, 콘솔에 출력
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류: $e')),
        );
      }
    }
  

  // 저장된 토큰을 불러오는 함수
  Future<Map<String, String?>> getTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }

  @override
  void initState() {
    super.initState();
    getTokens(); // 앱 시작 시 저장된 토큰 불러오기
  }

  // 회원가입 페이지로 이동하는 함수
  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpPage()), // 회원가입 페이지로 이동
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: SingleChildScrollView (
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/logo.png',
                width: MediaQuery.of(context).size.width * 0.5,
              ),
            ),
            SizedBox(height: 20.0),

            // ID 입력 필드
            TextField(
              controller: idController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),

            // 비밀번호 입력 필드
            TextField(
              controller: passwordController,
              obscureText: true, // 비밀번호 텍스트 숨김
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24.0),

            // 로그인 버튼
            ElevatedButton(
              onPressed: _login,
              child: Text('로그인'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // 버튼 너비와 높이 조정
              ),
            ),
            SizedBox(height: 12.0),

            // 회원가입 버튼
            ElevatedButton(
              onPressed: _navigateToSignUp, // 회원가입 페이지로 이동
              child: Text('회원가입'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // 버튼 너비와 높이 조정
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // TextEditingController 해제
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

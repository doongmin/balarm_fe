import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'login_page.dart';

// 회원가입 페이지
class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Dio dio = Dio();

  // 회원가입 요청 함수
  Future<void> _signUp() async {
    String name = nameController.text.trim();
    String id = idController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        id.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      // 유효성 검사
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요.')),
      );
      return;
    } else if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    } else {
      // 회원가입 처리 (서버로 보내기)
      // 서버로 보낼 데이터
      Map<String, dynamic> requestData = {
        "b_id": id,
        "nickname": name,
        "password": password,
      };

      // requestData 출력
      print('Request Data: $requestData');

      try {
        // POST 요청 보내기
        Response response = await dio.post(
          'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/signup/', // 회원가입 API URL
          data: requestData,
        );

        // 서버 응답 로그 찍기
        print('Response Status Code: ${response.statusCode}');
        print('Response Data: ${response.data}'); // 서버 응답 로그 출력

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원가입 성공!')),
          );

          // 성공 시 다음 페이지로 이동 또는 다른 작업
          // 성공 시 로그인 페이지로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => LoginPage()), // LoginPage로 수정 필요
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원가입 실패: ${response.statusMessage}')),
          );
        }
      } on DioError catch (dioError) {
        if (dioError.response?.statusCode == 400) {
          // 서버에서 받은 에러 코드에 따른 처리
          final errorResponse = dioError.response?.data;
          if (errorResponse != null && errorResponse['error'] != null) {
            String errorCode = errorResponse['error'].toString();

            // 에러 코드에 따른 메시지 처리
            switch (errorCode) {
              case "0":
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('중복된 아이디가 존재합니다.')),
                );
                break;
              case "1":
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('아이디는 영어, 숫자로만 입력해주세요.')),
                );
                break;
              case "2":
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('비밀번호는 영어, 숫자로만 입력해주세요.')),
                );
                break;
              case "3":
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('비밀번호는 8글자 이상이어야 합니다.')),
                );
                break;
              default:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('회원가입 실패: 알 수 없는 오류가 발생했습니다.')),
                );
                break;
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('회원가입 실패: ${dioError.message}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 오류: ${dioError.message}')),
          );
        }
      } catch (e) {
        print('Error: $e'); // 오류가 발생한 경우, 콘솔에 출력
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 150,
            ),
            //닉네임 입력 필드
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),

            // id 입력 필드
            TextField(
              controller: idController,
              decoration: InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),

            // 비밀번호 입력 필드
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),

            // 비밀번호 확인 입력 필드
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24.0),

            // 회원가입 버튼
            ElevatedButton(
              onPressed: _signUp,
              child: Text('회원가입'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
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
    nameController.dispose();
    idController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

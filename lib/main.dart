import 'package:bungry_alarm/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'notification_dialog.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 각 탭에 해당하는 페이지들 정의
import 'pages/home_page.dart';
import 'pages/today_page.dart';
import 'pages/calendar_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 바인딩 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase 초기화
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스
  PageController _pageController = PageController();
  Timer? _refreshTokenTimer; // 리프레시 토큰 재발급용 타이머
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadUserId();

    // 알림 권한 요청
    FirebaseMessaging.instance.requestPermission(
      badge: true,
      alert: true,
      sound: true,
    );
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('user_id');

    // 웹소켓 연결
    _channel = IOWebSocketChannel.connect(
        'wss://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/ws/alarm/?user_id=${userID.toString()}');

    // 수신된 메시지 처리
    _channel.stream.listen((message) {
      try {
        // 서버에서 받은 메시지를 JSON으로 디코드
        var decodedMessage = jsonDecode(message);

        // 'message' 키로부터 실제 내용을 추출
        var alarmTitle = decodedMessage['message'];
        var alarmTime = decodedMessage['time'];

        // 알림 다이얼로그 표시 (alarmTitle이 포함된 내용)
        NotificationDialog.show(context, alarmTitle, alarmTime);
      } catch (e) {
        print('메시지 처리 중 오류 발생: $e');
      }
    });

// FCM 토큰 발급
    String? _fcmToken = await FirebaseMessaging.instance.getToken();
    if (_fcmToken != null) {
      // 발급받은 토큰을 로그에 출력
      print("FCM Token: $_fcmToken");

      // 서버에 FCM 토큰 전송
      await sendFcmTokenToServer(_fcmToken);
    } else {
      print('FCM Token 발급 실패');
    }

    // 50분마다 리프레시 토큰을 재발급하는 타이머
    _refreshTokenTimer = Timer.periodic(Duration(minutes: 50), (timer) async {
      await refreshToken(); // 토큰 재발급 함수
    });
  }

// 토큰 전송 함수
  Future<void> sendFcmTokenToServer(String fcmToken) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken =
          prefs.getString('access_token'); // Access Token 가져오기

      var response = await Dio().post(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/fcm/', // 서버 URL 
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // Bearer 형식으로 토큰 포함
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'fcm_token': fcmToken, // FCM 토큰 포함
        },
      );

      if (response.statusCode == 200) {
        print('FCM 토큰이 성공적으로 서버에 전송되었습니다.');
      } else {
        print('FCM 토큰 전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('FCM 토큰 전송 중 오류 발생: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _refreshTokenTimer?.cancel(); // 타이머 해제
    super.dispose();
  }

  Future<void> refreshToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        throw Exception('리프레시 토큰이 없습니다.');
      }

      var response = await Dio().post(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/token/refresh/', // 리프레시 토큰 재발급 API 경로
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        String newAccessToken = response.data['access'];
        String newRefreshToken = response.data['refresh'];

        // 새로운 토큰을 저장
        prefs.setString('access_token', newAccessToken);
        prefs.setString('refresh_token', newRefreshToken);

        print(newAccessToken);
      }
    } catch (e) {
      print('토큰 재발급 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bungry Alarm'), // 타이틀 이름
        titleTextStyle: TextStyle(
          color: const Color.fromARGB(255, 255, 255, 255), // 타이틀 폰트 색깔
          fontSize: 20, // 타이틀 폰트 사이즈
          fontWeight: FontWeight.bold, // 타이틀 폰트 볼드
        ),

        backgroundColor: Color.fromARGB(255, 0, 0, 0),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          HomePage(),
          TodayPage(),
          CalendarPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 이 부분 추가하여 모든 탭이 고정되도록 설정
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              size: 20,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.push_pin,
              size: 20,
            ),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_month,
              size: 20,
            ),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              size: 20,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex, // 현재 선택된 탭의 인덱스
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0), // 선택된 아이템의 색상
        onTap: _onItemTapped, // 탭 선택 시 호출되는 메서드
      ),
    );
  }
}

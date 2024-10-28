import 'package:bungry_alarm/login_page.dart';
import 'package:bungry_alarm/pages/team_page.dart';
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
import 'pages/settings_page.dart';
import 'pages/teamspace_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 바인딩 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase 초기화
  );

  runApp(MyApp());
}

Future<bool> refreshTokens() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
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
      return true; // 성공 시 true 반환
    } else {
      return false; // 실패 시 false 반환
    }
  } catch (e) {
    print('토큰 재발급 실패: $e');
    return false;
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  bool isLoading = true; // 로딩 상태 추가
  

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // 앱 시작 시 로그인 상태 체크
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refresh_token');

    // 2초 대기
    await Future.delayed(Duration(seconds: 2));

    if (refreshToken != null && refreshToken.isNotEmpty) {
      // 리프레시 토큰이 있을 경우 엑세스 토큰 재발급 시도
      bool success = await refreshTokens();
      if (success) {
        setState(() {
          isLoggedIn = true;
          isLoading = false; // 로딩 완료
        });
      } else {
        setState(() {
          isLoggedIn = false;
          isLoading = false; // 로딩 완료
        });
      }
    } else {
      setState(() {
        isLoggedIn = false;
        isLoading = false; // 로딩 완료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이면 로딩 화면을 보여줌
    if (isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoadingScreen(), // 로딩 화면 위젯
      );
    }

    // 로딩이 완료되면 MyHomePage로 로그인 상태를 전달
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashColor: Colors.transparent, // 클릭 시 물결 효과 제거
        highlightColor: Colors.transparent, // 클릭 시 강조 효과 제거
        // splashFactory: NoSplash.splashFactory, // 스플래시 애니메이션 제거
      ),
      home: MyHomePage(isLoggedIn: isLoggedIn), // 로그인 상태 전달
    );
  }
}

// 로딩 화면 위젯
class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png', // 회사 로고 이미지 경로
              width: 200, // 로고의 너비
            ),
            SizedBox(height: 20), // 로고와 텍스트 사이의 간격
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool isLoggedIn;

  MyHomePage({required this.isLoggedIn}); // 로그인 상태 전달받음

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스
  PageController _pageController = PageController();
  Timer? _refreshTokenTimer; // 리프레시 토큰 재발급용 타이머
  WebSocketChannel? _channel;
  late bool isLoggedIn;
  String? lastMessageId; // 마지막으로 처리한 메시지 ID를 저장하는 변수
  bool isTeamspace = false; // Teamspace 여부를 저장하는 변수
  bool isLoadingTeam = false; // API 호출 상태를 저장하는 변수
  Map<String, dynamic> groupInfo = {}; // 그룹 정보를 저장할 변수 초기화
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn; // 초기 로그인 상태 설정

    WidgetsBinding.instance.addObserver(this); // Observer 등록
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
    // 로그인 상태일 때만 웹소켓 연결 시도
    if (isLoggedIn) {
      int? userID = prefs.getInt('user_id');
      if (userID != null) {
        // 웹소켓 연결
        _connectToWebSocket(userID); // 웹소켓 연결

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
        _refreshTokenTimer =
            Timer.periodic(Duration(minutes: 50), (timer) async {
          await refreshTokens(); // 토큰 재발급 함수
        });
      }
    }
  }

  void _connectToWebSocket(int? userID) {
    _channel = IOWebSocketChannel.connect(
        'wss://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/ws/alarm/?user_id=${userID.toString()}');

    // 수신된 메시지 처리
    _channel?.stream.listen((message) {
      try {
        var decodedMessage = jsonDecode(message);
        var messageId =
            decodedMessage['alarmid'].toString(); // 서버에서 제공하는 메시지 ID
        var alarmTitle = decodedMessage['message'];
        var alarmTime = decodedMessage['time'];

        // 중복 메시지 확인
        if (messageId != lastMessageId) {
          // 중복 메시지가 아니면 처리
          NotificationDialog.show(context, alarmTitle, alarmTime);
          lastMessageId = messageId; // 마지막 메시지 ID 업데이트
        } else {
          print('중복 메시지 감지: $messageId');
        }
      } catch (e) {
        print('메시지 처리 중 오류 발생: $e');
      }
    });
    print('WebSocket connected');
  }

  void _disconnectWebSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('user_id');

    if (_channel != null && userID != null) {
      _channel?.sink.add(jsonEncode({"disconnect_user": "$userID"}));
      _channel?.sink.close(); // 웹소켓 종료

      print('WebSocket disconnected');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _disconnectWebSocket(); // 백그라운드로 전환될 때 웹소켓 연결을 끊습니다.
    } else if (state == AppLifecycleState.resumed) {
      _loadUserId(); // 포그라운드로 돌아올 때 사용자 ID를 로드하고 웹소켓 재연결
    }
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

  // Teamspace에서 팀을 나갔을 때 호출할 함수
  void _onTeamLeft() {
    setState(() {
      isTeamspace = false; // 팀을 나가면 isTeamspace를 false로 변경하여 TeamPage를 보여줌
    });
  }

  void updateTeamspace(bool status) {
    setState(() {
      isTeamspace = status;
    });
    // Team 탭을 다시 호출
    _onItemTapped(3);
  }

  void _onItemTapped(int index) async {
    if (index == 3) {
      // Team 탭이 선택될 때

      setState(() {
        isLoadingTeam = true; // 로딩 상태로 설정
      });

      // API 호출
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? accessToken = prefs.getString('access_token');

        if (accessToken == null) {
          throw Exception('엑세스 토큰이 없습니다.');
        }

        var response = await Dio().get(
          'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/groupinfo/', // 팀 관련 API 엔드포인트
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          bool groupStatus = response.data['group_status'] ??
              false; // group_status가 없으면 false로 처리

          setState(() {
            isTeamspace = groupStatus; // 그룹 상태 업데이트
            groupInfo = response.data; // 그룹 정보 저장
          });
        } else {
          // 데이터가 없으면 일반 TeamPage로 이동
          setState(() {
            isTeamspace = false; // TeamPage로 전환
          });
        }
      } catch (e) {
        // API 호출 실패 또는 예외 발생 시 TeamPage로 이동
        setState(() {
          isTeamspace = false; // 오류 발생 시에도 TeamPage로 전환
        });
      } finally {
        setState(() {
          isLoadingTeam = false; // 로딩 상태 해제
        });

        // 페이지를 명시적으로 업데이트
        _pageController.jumpToPage(3);
      }
    } else {
      // 다른 탭이 선택되면 일반적인 탭 이동
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer 해제
    // _channel?.sink.close(); // 웹소켓 연결 종료
    _disconnectWebSocket();
    _pageController.dispose();
    _refreshTokenTimer?.cancel(); // 타이머 해제
    super.dispose();
  }

  Future<void> refreshTokens() async {
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
        
        actions: [
          Container(
            width: 70, // 가로 크기
            height: 30, // 세로 크기
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255), // 배경색
              shape: BoxShape.rectangle, // 모양
              borderRadius: BorderRadius.circular(30), // 모서리를 둥글게 설정
            ),
            child: TextButton(
              onPressed: () {
                if (isLoggedIn) {
                  // 로그아웃 페이지로 이동
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  });
                } else {
                  // 로그인 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                }
              },
              child: Text(
                isLoggedIn ? 'Logout' : 'Login',
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 0, 0), // 텍스트 색상
                  fontWeight: FontWeight.bold, // 텍스트 굵기
                  fontSize: 10.7, // 텍스트 크기
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: NeverScrollableScrollPhysics(), // 스와이프 비활성화
        children: [
          HomePage(),
          TodayPage(),
          CalendarPage(),
          isLoadingTeam
              ? Center(
                  child: CircularProgressIndicator(),
                ) // 로딩 중일 때
              : isTeamspace
                  ? TeamspacePage(
                      onTeamLeft: _onTeamLeft,
                      groupInfo: groupInfo,
                    ) // Teamspace 데이터가 있으면 보여줌

                  : TeamPage(
                      onTeamJoined:
                          updateTeamspace), // Team 데이터가 없으면 기본 페이지 // 콜백 함수 전달
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
              Icons.groups,
              size: 20,
            ),
            label: 'Team',
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

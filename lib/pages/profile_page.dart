import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'edit_page.dart';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// profile 페이지
class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<dynamic> dummyData = [];
  // 가짜 데이터
  bool isLoading = true; // 데이터를 로드하는 동안 로딩 상태를 표시하기 위한 변수
  bool isTokenMissing = false; // 토큰이 없을 때를 처리하기 위한 변수
  int? userID; // 사용자 ID 저장할 변수
  String? nickname;

  @override
  void initState() {
    super.initState();
    loadUserId(); // 사용자 ID 로드
  }

// 사용자 ID를 SharedPreferences에서 가져오기
  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getInt('user_id'); // userID 가져오기
      nickname = prefs.getString('user_nickname');
    });
    loadServerData(); // 서버에서 데이터 로드
  }

// 토큰 가져오기
  Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 서버에서 json 데이터 불러오는 함수
  Future<void> loadServerData() async {
    try {
      // SharedPreferences에서 저장된 액세스 토큰을 가져옴
      String? accessToken = await getAccessToken();

      if (accessToken == null) {
        setState(() {
          isLoading = false; // 로딩 완료
          isTokenMissing = true; // 토큰 없음 상태로 설정
        });
        return;
      }

      var response = await Dio().get(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/alarms/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // 헤더에 토큰 추가
          },
        ),
      );
      setState(() {
        dummyData =
            response.data.where((alarm) => alarm['id_user'] == userID).toList();
        _sortDataByDate(); // 데이터를 로드한 후 날짜 내림차순 정렬
        isLoading = false; // 데이터 로드 완료 후 로딩 상태 해제
        isTokenMissing = false; // 토큰이 있을 경우 false로 설정
      });
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() {
          isLoading = false; // 에러 발생 시에도 로딩 상태를 종료
        });
      }
    }
  }

  // 데이터를 날짜 기준으로 내림차순 정렬
  void _sortDataByDate() {
    dummyData.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA); // 내림차순 정렬
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 닉네임과 설정 버튼 부분
          Positioned(
            top: 30,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_circle, size: 40),
                    SizedBox(width: 10),
                    Text(
                      nickname != null ? '$nickname 님' : '로그인 필요',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isTokenMissing) {
                      // 토큰이 없을 때 "로그인이 필요합니다" 메시지 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('로그인이 필요합니다.')),
                      );
                    } else {
                      // 설정 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Row의 크기가 콘텐츠에 맞춰지도록 설정
                    children: [
                      Icon(Icons.settings, color: Colors.black), // 아이콘 추가
                      SizedBox(width: 8), // 아이콘과 텍스트 사이에 간격 추가
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                      minimumSize: Size(100, 50), // 버튼 크기 조정
                      side: BorderSide(
                          width: 2.0,
                          color: Color.fromARGB(255, 0, 0, 0)), // 테두리 두께와 색상
                      textStyle: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // 테두리 및 리스트
          Positioned(
            top: 110,
            left: 30,
            right: 30,
            bottom: 30, // 아래쪽 마진 추가
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent, // 내부를 투명하게 설정
                border: Border.all(
                  color: Colors.black, // 테두리 색상 설정
                  width: 2.0, // 테두리 두께 설정
                ),
                borderRadius: BorderRadius.circular(20.0), // 둥근 네모 모양으로 테두리 설정
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0), // 테두리와 콘텐츠 사이 여백
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : isTokenMissing
                        ? Center(
                            child: Text(
                              '로그인이 필요합니다.',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        : dummyData.isNotEmpty
                            ? ListView.separated(
                                shrinkWrap: true,
                                itemCount: dummyData.length,
                                itemBuilder: (context, index) {
                                  DateTime dateTime =
                                      DateTime.parse(dummyData[index]['date']);
                                  String date =
                                      DateFormat('yyyy-MM-dd').format(dateTime);
                                  String time =
                                      DateFormat('HH:mm').format(dateTime);
                                  String title = dummyData[index]['title'];
                                  String detail =
                                      dummyData[index].containsKey('detail')
                                          ? dummyData[index]['detail']
                                          : '상세 정보 없음';

                                  return ListTile(
                                    leading: Icon(
                                      Icons.circle,
                                      size: 15,
                                    ),
                                    title: Text(title),
                                    subtitle: Text('$date at $time'),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => EditPage(
                                                  id: dummyData[index]['id'],
                                                  title: title,
                                                  date: date,
                                                  time: time,
                                                  detail: detail,
                                                )),
                                      );
                                      if (result == true) {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        await loadServerData();
                                      }
                                    },
                                  );
                                },
                                separatorBuilder: (context, index) => Divider(),
                              )
                            : Center(
                                child: Text(
                                  '일정이 없습니다..',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
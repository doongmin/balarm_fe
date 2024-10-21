import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'create_page.dart';
import 'edit_page.dart';
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

  @override
  void initState() {
    super.initState();
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
        dummyData = response.data;
        _sortDataByDate(); // 데이터를 로드한 후 날짜 내림차순 정렬
        isLoading = false; // 데이터 로드 완료 후 로딩 상태 해제
        isTokenMissing = false; // 토큰이 있을 경우 false로 설정
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false; // 오류 발생 시에도 로딩 상태 해제
      });
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePage()),
            );
            // 알림 생성이 성공하면 서버에서 데이터를 다시 로드
            if (result == true) {
              setState(() {
                isLoading = true; // 로딩 상태로 변경
              });
              await loadServerData(); // 서버 데이터 다시 로드
            }
          }
        },
        backgroundColor: Colors.black,
        shape: CircleBorder(),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          // 상단 날짜 텍스트 (매일 당일 날짜 정보 받아와야 함)
          Positioned(
            top: 30,
            left: 50,
            right: 50,
            child: Container(
              child: Center(
                child: Text(
                  'My Page',
                  style: TextStyle(
                      fontSize: 25,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // 테두리
          Positioned(
            top: 90,
            left: 30,
            right: 30,
            child: Container(
              width: 600,
              height:
                  MediaQuery.of(context).size.height * 0.7, // 화면 높이의 70%로 설정
              color: Color.fromARGB(255, 211, 211, 211),
            ),
          ),

          // 로딩 중일 때 로딩 표시
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            )
          else if (isTokenMissing)
            // 토큰이 없을 때 "로그인이 필요합니다." 메시지 표시
            Center(
              child: Text(
                '로그인이 필요합니다.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          else
            // 리스트뷰 추가
            Positioned(
              top: 100, // 테두리 박스의 안쪽에 위치하도록 조정
              left: 40,
              right: 40,
              bottom: 40, // 리스트뷰의 하단 여백
              child: ListView.separated(
                itemCount: dummyData.length, // 가짜 데이터의 개수
                itemBuilder: (context, index) {
                  // JSON에서 date와 time 분리
                  DateTime dateTime = DateTime.parse(dummyData[index]['date']);
                  String date =
                      DateFormat('yyyy-MM-dd').format(dateTime); // 날짜 부분
                  String time = DateFormat('HH:mm').format(dateTime); // 시간 부분
                  String title = dummyData[index]['title'];
                  String detail = dummyData[index].containsKey('detail')
                      ? dummyData[index]['detail']
                      : '상세 정보 없음'; // detail 필드가 없는 경우 처리

                  return ListTile(
                    leading: Icon(Icons.circle),
                    title: Text(
                        dummyData[index]['title'] ?? ''), // 가짜 데이터를 리스트에 표시
                    subtitle: Text('$date at $time'),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditPage(
                                  id: dummyData[index]['id'], // id 전달
                                  title: title, // 타이틀 전달
                                  date: date, // 날짜 전달
                                  time: time, // 시간 전달
                                  detail: detail, // 상세 정보 전달
                                )),
                      );
                      // 알림 수정이 성공하면 서버에서 데이터를 다시 로드
                      if (result == true) {
                        setState(() {
                          isLoading = true; // 로딩 상태로 변경
                        });
                        await loadServerData(); // 서버 데이터 다시 로드
                      }
                    },
                  );
                },
                separatorBuilder: (context, index) =>
                    Divider(), // 각 아이템 사이에 구분선 추가
              ),
            ),
          // 설정 페이지
          /* Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () {
                // 버튼 클릭 시 기능
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()),);
              },
              icon: Icon(
                Icons.settings,
                size: 40,
              ),
            ),
          ),*/
        ],
      ),
    );
  }
}

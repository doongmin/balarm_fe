import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'create_page.dart';
import 'edit_page_for_all.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Today 페이지
class TodayPage extends StatefulWidget {
  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  List<dynamic> dummyData = [];
  bool isLoading = true; // 데이터를 로드하는 동안 로딩 상태를 표시하기 위한 변수

  // 가짜 데이터
  Dio dio = Dio(); // Dio 객체 생성

  @override
  void initState() {
    super.initState();
    fetchScheduleData(); // 서버에서 데이터를 불러오는 함수 호출
  }

  // 토큰 가져오기
  Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 서버에서 JSON 데이터를 가져오는 함수
  Future<void> fetchScheduleData() async {
    try {
      // SharedPreferences에서 저장된 액세스 토큰을 가져옴
      String? accessToken = await getAccessToken();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('토큰이 없습니다. 다시 로그인 해주세요.')),
        );
        return;
      }

      // 오늘 날짜를 yyyy-MM-dd 형식으로 얻음
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await dio.get(
        // 그룹화 할 때는 수정 필요
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/alarms/', 
        data: {
            'date': todayDate,
          },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // 헤더에 토큰 추가
          },
        ),
      );

      setState(() {
        dummyData = response.data; // 서버에서 받은 데이터를 상태로 저장
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String todayDate =
        DateFormat('yyyy-MM-dd').format(DateTime.now()); // 날짜 형식 yyyy-MM-dd

    // 서버에서 가져온 데이터에서 오늘 날짜와 일치하는 항목만 필터링
    List<dynamic> todayTasks = dummyData.where((task) {
      DateTime taskDateTime =
          DateTime.parse(task['date']); // JSON의 날짜/시간 문자열을 DateTime으로 변환
      String taskDate = DateFormat('yyyy-MM-dd').format(taskDateTime); // 날짜만 추출
      return taskDate == todayDate; // 오늘 날짜와 일치하는 항목만 필터링
    }).toList();

    // 시간 순으로 정렬 (오름차순)
    todayTasks.sort((a, b) {
      DateTime timeA = DateTime.parse(a['date']);
      DateTime timeB = DateTime.parse(b['date']);
      return timeA.compareTo(timeB); // 오름차순 정렬
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePage()),
          );
          // 알림 생성이 성공하면 서버에서 데이터를 다시 로드
          if (result == true) {
            setState(() {
              isLoading = true; // 로딩 상태로 변경
            });
            await fetchScheduleData(); // 서버 데이터 다시 로드
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
                  todayDate,
                  style: TextStyle(
                      fontSize: 30,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // 테두리
          Positioned(
            top: 100,
            left: 30,
            right: 30,
            child: Container(
              width: 600,
              height: MediaQuery.of(context).size.height * 0.7, // 화면 높이의 70%로 설정
              color: Color.fromARGB(255, 211, 211, 211),
            ),
          ),

          // 리스트뷰 추가
          Positioned(
            top: 110,
            left: 40,
            right: 40,
            bottom: 40,
            child: todayTasks.isNotEmpty
                ? ListView.separated(
                    itemCount: todayTasks.length,
                    itemBuilder: (context, index) {
                      DateTime taskDateTime =
                          DateTime.parse(todayTasks[index]['date']);
                      String date = DateFormat('yyyy-MM-dd')
                          .format(taskDateTime); // 날짜 부분
                      String taskTime =
                          DateFormat('HH:mm').format(taskDateTime); // 시간만 추출
                      String title = todayTasks[index]['title'];
                      String detail = todayTasks[index].containsKey('detail')
                          ? todayTasks[index]['detail']
                          : '상세 정보 없음'; // detail 정보가 없는 경우
                      String id = todayTasks[index]['id'].toString();
                      String id_user = todayTasks[index]['id_user'].toString();

                      return ListTile(
                        leading: Icon(Icons.push_pin_outlined),
                        title: Text(todayTasks[index]['title'] ?? ''),
                        subtitle: Text(taskTime),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditPage(
                                      id: id, // ID 전달
                                      title: title, // 타이틀 전달
                                      date: date, // 날짜 전달
                                      time: taskTime, // 시간 전달
                                      detail: detail, // 상세 정보 전달
                                      id_user: id_user,
                                    )),
                          );
                          // 알림 수정이 성공하면 서버에서 데이터를 다시 로드
                          if (result == true) {
                            setState(() {
                              isLoading = true; // 로딩 상태로 변경
                            });
                            await fetchScheduleData(); // 서버 데이터 다시 로드
                          }
                        },
                      );
                    },
                    separatorBuilder: (context, index) => Divider(),
                  )
                : Center(
                    child: Text(
                      '오늘은 일정이 없네요..', // 데이터가 없을 때 표시
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

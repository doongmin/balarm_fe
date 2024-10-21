import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'create_page.dart';
import 'edit_page_for_all.dart';
import 'package:shared_preferences/shared_preferences.dart';

// calendar 페이지
class CalendarPage extends StatefulWidget {
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 날짜별 스케줄 데이터
  Map<DateTime, List<Map<String, dynamic>>> _schedules = {};
  bool isLoading = true; // 데이터를 로드하는 동안 로딩 상태를 표시하기 위한 변수
  bool isTokenMissing = false; // 토큰이 없을 때를 처리하기 위한 변수

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now(); // 캘린더 페이지 열면 현재 날짜가 기본 선택
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

      // 선택된 날짜가 null이 아닐 때만 요청을 보냄
      if (_selectedDay != null) {
        String formattedDate =
            DateFormat('yyyy-MM-dd').format(_selectedDay!); // 날짜 포맷팅

        var response = await Dio().get(
          // 그룹화 할 때는 수정 필요
          'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/alarms/',
          data: {
            'date': formattedDate,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken', // 헤더에 토큰 추가
            },
          ),
        );
        final List<dynamic> data = response.data;

        // 서버에서 받은 데이터를 확인하기 위해 print 추가 (테스트용)
        // print("Received data: $data");

        // 서버에서 불러온 데이터를 DateTime을 키로 변환
        Map<DateTime, List<Map<String, dynamic>>> schedules = {};
        data.forEach((schedule) {
          DateTime date =
              DateTime.parse(schedule['date']); // 문자열을 DateTime으로 변환
          DateTime dateWithoutTime =
              DateTime(date.year, date.month, date.day); // 날짜만 저장

          if (!schedules.containsKey(dateWithoutTime)) {
            schedules[dateWithoutTime] = [];
          }

          // 스케줄 리스트에 각 스케줄 추가
          schedules[dateWithoutTime]!.add({
            'id': schedule['id'],
            'date': schedule['date'], // 날짜 정보 저장
            'time': DateFormat('HH:mm').format(date), // 시간 저장
            'title': schedule['title'], // 타이틀 저장
            'detail': schedule.containsKey('detail')
                ? schedule['detail']
                : '상세 정보 없음', // 상세 정보
            'id_user': schedule.containsKey('id_user')
                ? schedule['id_user']
                : null, // id_user 추가
          });
        });

        setState(() {
          _schedules = schedules; // 변환된 데이터를 상태에 저장
          isLoading = false; // 데이터 로드 완료 후 로딩 상태 해제
          isTokenMissing = false; // 토큰이 있을 경우 false로 설정
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() {
          isLoading = false; // 오류 발생 시에도 로딩 상태 해제
        });
      }
    }
  }

  // 날짜만 비교 (시간 정보를 완전히 제거한 상태에서 비교)
  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 현재 선택된 날짜의 스케줄을 가져오는 메서드
  List<Map<String, dynamic>> _getScheduleForDay(DateTime? day) {
    if (day == null) {
      return [];
    }

    // 날짜만 비교하여 스케줄 찾기
    return _schedules[_stripTime(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> _selectedDaySchedules =
        _getScheduleForDay(_selectedDay);

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
            // CreatePage에서 알림 생성 후 결과를 받음
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
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중일 때 로딩 표시
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  // TableCalendar 위젯 사용
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay =
                            _stripTime(selectedDay); // 시간 정보를 제거하여 날짜만 비교
                        _focusedDay = focusedDay;
                      });
                      loadServerData(); // 선택한 날짜에 대한 알림 로드
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Color.fromARGB(255, 164, 164, 164),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                  SizedBox(height: 20),

                  // 선택된 날짜의 스케줄 리스트 표시
                  Expanded(
                    child: isTokenMissing
                        ? Center(
                            child: Text(
                              '로그인이 필요합니다.', // 토큰이 없을 때 메시지
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        : _selectedDaySchedules.isNotEmpty
                            ? ListView.builder(
                                itemCount: _selectedDaySchedules.length,
                                itemBuilder: (context, index) {
                                  // JSON 데이터의 날짜와 시간을 분리
                                  DateTime dateTime = DateTime.parse(
                                      _selectedDaySchedules[index]['date']);
                                  String title =
                                      _selectedDaySchedules[index]['title'];
                                  String date = DateFormat('yyyy-MM-dd')
                                      .format(dateTime); // 날짜 부분
                                  String time = DateFormat('HH:mm')
                                      .format(dateTime); // 시간 부분
                                  String id = _selectedDaySchedules[index]['id']
                                      .toString();
                                  String id_user = _selectedDaySchedules[index]
                                          ['id_user']
                                      .toString();

                                  // 'detail' 필드가 없는 경우 기본값 설정
                                  String detail = _selectedDaySchedules[index]
                                          .containsKey('detail')
                                      ? _selectedDaySchedules[index]['detail']
                                      : '상세 정보 없음';

                                  return ListTile(
                                    title: Text('$time : $title'),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => EditPage(
                                                  id: id, // ID 전달
                                                  title: title, // 타이틀 전달
                                                  date: date, // 날짜 전달
                                                  time: time, // 시간 전달
                                                  detail: detail, // 상세 정보 전달
                                                  id_user: id_user,
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
                              )
                            : Center(
                                child: Text(
                                  '오늘은 일정이 없네요..',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                  ),
                ],
              ),
            ),
    );
  }
}

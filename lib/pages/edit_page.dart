import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 알람 수정 페이지 - 모든 알람 수정 페이지는 여기로 연결
class EditPage extends StatefulWidget {
  final int id;
  final String title;
  final String date;
  final String time;
  final String detail;

  EditPage({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.detail,
  });

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late TextEditingController titleController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController detailController;

  @override
  void initState() {
    super.initState();

    // 전달받은 데이터를 TextField의 기본값으로 설정
    titleController = TextEditingController(text: widget.title);
    dateController = TextEditingController(text: widget.date);
    timeController = TextEditingController(text: widget.time);
    detailController = TextEditingController(text: widget.detail);
  }

// 토큰 가져오기
  Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 알림 수정 함수 (PUT 요청)
Future<void> _updateData() async {
  String title = titleController.text;
  String date = dateController.text;
  String time = timeController.text;
  String detail = detailController.text;

  if (title.isEmpty || date.isEmpty || time.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('모든 항목을 입력해주세요')),
    );
    return;
  }

// 날짜와 시간을 결합해서 DateTime 형식으로 변환
  String combinedDateTimeString = '$date $time';
  DateTime combinedDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(combinedDateTimeString);

  // ISO 8601 형식 (2024-09-20T10:00:00)으로 변환
  String formattedDateTime = combinedDateTime.toIso8601String();

  try {
    // SharedPreferences에서 저장된 액세스 토큰을 가져옴
      String? accessToken = await getAccessToken();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('토큰이 없습니다. 다시 로그인 해주세요.')),
        );
        return;
      }

    // 수정된 데이터를 서버로 전송 (PUT 요청)
    var response = await Dio().patch(
      'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/alarms/${widget.id}/', // 기존 타이틀로 아이템 식별 (필요시 ID 사용)
      data: {
        'title': title,
        'date': formattedDateTime,
        'detail': detail,
      },
      options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // 헤더에 토큰 추가
          },
        ),
    );

    if (response.statusCode == 200) {
      // 성공적으로 수정됨
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('알림이 성공적으로 수정되었습니다.')),
      );
      Navigator.pop(context, true); // 수정 후 페이지를 닫음, true값 전달 -> 바로 새로고침용
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('알림 수정에 실패했습니다.')),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('서버와의 연결에 실패했습니다.')),
    );
  }
}

  // 서버에 데이터를 삭제하는 함수 (DELETE 요청)
  Future<void> _deleteData() async {
    try {
      // SharedPreferences에서 저장된 액세스 토큰을 가져옴
      String? accessToken = await getAccessToken();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('토큰이 없습니다. 다시 로그인 해주세요.')),
        );
        return;
      }

      var response = await Dio().delete(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/alarms/${widget.id}/', // 타이틀로 아이템 식별 (필요시 ID 사용)
      options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // 헤더에 토큰 추가
          },
        ),
      );

      if (response.statusCode == 204) {
        // 성공적으로 삭제됨
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림이 성공적으로 삭제되었습니다.')),
        );
        Navigator.pop(context, true); // 삭제 후 페이지를 닫음
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 삭제에 실패했습니다.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버와의 연결에 실패했습니다.')),
      );
    }
  }

  // 날짜 선택 함수
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // 선택한 날짜를 yyyy-MM-dd 형식으로 변환 후 텍스트 필드에 입력
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        dateController.text = formattedDate; // 텍스트 필드 업데이트
      });
    }
  }

  // 시간 선택 함수
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // 선택한 시간을 "HH:mm" 형식으로 변환 후 텍스트 필드에 입력
      final now = DateTime.now();
      final formattedTime = DateFormat('HH:mm').format(
        DateTime(
            now.year, now.month, now.day, pickedTime.hour, pickedTime.minute),
      );
      setState(() {
        timeController.text = formattedTime; // 선택한 시간을 텍스트 필드에 표시
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit List'),
      ),
      body: Stack(
        children: [
          // 테두리
          Positioned(
            top: 30,
            left: 30,
            right: 30,
            child: Container(
              width: 600,
              height: MediaQuery.of(context).size.height * 0.75, // 화면 높이의 70%로 설정
              color: Color.fromARGB(255, 182, 182, 182),
            ),
          ),

          // Title 입력 칸
          Positioned(
            top: 50,
            left: 50,
            right: 50,
            child: Container(
                width: 600,
                height: 50,
                color: Color.fromARGB(255, 235, 226, 225),
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '제목을 입력하세요.',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                )),
          ),

          //날짜 입력 칸
          Positioned(
            top: 120,
            left: 50,
            right: 50,
            child: Container(
              width: 600,
              height: 50,
              color: Color.fromARGB(255, 235, 226, 225),
              child: Row(
                children: [
                  // 날짜 입력 칸
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.only(right: 5),
                      child: TextField(
                        controller: dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '날짜 선택',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onTap: () {
                          _selectDate(context); // 캘린더 팝업 호출
                        },
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),

                  // 시간 입력 칸
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.only(left: 5),
                      child: TextField(
                        controller: timeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '시간 선택',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onTap: () {
                          _selectTime(context); // 시간 선택 다이얼로그 호출
                        },
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 상세정보 입력 칸
          Positioned(
            top: 190,
            left: 50,
            right: 50,
            child: Container(
              width: 600,
              height: MediaQuery.of(context).size.height * 0.5, // 화면 높이의 70%로 설정
              color: Color.fromARGB(255, 235, 226, 225),
              child: TextField(
                controller: detailController,
                maxLines: null, // 여러 줄 입력 가능
                keyboardType: TextInputType.multiline, // 여러 줄 입력 가능 설정
                textInputAction: TextInputAction.done, // 완료 버튼 설정
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '상세정보를 입력하세요.',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                style: TextStyle(color: Colors.black),
                onEditingComplete: () {
                  FocusScope.of(context).unfocus(); // 완료 후 키보드를 내림 (필수 X)
                },
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).size.height * 0.72, // 화면 높이에 맞춰 위치 조정
            left: MediaQuery.of(context).size.width * 0.22, // 화면 너비의 25% 위치에 배치
            child: IconButton(
              onPressed: () {
                // 버튼 클릭 시 기능
                _updateData();
              },
              icon: Icon(
                Icons.edit_note,
                size: 40,
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).size.height * 0.72, // 화면 높이에 맞춰 위치 조정
            left: MediaQuery.of(context).size.width * 0.65, // 화면 너비의 25% 위치에 배치
            child: IconButton(
              onPressed: () {
                // 버튼 클릭 시 기능
                _deleteData();
              },
              icon: Icon(
                Icons.delete_outline,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

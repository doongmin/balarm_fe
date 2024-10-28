import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamPage extends StatefulWidget {
  final Function(bool) onTeamJoined; // 콜백 함수 받기

  TeamPage({required this.onTeamJoined});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  bool isTokenMissing = false; // 토큰이 없을 때를 처리하기 위한 변수
  Dio dio = Dio(); // Dio 객체 생성
  String? groupCode; // 그룹코드를 저장할 변수

  // 토큰 가져오기
  Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 그룹코드 저장하기
  Future<void> saveGroupCode(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('group_code', code); // 그룹코드를 저장
  }

  // 그룹코드 표시
  Future<void> loadGroupCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedCode = prefs.getString('group_code');
    if (storedCode != null) {
      setState(() {
        groupCode = storedCode; // 저장된 그룹코드를 변수에 저장
      });

      // 팝업으로 그룹코드 표시
      _showGroupCodePopup(storedCode);
    } else {
      // 그룹코드가 없을 경우 처리
      print('팀 코드가 없습니다.');
    }
  }

// 그룹코드 팝업 함수
  void _showGroupCodePopup(String groupCode) {
    TextEditingController companyController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 45,
              ), // 좌측을 비워서 타이틀 가운데로 맞추기
              Text(
                '팀스페이스 생성',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // 제목 볼드체
                  fontSize: 20, // 제목 글씨 크기 설정
                ),
                textAlign: TextAlign.center, // 가운데 정렬
              ),

              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기 (X 버튼)
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 팝업 크기를 내용에 맞게 조정
            children: [
              Text(
                '팀 초대 코드: $groupCode',
                style: TextStyle(fontSize: 16), // 텍스트 글씨 크기 키우기
              ),
              SizedBox(height: 10), // 간격 추가
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: groupCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('초대 코드가 복사되었습니다!')),
                  ); // 초대 코드 복사 알림
                },
                icon: Icon(Icons.copy), // 복사 아이콘
                label: Text('초대 코드 복사'), // 복사 버튼 텍스트
              ),
              SizedBox(height: 20), // 간격 추가
              TextField(
                controller: companyController,
                decoration: InputDecoration(
                  labelText: '팀 이름 입력', // 입력 필드의 라벨
                  border: OutlineInputBorder(), // 테두리 설정
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 사용자가 입력한 회사명을 처리
                String companyName = companyController.text;
                if (companyName.isEmpty) {
                  // 회사명이 입력되지 않았을 경우
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('팀 이름을 입력해주세요')),
                  );
                } else {
                  // API 호출
                  _sendCompanyInfo(groupCode, companyName);
                  Navigator.of(context).pop(); // 팝업 닫기
                }
              },
              child: Text('팀스페이스 생성'),
            ),
          ],
        );
      },
    );
  }

  // 그룹코드 입력 팝업 함수
  void _writeGroupCodePopup() async {
    TextEditingController codeController = TextEditingController();
    String? accessToken = await getAccessToken(); // 엑세스 토큰 확인

    if (accessToken == null) {
      // 엑세스 토큰이 없으면 로그인 필요 메시지 띄우기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return; // 팝업을 열지 않음
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 45,
              ), // 좌측을 비워서 타이틀 가운데로 맞추기
              Text(
                '팀스페이스 참여',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // 제목 볼드체
                  fontSize: 20, // 제목 글씨 크기 설정
                ),
                textAlign: TextAlign.center, // 가운데 정렬
              ),

              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(); // 팝업 닫기 (X 버튼)
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 팝업 크기를 내용에 맞게 조정
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: '팀 초대 코드 입력', // 입력 필드의 라벨
                  border: OutlineInputBorder(), // 테두리 설정
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 사용자가 입력한 회사명을 처리
                String teamcode = codeController.text;
                if (teamcode.isEmpty) {
                  // 회사명이 입력되지 않았을 경우
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('팀 초대 코드를 입력해주세요')),
                  );
                } else {
                  // API 호출
                  joinTeamCode(teamcode);
                  Navigator.of(context).pop(); // 팝업 닫기
                }
              },
              child: Text('팀스페이스 참여'),
            ),
          ],
        );
      },
    );
  }

  // 그룹코드와 회사명을 서버로 전달하는 함수
  Future<void> _sendCompanyInfo(String groupCode, String companyName) async {
    try {
      String? accessToken = await getAccessToken();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id'); // user_id 불러오기

      if (accessToken == null) {
        setState(() {
          isTokenMissing = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      // API 요청 보내기
      final response = await dio.post(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/creategroup/', // 실제 API 경로로 바꿔야 합니다.
        data: {
          'group_code': groupCode,
          'group_name': companyName,
          'user_id': userId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팀스페이스 생성이 완료되었습니다.')),
        );
        // 콜백 함수 호출해서 부모 위젯에 상태 전달
        widget.onTeamJoined(true); // 그룹 생성 성공 시 status를 true로 설정
      } else {
        print('전송 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팀스페이스 생성에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }

  // 그룹생성 API 호출 함수
  Future<void> createTeamCode() async {
    try {
      // Access Token 가져오기
      String? accessToken = await getAccessToken();

      if (accessToken == null) {
        setState(() {
          isTokenMissing = true; // 토큰 없음 상태로 설정
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      // API 호출
      final response = await dio.post(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/groupcode/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // 헤더에 토큰 추가
          },
        ),
      );

      if (response.statusCode == 200) {
        // 성공적으로 팀스페이스가 생성되었을 때 처리
        String receivedGroupCode = response.data['group_code']; // 그룹코드 추출
        await saveGroupCode(receivedGroupCode); // 그룹코드 저장
        await loadGroupCode(); // 저장된 그룹코드를 로드하여 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팀 코드가 성공적으로 생성되었습니다.')),
        );
      } else {
        // 요청 실패 시 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팀스페이스 생성 실패. 다시 시도하세요.')),
        );
      }
    } catch (e) {
      // 에러 발생 시 처리
      print('Error creating team space: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 오류가 발생했습니다.')),
      );
    }
  }

  // 그룹 참여 API 호출 함수
  Future<void> joinTeamCode(String teamcode) async {
    try {
      // Access Token 가져오기
      String? accessToken = await getAccessToken();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id'); // user_id 불러오기

      if (accessToken == null) {
        setState(() {
          isTokenMissing = true; // 토큰 없음 상태로 설정
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      // API 호출
      final response = await dio.post(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/joingroup/',
        data: {
          'group_code': teamcode,
          'user_id': userId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken', // 헤더에 토큰 추가
          },
        ),
      );

      if (response.statusCode == 200) {
        // 성공적으로 팀스페이스에 참여되었을 때 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('새로운 팀스페이스에 참여했습니다.')),
        );
        // 콜백 함수 호출하여 부모 페이지의 상태를 변경
        widget.onTeamJoined(true); // 팀스페이스 참여 상태 전달
      } else {
        // 요청 실패 시 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팀스페이스 참여 실패. 다시 시도하세요.')),
        );
      }
    } catch (e) {
      // 에러 발생 시 처리
      print('Error creating team space: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버 오류가 발생했습니다.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 화면 중앙에 위치
          children: [
            ElevatedButton(
              onPressed: () {
                createTeamCode();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min, // Row의 크기가 콘텐츠에 맞춰지도록 설정
                children: [
                  Icon(Icons.group, color: Colors.black), // 아이콘 추가
                  SizedBox(width: 8), // 아이콘과 텍스트 사이에 간격 추가
                  Text(
                    '팀스페이스 생성',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                  minimumSize: Size(200, 50), // 버튼 크기 조정
                  side: BorderSide(
                      width: 2.0,
                      color: const Color.fromARGB(255, 0, 0, 0)), // 테두리 두께와 색상
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            ),
            SizedBox(height: 20), // 버튼 사이 간격
            ElevatedButton(
              onPressed: () {
                _writeGroupCodePopup();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min, // Row의 크기가 콘텐츠에 맞춰지도록 설정
                children: [
                  Icon(Icons.group_add, color: Colors.black), // 아이콘 추가
                  SizedBox(width: 8), // 아이콘과 텍스트 사이에 간격 추가
                  Text(
                    '팀스페이스 참여',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                  minimumSize: Size(200, 50), // 버튼 크기 조정
                  side: BorderSide(
                      width: 2.0,
                      color: Color.fromARGB(255, 0, 0, 0)), // 테두리 두께와 색상
                  textStyle: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

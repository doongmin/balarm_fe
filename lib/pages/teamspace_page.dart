import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'member_alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamspacePage extends StatefulWidget {
  final Function onTeamLeft; // 팀을 나갔을 때 콜백 함수 추가
  final Map<String, dynamic> groupInfo; // 그룹 정보를 받을 파라미터 추가

  TeamspacePage(
      {required this.onTeamLeft, required this.groupInfo}); // 콜백 함수 받음

  @override
  State<TeamspacePage> createState() => _TeamSpaceState();
}

class _TeamSpaceState extends State<TeamspacePage> {
  List<dynamic> teamData = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // 기존 initState 코드
        if (widget.groupInfo.containsKey('member') &&
            widget.groupInfo['member'] != null &&
            widget.groupInfo['member'] is List) {
          setState(() {
            teamData = widget.groupInfo['member'];
          });
        } else {
          setState(() {
            teamData = [];
          });
        }
      } catch (e) {
        print("Error in initState: $e");
      }
    });
  }

  // 토큰 가져오기
  Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

// 팀 나가기 API 호출
  Future<void> leaveTeam() async {
    try {
      String? accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('액세스 토큰이 없습니다.');
      }

      var response = await Dio().post(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/leavegroup/', // 팀 나가기 API 경로
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        // 팀 나가기 성공 시 콜백 함수 호출하여 탭 변경
        widget.onTeamLeft(); // 부모 위젯의 콜백 함수 호출
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팀을 나갔습니다. 새로운 팀에 참여해주세요.')),
        );
      } else {
        // 실패 시 메시지 출력
        _showErrorDialog('팀 나가기를 실패했습니다.');
      }
    } catch (e) {
      print('Error leaving team: $e');
      _showErrorDialog('팀 나가기를 실패했습니다.');
    }
  }

// 알림 리스트 불러오기
  Future<List<dynamic>> fetchAllAlarms() async {
    try {
      String? accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('액세스 토큰이 없습니다.');
      }

      var response = await Dio().get(
        'https://port-0-balarm-m1ep4ac2e3fbce39.sel4.cloudtype.app/api/alarms/', // 모든 알람을 불러오는 API 엔드포인트
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('알람 데이터를 불러오는 데 실패했습니다.');
      }
    } catch (e) {
      print('Error fetching alarms: $e');
      return [];
    }
  }

  // 에러 메시지를 표시하는 함수
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 팀 나가기 확인 팝업
  void _confirmLeaveTeam() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '팀 나가기',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('정말로 팀에서 나가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 팝업 닫기
                await leaveTeam(); // 팀 나가기 API 호출
              },
              child: Text(
                '나가기',
                style: TextStyle(color: Color.fromARGB(255, 148, 0, 0)),
              ),
            ),
          ],
        );
      },
    );
  }

// 팀 초대 코드 팝업
  void _showGroupCodePopup(String? groupCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '초대 코드',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                groupCode ?? '초대 코드가 없습니다.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  if (groupCode != null) {
                    // 그룹 코드를 클립보드에 복사
                    Clipboard.setData(ClipboardData(text: groupCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('초대 코드가 복사되었습니다!')),
                    );
                  }
                },
                icon: Icon(Icons.copy), // 복사 아이콘
                label: Text('초대 코드 복사'), // 복사 버튼 텍스트
              ),
              SizedBox(height: 10), // 간격 추가
              Text('초대 코드를 복사해 공유하세요.'),
            ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 상단 날짜 텍스트
          Positioned(
            top: 20,
            left: 50,
            right: 50,
            child: Container(
              child: Center(
                child: Text(
                  widget.groupInfo['group_name'] ?? 'Team Space',
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
            top: 80,
            left: 30,
            right: 30,
            child: Container(
              width: 600,
              height: MediaQuery.of(context).size.height * 0.5, // 화면 높이의 %로 설정
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
                child: teamData.isNotEmpty
                    ? ListView.separated(
                        shrinkWrap: true,
                        itemCount: teamData.length,
                        itemBuilder: (context, index) {
                          var member = teamData[index];
                          return ListTile(
                            leading: Icon(Icons.person_outline),
                            title: Text(member['nickname']),
                            subtitle: Text('멤버'),
                            onTap: () async {
                              // 전체 알람을 불러오는 API 호출
                              List<dynamic> allAlarms = await fetchAllAlarms();

                              // 해당 팀원의 user_id로 알람 필터링
                              int userId = member['user_id']; // teamData의 user_id는 int로 가정
                              List<dynamic> memberAlarms =
                                  allAlarms.where((alarm) {
                                // id_user 필드와 teamData의 user_id를 비교하여 필터링
                                return alarm['id_user'] == userId;
                              }).toList();

                              // 알람 데이터를 새 페이지로 전달하여 화면에 표시
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MemberAlarmPage(
                                    alarms: memberAlarms,
                                    memberName: member['nickname'],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        separatorBuilder: (context, index) => Divider(),
                      )
                    : Center(
                        child: Text(
                          '팀원이 없습니다..',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
          ),

          // 하단에 버튼 두 개 배치
          Positioned(
            top: MediaQuery.of(context).size.height * 0.65,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 버튼 사이 간격 조절
              children: [
                OutlinedButton(
                  onPressed: () {
                    // '팀 초대 코드' 버튼 클릭 시 로직
                    _showGroupCodePopup(
                        widget.groupInfo['group_code']); // 팝업에 그룹 코드 전달
                  },
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // 아이콘과 텍스트를 가운데 정렬
                    children: [
                      Text(
                        '팀 초대 코드',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격
                      Icon(
                        Icons.group_add, // 원하는 아이콘 설정
                        color: Color.fromARGB(255, 0, 0, 0), // 아이콘 색상
                      ),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(width: 3.0, color: Colors.black), // 테두리 설정
                    minimumSize: Size(140, 50), // 버튼 크기 조정
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    // '팀스페이스 나가기' 버튼 클릭 시 로직
                    _confirmLeaveTeam();
                  },
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // 아이콘과 텍스트를 가운데 정렬
                    children: [
                      Text(
                        '팀 나가기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 148, 0, 0),
                        ),
                      ),
                      SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격
                      Icon(
                        Icons.exit_to_app, // 원하는 아이콘 설정
                        color: Color.fromARGB(255, 148, 0, 0), // 아이콘 색상
                      ),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        width: 3.0,
                        color: Color.fromARGB(255, 148, 0, 0)), // 테두리 설정
                    minimumSize: Size(140, 50), // 버튼 크기 조정
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

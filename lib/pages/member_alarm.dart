import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'edit_page_for_all.dart';

class MemberAlarmPage extends StatelessWidget {
  final List<dynamic> alarms;
  final String memberName;

  MemberAlarmPage({required this.alarms, required this.memberName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$memberName님이 생성한 일정',
          style: TextStyle(fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Colors.black, // 앱바 배경색을 검정색으로 설정
      iconTheme: IconThemeData(
          color: Colors.white, // 뒤로 가기 버튼 색상 설정
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 30,
            left: 20,
            right: 20,
            child: Container(
              height:
                  MediaQuery.of(context).size.height * 0.75, // 화면의 75% 높이로 설정
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), // 둥근 테두리 설정
                border:
                    Border.all(color: Colors.black, width: 2), // 테두리 색상 및 두께 설정
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0), // 테두리와 내부 컨텐츠 사이의 패딩 설정
                child: alarms.isNotEmpty
                    ? ListView.separated(
                        itemCount: alarms.length,
                        separatorBuilder: (context, index) => Divider(
                          thickness: 1.0, // 구분선 두께
                          color: Colors.grey[300], // 구분선 색상
                        ),
                        itemBuilder: (context, index) {
                          var alarm = alarms[index];

                          // 서버에서 받은 시간을 DateTime 형식으로 변환
                          DateTime alarmDateTime = DateTime.parse(alarm['date']);

                          // 원하는 형식으로 날짜와 시간 포맷팅
                          String formattedDate = DateFormat('yyyy-MM-dd \'at\' HH:mm')
                              .format(alarmDateTime);

                          return ListTile(
                            leading: Icon(Icons.circle,
                                size: 12, color: Colors.grey), // 왼쪽에 작은 점 아이콘
                            title: Text(
                              alarm['title'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(formattedDate),
                            onTap: () {
                              // 알람 항목을 클릭하면 EditPage로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPage(
                                    id: alarm['id'].toString(),
                                    title: alarm['title'],
                                    date: alarm['date']
                                        .substring(0, 10), // yyyy-MM-dd 형식으로 자르기
                                    time: alarm['date']
                                        .substring(11, 16), // HH:mm 형식으로 자르기
                                    detail: alarm['detail'],
                                    id_user: alarm['id_user'].toString(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          '생성된 알림이 없습니다.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
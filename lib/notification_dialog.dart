import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class NotificationDialog {
  static void show(BuildContext context, String message, String time) async {

    // DateTime으로 변환 후 시간 정보만 추출
    DateTime dateTime = DateTime.parse(time);
    String formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    // 진동 울리기
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000); // 1초 동안 진동
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          formattedTime,
          textAlign: TextAlign.center, // 가운데 정렬
          style: TextStyle(
            fontSize: 30, // 글씨 크기
            fontWeight: FontWeight.bold, // 글씨 굵기
            color: Color.fromARGB(255, 0, 0, 0), // 글씨 색상
            fontFamily: 'Roboto', // 글씨체 설정
          ),
        ),
        content: Text(
          "\n '$message' 할 시간!",
          textAlign: TextAlign.center, // 가운데 정렬
          style: TextStyle(
            fontSize: 18, // 글씨 크기
            fontWeight: FontWeight.bold, // 글씨 굵기
            color: Colors.black87, // 글씨 색상
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: TextStyle(
                fontSize: 16, // 글씨 크기
                color: Color.fromARGB(255, 38, 0, 255), // 버튼 텍스트 색상
              ),
            ),
          ),
        ],
      ),
    );
  }
}

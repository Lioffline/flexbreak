import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'variable.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  String profession = '';
  String email = '';
  String defaultBreakStart = '';
  String defaultBreakEnd = '';
  List<int> weekends = [];
  int totalQuotaBalance = 0;
  int dailyQuotaMinutes = 0;

  @override
  void initState() {
    super.initState();
  }


  int _parseQuotaToMinutes(String quota) {
    final parts = quota.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _convertWeekday(int day) {
    final daysOfWeek = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return daysOfWeek[day - 1];
  }


Stream<int> _calculateTotalQuotaBalance(int userId) async* {
  final breakSnapshots = FirebaseFirestore.instance
      .collection('Breaks')
      .where('UserID', isEqualTo: userId)
      .snapshots();

  await for (var snapshot in breakSnapshots) {
    Map<String, int> dayBreaks = {}; 
    Map<String, int> dayMaxQuota = {};
    int totalBalance = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp? startTimestamp = data['start'] as Timestamp?;
      final Timestamp? endTimestamp = data['end'] as Timestamp?;
      final String? quota = data['quota'] as String?;

      if (startTimestamp == null || endTimestamp == null || quota == null) {
        continue;
      }

      final DateTime start = startTimestamp.toDate();
      final DateTime end = endTimestamp.toDate();
      

      final int breakDuration = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
      
      final int quotaMinutes = _parseQuotaToMinutes(quota);

      String dayKey = DateFormat('yyyy-MM-dd').format(start);

      dayMaxQuota[dayKey] = dayMaxQuota.containsKey(dayKey)
          ? (quotaMinutes > dayMaxQuota[dayKey]! ? quotaMinutes : dayMaxQuota[dayKey]!)
          : quotaMinutes;

      dayBreaks[dayKey] = (dayBreaks[dayKey] ?? 0) + breakDuration;
    }

    dayBreaks.forEach((day, totalMinutes) {
      int maxQuotaMinutes = dayMaxQuota[day] ?? 0;
      if (totalMinutes >= maxQuotaMinutes) {
        totalBalance -= (totalMinutes - maxQuotaMinutes);
      } else {
        totalBalance += (maxQuotaMinutes - totalMinutes);
      }
    });

    yield totalBalance;
  }
}

  Stream<DocumentSnapshot> _getUserData(int userId) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId.toString())
        .snapshots();
  }

  Widget _buildWeeklyCalendar() {
    List<Widget> dayWidgets = [];
    for (int i = 0; i < 7; i++) {
      bool isWeekend = weekends.contains(i + 1);
      dayWidgets.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              
            },
            child: Container(
              margin: EdgeInsets.all(4),
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isWeekend ? Colors.blueAccent : Colors.grey[800], 
                borderRadius: BorderRadius.circular(10), 
              ),
              child: Center(
                child: Text(
                  _convertWeekday(i + 1),
                  style: TextStyle(
                    color: isWeekend ? Colors.white : Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dayWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    //final int userId = 1; 
    int userId = int.tryParse(userID) ?? 0;  
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Profile",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(  
        child: StreamBuilder<DocumentSnapshot>(
          stream: _getUserData(userId), 
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(child: CircularProgressIndicator()); 
            }

            final userDoc = userSnapshot.data!;
            final userData = userDoc.data() as Map<String, dynamic>;

            name = userData['Name'] ?? '';
            profession = userData['Proffesion'] ?? '';
            email = userData['mail'] ?? '';
            defaultBreakStart = userData['defaultBreak']['start'] ?? '13:30';
            defaultBreakEnd = userData['defaultBreak']['end'] ?? '14:00';
            weekends = List<int>.from(userData['weekends'] ?? []);
            dailyQuotaMinutes = _parseQuotaToMinutes(userData['quota'] ?? '01:30');

            return StreamBuilder<int>(
              stream: _calculateTotalQuotaBalance(userId), 
              builder: (context, balanceSnapshot) {
                if (!balanceSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator()); 
                }

                totalQuotaBalance = balanceSnapshot.data!;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 60, 
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    totalQuotaBalance >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: totalQuotaBalance >= 0 ? Colors.blue : Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '$totalQuotaBalance',
                                    style: TextStyle(
                                      color: totalQuotaBalance >= 0 ? Colors.blue : Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Основная информация",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.email, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  email,
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.work, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  profession,
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Стандартный перерыв",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.timer, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "$defaultBreakStart - $defaultBreakEnd",
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      _buildWeeklyCalendar(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

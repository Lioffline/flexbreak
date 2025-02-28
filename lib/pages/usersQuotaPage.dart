import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'variable.dart';
import 'home_page.dart'; 

class UsersQuotaPage extends StatefulWidget {
  @override
  _UsersQuotaPageState createState() => _UsersQuotaPageState();
}

class _UsersQuotaPageState extends State<UsersQuotaPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _parseQuotaToMinutes(String quota) {
    final parts = quota.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int? _calculateRemainingQuotaForDay(List<Map<String, dynamic>> breaks) {
    if (breaks.isEmpty) return null;

    int totalMinutes = 0;
    int? maxQuota;

    for (var breakInfo in breaks) {
      final start = breakInfo['start'] as DateTime;
      final end = breakInfo['end'] as DateTime;
      final quotaStr = breakInfo['quota'] as String?;
      final quotaMinutes = quotaStr != null ? _parseQuotaToMinutes(quotaStr) : null;

      final breakDuration = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
      totalMinutes += breakDuration;

      if (quotaMinutes != null) {
        maxQuota = maxQuota == null ? quotaMinutes : (quotaMinutes > maxQuota ? quotaMinutes : maxQuota);
      }
    }

    if (maxQuota == null) return null;

    return maxQuota - totalMinutes;
  }

  Stream<List<Map<String, dynamic>>> _fetchUsersAndQuotas() async* {
    final usersSnapshot = FirebaseFirestore.instance.collection('Users').snapshots();

    await for (var snapshot in usersSnapshot) {
      List<Map<String, dynamic>> usersWithQuota = [];

      for (var doc in snapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;
        final userName = userData['Name'] ?? 'Unnamed';
        final profession = userData['Proffesion'] ?? 'Unknown'; 

        if (!_searchQuery.isEmpty &&
            !(userName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
              profession.toLowerCase().contains(_searchQuery.toLowerCase()))) {
          continue;
        }

        final breaksSnapshot = await FirebaseFirestore.instance
            .collection('Breaks')
            .where('UserID', isEqualTo: userId)
            .get();

        Map<String, List<Map<String, dynamic>>> breaksByDay = {};

        for (var breakDoc in breaksSnapshot.docs) {
          final data = breakDoc.data();
          final start = (data['start'] as Timestamp).toDate();
          final end = (data['end'] as Timestamp).toDate();
          final quota = data['quota'] as String;

          final dayKey = DateFormat('yyyy-MM-dd').format(start);
          if (!breaksByDay.containsKey(dayKey)) {
            breaksByDay[dayKey] = [];
          }
          breaksByDay[dayKey]!.add({'start': start, 'end': end, 'quota': quota});
        }

        int totalQuotaBalance = 0;
        for (var dayBreaks in breaksByDay.values) {
          final remainingQuota = _calculateRemainingQuotaForDay(dayBreaks);
          if (remainingQuota != null) totalQuotaBalance += remainingQuota;
        }

        usersWithQuota.add({
          'userId': userId,
          'name': userName,
          'profession': profession,
          'quotaBalance': totalQuotaBalance,
        });
      }

      usersWithQuota.sort((a, b) => a['quotaBalance'].compareTo(b['quotaBalance']));
      yield usersWithQuota;
    }
  }
  void _onUserTap(Map<String, dynamic> user) {
    userID = user['userId'].toString(); 

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "FlexBreak",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Поиск по имени или профессии',
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>( 
              stream: _fetchUsersAndQuotas(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final usersWithQuota = snapshot.data!;

                List<Map<String, dynamic>> negativeUsers = [];
                List<Map<String, dynamic>> zeroUsers = [];
                List<Map<String, dynamic>> positiveUsers = [];

                for (var user in usersWithQuota) {
                  final quotaBalance = user['quotaBalance'];
                  if (quotaBalance < 0) {
                    negativeUsers.add(user);
                  } else if (quotaBalance == 0) {
                    zeroUsers.add(user);
                  } else {
                    positiveUsers.add(user);
                  }
                }

                return ListView(
                  children: [
                    if (negativeUsers.isNotEmpty)
                      ExpansionTile(
                        shape: Border(),
                        title: Text(
                          'Недоработка',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: true,
                        children: negativeUsers.map<Widget>((user) {
                          final quotaBalance = user['quotaBalance'];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () => _onUserTap(user),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_circle, size: 50, color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${user['name']}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                user['profession'],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.arrow_downward,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                '$quotaBalance',
                                                style: TextStyle(
                                                  color: Colors.red,
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
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    if (zeroUsers.isNotEmpty)
                      ExpansionTile(
                        shape: Border(),
                        title: Text(
                          'Без отклонения',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: true,
                        children: zeroUsers.map<Widget>((user) {
                          final quotaBalance = user['quotaBalance'];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () => _onUserTap(user),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_circle, size: 50, color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                               '${user['name']}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                user['profession'],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              ),
                                            ],
                                          ),
                                          Row(
                                          children: [
                                            Icon(
                                              Icons.remove,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              '$quotaBalance',
                                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    if (positiveUsers.isNotEmpty)
                      ExpansionTile(
                        shape: Border(),
                        title: Text(
                          'Переработка',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: true,
                        children: positiveUsers.map<Widget>((user) {
                          final quotaBalance = user['quotaBalance'];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () => _onUserTap(user),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_circle, size: 50, color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${user['name']}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                user['profession'],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.arrow_upward,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                '$quotaBalance',
                                                style: TextStyle(
                                                  color: Colors.blue,
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
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

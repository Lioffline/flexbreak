import 'package:flexbreak/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String quota = '';
  int totalQuotaBalance = 0;
  int dailyQuotaMinutes = 0;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _defaultBreakStartController = TextEditingController();
  final _defaultBreakEndController = TextEditingController();
  final _quotaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _professionController = TextEditingController();

  bool isModerator = Profession == 'Модератор';
  bool isSelfProfile = userID == LoggeduserID;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }


  int _parseQuotaToMinutes(String quota) {
    final parts = quota.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _convertWeekday(int day) {
    final daysOfWeek = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    return daysOfWeek[day - 1];
  }


Stream<int> _calculateTotalQuotaBalance(userID) async* {
  final breakSnapshots = FirebaseFirestore.instance
      .collection('Breaks')
      .where('UserID', isEqualTo: userID)
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

  Stream<DocumentSnapshot> _getUserData(userID) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userID)
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

void _fetchUserProfile() async {
  final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userID).get();
  final userData = userDoc.data() as Map<String, dynamic>;

  setState(() {
    name = userData['Name'] ?? '';
    profession = userData['Proffesion'] ?? '';
    email = userData['mail'] ?? '';
    defaultBreakStart = userData['defaultBreak']['start'] ?? '';
    defaultBreakEnd = userData['defaultBreak']['end'] ?? '';
    weekends = List<int>.from(userData['weekends'] ?? []);
    quota = userData['quota'] ?? '';
    
    _nameController.text = name;
    _emailController.text = email;
    _defaultBreakStartController.text = defaultBreakStart;
    _defaultBreakEndController.text = defaultBreakEnd;
    _quotaController.text = quota;
    _professionController.text = profession;
  });
}

void _showEditProfileDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Edit Profile", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelfProfile) _buildTextField("Name", _nameController, isEditable: true),
              if (isSelfProfile) _buildTextField("Email", _emailController, isEditable: true),
              if (isSelfProfile) _buildTextField("Password", _passwordController, isEditable: true),
              if (isModerator) _buildTextField("Quota", _quotaController, isEditable: true),
              if (isModerator) _buildTextField("Profession", _professionController, isEditable: true),
              if (isModerator) _buildWeekendsField(),
              if (isModerator) _buildTextField("Default Break Start", _defaultBreakStartController, isEditable: true),
              if (isModerator) _buildTextField("Default Break End", _defaultBreakEndController, isEditable: true),
            ],
          ),
        ),
        actions: [
          if (isSelfProfile) 
            Text(
              "Для изменения важных данных необходимо связаться с модератором",
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          TextButton(
            onPressed: () {
              _saveProfileChanges();
              Navigator.pop(context);
            },
            child: Text("Сохранить", style: TextStyle(color: Colors.blue)),
          ),
        ],
      );
    },
  );
}

Widget _buildTextField(String label, TextEditingController controller, {bool isEditable = true}) {
  return TextField(
    controller: controller,
    readOnly: !isEditable,
    decoration: InputDecoration(
      labelText: label,
      counterStyle: TextStyle(color: Colors.white),
      labelStyle: TextStyle(color: Colors.white),
    ),
    style: TextStyle(color: Colors.white),
    maxLength: 30,
  );
}

Widget _buildWeekendsField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Weekends", style: TextStyle(color: Colors.white)),
      Column(
        children: List.generate(7, (index) {
          int day = index + 1;  // 1 = пн, 7 = вс
          return ListTile(
            title: Text(
              _convertWeekday(day), 
              style: TextStyle(color: Colors.white),
            ),
            trailing: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Checkbox(
                  value: weekends.contains(day),
                  onChanged: (bool? newValue) {
                    setState(() {
                      if (newValue == true) {
                        if (!weekends.contains(day)) weekends.add(day);
                      } else {
                        weekends.remove(day);
                      }
                    });
                  },
                  activeColor: Colors.blue,
                );
              },
            ),
          );
        }),
      ),
    ],
  );
}

void _saveProfileChanges() async {
  final updatedData = <String, dynamic>{};

  if (isSelfProfile) {
    if (_nameController.text.isNotEmpty) {
      updatedData['Name'] = _nameController.text;
    }
    if (_emailController.text.isNotEmpty) {
      updatedData['mail'] = _emailController.text;
    }
    if (_passwordController.text.isNotEmpty) {
      updatedData['password'] = _passwordController.text;
    }
  }

  if (isModerator) {
    updatedData.addAll({
      'quota': _quotaController.text,
      'Proffesion': _professionController.text,
      'weekends': weekends,
      'defaultBreak': {
        'start': _defaultBreakStartController.text,
        'end': _defaultBreakEndController.text,
      },
    });
  }

  await FirebaseFirestore.instance.collection('Users').doc(userID).update(updatedData);
  _fetchUserProfile();
}

Future<void> _handleLogout() async {
  userID = '';
  LoggeduserID = '';
  Profession = '';

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('loggeduserID');
  await prefs.remove('Profession');

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => LoginPage()),
    (Route route) => false,
  );
}


  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Profile",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
                actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditProfileDialog,
          ),
          IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.red),
              onPressed: _handleLogout,
              tooltip: 'Выход из системы',
          )
        ],
      ),
      body: SingleChildScrollView(  
        child: StreamBuilder<DocumentSnapshot>(
          stream: _getUserData(userID), 
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
              stream: _calculateTotalQuotaBalance(userID), 
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
                                  totalQuotaBalance > 0
                                      ? Icons.arrow_upward
                                      : totalQuotaBalance < 0
                                          ? Icons.arrow_downward
                                          : Icons.remove, 
                                  color: totalQuotaBalance > 0
                                      ? Colors.blue
                                      : totalQuotaBalance < 0
                                          ? Colors.red
                                          : Colors.white, 
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '$totalQuotaBalance',
                                  style: TextStyle(
                                    color: totalQuotaBalance > 0
                                        ? Colors.blue
                                        : totalQuotaBalance < 0
                                            ? Colors.red
                                            : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
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

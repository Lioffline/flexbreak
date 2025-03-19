import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TimeManagementPage.dart';
import 'variable.dart';

class CalendarPage extends StatefulWidget {
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late Map<DateTime, List<Map<String, dynamic>>> _events;
  final Map<DateTime, List<Map<String, dynamic>>> _customBreaks = {};
  

  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showCalendarFormats = false;

  List<int> _nonWorkingDays = [];
  String _defaultBreakStart = '13:30';
  String _defaultBreakEnd = '14:00';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _events = {};
    _loadUserDefaultBreak();
    _loadUserDefaultBreakStream();
  }

  Stream<List<int>> _loadUserWeekends() {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userID)
        .snapshots()
        .map((userDoc) {
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> weekends = userData['weekends'] ?? [];
        return weekends.map((e) => e as int).toList();
      }
      return [];
    });
  }

  Future<void> _loadUserDefaultBreak() async {
    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userID.toString()).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      final breakData = userData?['defaultBreak'] as Map<String, dynamic>;

      setState(() {
        _defaultBreakStart = breakData['start'] ?? '13:30';
        _defaultBreakEnd = breakData['end'] ?? '14:00';
      });

      _addDefaultBreaks();
    }
  }

  void _loadUserDefaultBreakStream() {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userID)
        .snapshots()
        .listen((userDoc) {
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final breakData = userData['defaultBreak'] as Map<String, dynamic>;

        setState(() {
          _defaultBreakStart = breakData['start'] ?? '13:30';
          _defaultBreakEnd = breakData['end'] ?? '14:00';
        });

        _addDefaultBreaks();
      }
    });
  }

  void _addDefaultBreaks() {
    final now = DateTime.now();
    final startDefault = _parseTime(_defaultBreakStart);
    final endDefault = _parseTime(_defaultBreakEnd);

    for (int i = 0; i < 60; i++) {
      final day = now.add(Duration(days: i));
      final dateKey = DateTime(day.year, day.month, day.day);
      _events[dateKey] = [
        {'start': startDefault, 'end': endDefault}
      ];
    }
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, hours, minutes);
  }

  Stream<Map<DateTime, List<Map<String, dynamic>>>> _loadBreaksFromFirestore() {
    return FirebaseFirestore.instance
        .collection('Breaks')
        .where('UserID', isEqualTo: userID)
        .snapshots()
        .map((snapshot) {
      final customBreaks = <DateTime, List<Map<String, dynamic>>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp dateTimestamp = data['date'];
        final DateTime date = dateTimestamp.toDate();

        final Timestamp startTimestamp = data['start'];
        final DateTime start = startTimestamp.toDate();

        final Timestamp endTimestamp = data['end'];
        final DateTime end = endTimestamp.toDate();

        final String quota = data['quota'];

        final dateKey = DateTime(date.year, date.month, date.day);

        if (!customBreaks.containsKey(dateKey)) {
          customBreaks[dateKey] = [];
        }
        customBreaks[dateKey]!.add({
          'start': start,
          'end': end,
          'message': data['message'],
          'quota': quota,
        });
      }

      return customBreaks;
    });
  }

  List<Map<String, dynamic>> _getBreaksForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);

    if (_customBreaks.containsKey(dateKey)) {
      return _customBreaks[dateKey]!;
    }
    if (_nonWorkingDays.contains(day.weekday)) {
      return [
        {'start': DateTime(day.year, day.month, day.day), 'end': DateTime(day.year, day.month, day.day), 'message': 'Нерабочий день'}
      ];
    }
    return _events[dateKey] ?? [];
  }

String? _calculateRemainingQuota(List<Map<String, dynamic>> breaks) {
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

  final remainingQuota = maxQuota - totalMinutes;
  return remainingQuota.toString();
}


  int _parseQuotaToMinutes(String quota) {
    final parts = quota.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _setCalendarFormat(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TimeManagementPage()),
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
        actions: [
          IconButton(
            icon: Icon(
              _showCalendarFormats ? Icons.close : Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showCalendarFormats = !_showCalendarFormats;
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: _navigateToProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(  
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              height: _showCalendarFormats ? 60 : 0,
              child: _showCalendarFormats
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCalendarButton(CalendarFormat.month, Icons.calendar_today),
                        SizedBox(width: 16),
                        _buildCalendarButton(CalendarFormat.week, Icons.date_range),
                        SizedBox(width: 16),
                        _buildCalendarButton(CalendarFormat.twoWeeks, Icons.calendar_view_week),
                      ],
                    )
                  : SizedBox.shrink(),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                return _customBreaks.containsKey(DateTime(day.year, day.month, day.day)) ? _getBreaksForDay(day) : [];
              },
              calendarFormat: _calendarFormat,
              locale: 'ru_RU',
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                headerMargin: EdgeInsets.only(bottom: 8),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                todayTextStyle: TextStyle(color: Colors.blue, fontSize: 18),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                defaultTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              availableGestures: AvailableGestures.all,
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, date) {
                  return Column(
                    children: [
                      Text(
                        DateFormat('MMMM').format(date),
                        style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('yyyy').format(date),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
            StreamBuilder<List<int>>(
              stream: _loadUserWeekends(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData) {
                  _nonWorkingDays = snapshot.data!;

                  return StreamBuilder<Map<DateTime, List<Map<String, dynamic>>>>(
                    stream: _loadBreaksFromFirestore(),
                    builder: (context, breakSnapshot) {
                      if (breakSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (breakSnapshot.hasData) {
                        final breaksForSelectedDay = _getBreaksForDay(_selectedDay);
                        final remainingQuota = _calculateRemainingQuota(breaksForSelectedDay);
                        _customBreaks.clear();
                        _customBreaks.addAll(breakSnapshot.data!);

                        return Column(
                          children: [
                            if (remainingQuota != null)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    int.parse(remainingQuota) > 0
                                        ? Icons.arrow_upward
                                        : int.parse(remainingQuota) < 0
                                            ? Icons.arrow_downward
                                            : Icons.remove, 
                                    color: int.parse(remainingQuota) > 0
                                        ? Colors.blue
                                        : int.parse(remainingQuota) < 0
                                            ? Colors.red
                                            : Colors.white, 
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    remainingQuota,
                                    style: TextStyle(
                                      color: int.parse(remainingQuota) > 0
                                          ? Colors.blue
                                          : int.parse(remainingQuota) < 0
                                              ? Colors.red
                                              : Colors.white, 
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                              ),
                            ...breaksForSelectedDay.map((breakInfo) {
                              final breakStart = breakInfo['start'] as DateTime;
                              final breakEnd = breakInfo['end'] as DateTime;
                              final message = breakInfo['message'] as String?;
                              final formattedStartTime = DateFormat('HH:mm').format(breakStart);
                              final formattedEndTime = DateFormat('HH:mm').format(breakEnd);

                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  title: Text(
                                    "$formattedStartTime - $formattedEndTime",
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    message ?? '',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                  ),
                                  tileColor: Colors.transparent,
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }

                      return Center(child: Text("Ошибка загрузки данных"));
                    },
                  );
                }

                return Center(child: Text("Ошибка загрузки выходных"));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarButton(CalendarFormat format, IconData icon) {
    return GestureDetector(
      onTap: () {
        _setCalendarFormat(format);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: _calendarFormat == format ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: _calendarFormat == format ? Colors.white : Colors.white),
          ],
        ),
      ),
    );
  }
}

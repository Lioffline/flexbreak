import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'variable.dart';

class TimeManagementPage extends StatefulWidget {
  @override
  _TimeManagementPageState createState() => _TimeManagementPageState();
}

class _TimeManagementPageState extends State<TimeManagementPage> {
  DateTime _selectedDate = DateTime.now();
  String _defaultQuota = "00:30";
  DateTime _defaultStartTime = DateTime.now().add(Duration(hours: 13));
  DateTime _defaultEndTime = DateTime.now().add(Duration(hours: 13, minutes: 30));

  int get userIDInt => int.tryParse(userID) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<bool> _isTimeOverlapping(DateTime start, DateTime end) async {
      final query = await FirebaseFirestore.instance
          .collection('Breaks')
          .where('UserID', isEqualTo: userIDInt)
          .where('date', isEqualTo: Timestamp.fromDate(
            DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
          ))
          .get();

      for (var doc in query.docs) {
        final breakData = doc.data();
        final existingStart = (breakData['start'] as Timestamp).toDate();
        final existingEnd = (breakData['end'] as Timestamp).toDate();
        if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
          return true;
        }
      }
      return false;
    }

  Future<void> _loadUserProfile() async {
    try {
      final userProfileSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userID)
          .get();

      if (userProfileSnapshot.exists) {
        final userData = userProfileSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _defaultQuota = userData['quota'] ?? "00:30";
          final defaultBreak = userData['defaultBreak'] as Map<String, dynamic>?;
          if (defaultBreak != null) {
            final startStr = defaultBreak['start'] as String? ?? "13:00";
            final endStr = defaultBreak['end'] as String? ?? "13:30";
            _defaultStartTime = _parseTimeToDate(startStr);
            _defaultEndTime = _parseTimeToDate(endStr);
          }
        });
      }
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }

  DateTime _parseTimeToDate(String timeStr) {
    final timeFormat = DateFormat("HH:mm");
    final time = timeFormat.parse(timeStr);
    return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour, time.minute);
  }

void _selectDate() async {
  final firstDate = (Profession == "Модератор") ? DateTime(2020) : DateTime.now();
  
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: firstDate,
    lastDate: DateTime(2030),
  );

  if (pickedDate != null) {
    if (Profession != "Модератор" && pickedDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Вы не можете выбирать прошедшие даты")),
      );
    } else {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
}

  Future<void> _addBreak(DateTime start, DateTime end, String message) async {
    final breakData = {
      'UserID': userIDInt,
      'date': Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)),
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'message': message,
      'quota': _defaultQuota,
    };

    await FirebaseFirestore.instance.collection('Breaks').add(breakData);
  }


  Future<void> _deleteBreak(String breakId) async {
    await FirebaseFirestore.instance.collection('Breaks').doc(breakId).delete();
  }

  void _openAddBreakDialog() {
    if (Profession != "Модератор" && _selectedDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Вы не можете добавлять перерывы на прошедшие даты")),
      );
      return;
    }

    DateTime start = _defaultStartTime;
    DateTime end = _defaultEndTime;
    String message = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Добавить новый перерыв',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Сообщение',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => message = value,
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(start),
                              );
                              if (pickedTime != null) {
                                setDialogState(() {
                                  start = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                    _selectedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  // Ensure end is at least 30 mins after start
                                  if (end.isBefore(start.add(Duration(minutes: 30)))) {
                                    end = start.add(Duration(minutes: 30));
                                  }
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(
                              'Начало',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(end),
                              );
                              if (pickedTime != null) {
                                setDialogState(() {
                                  final tempEnd = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                    _selectedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  if (tempEnd.isAfter(start)) {
                                    end = tempEnd;
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Время конца должно быть позже начала")),
                                    );
                                  }
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(
                              'Конец',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Отмена',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (message.isEmpty) message = 'Нет описания';
                            
                            if (await _isTimeOverlapping(start, end)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Этот перерыв пересекается с существующим")),
                              );
                            } else {
                              _addBreak(start, end, message);
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(
                            'Добавить',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('d MMMM yyyy', 'ru').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Созданные перерывы",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Breaks')
                  .where('UserID', isEqualTo: userIDInt)
                  .where('date', isEqualTo: Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)))
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final breaks = snapshot.data!.docs;

                if (breaks.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет созданных перерывов на этот день',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: breaks.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final breakData = breaks[index].data() as Map<String, dynamic>;
                    final startTime = DateFormat('HH:mm').format((breakData['start'] as Timestamp).toDate());
                    final endTime = DateFormat('HH:mm').format((breakData['end'] as Timestamp).toDate());
                    final message = breakData['message'] ?? '';

                    return Card(
                      margin: EdgeInsets.all(8),
                      color: Colors.grey[900],
                      child: ListTile(
                        title: Text(
                          '$startTime - $endTime',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(message, style: TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteBreak(breaks[index].id);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.calendar_today, color: Colors.blue),
              onPressed: _selectDate,
            ),
          ),
          FloatingActionButton(
            onPressed: _openAddBreakDialog,
            backgroundColor: Colors.blue,
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

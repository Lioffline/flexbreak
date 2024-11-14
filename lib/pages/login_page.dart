import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'usersQuotaPage.dart';
import 'variable.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';

  final _nameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<int> _getNextUserId() async {
    final counterDoc = FirebaseFirestore.instance.collection('metadata').doc('userCounter');
    final counterSnapshot = await counterDoc.get();

    if (!counterSnapshot.exists) {
      await counterDoc.set({'count': 1});
      return 1;
    } else {
      int nextId = counterSnapshot['count'] + 1;
      await counterDoc.update({'count': nextId});
      return nextId;
    }
  }

  Future<void> _login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  try {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('mail', isEqualTo: email)
        .where('password', isEqualTo: password)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      userID = userSnapshot.docs.first.id;
      LoggeduserID = userID;
      Profession = userSnapshot.docs.first['Proffesion'];

      setState(() {
        userID = userID;
        LoggeduserID = LoggeduserID;
        Profession = Profession;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggeduserID', LoggeduserID);
      await prefs.setString('Profession', Profession);

      if (Profession == "Модератор") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UsersQuotaPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } else {
      setState(() {
        errorMessage = 'Неверный email или пароль';
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Произошла ошибка. Попробуйте позже.';
    });
  }
}


  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        errorMessage = 'Неверный формат email';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Пароли не совпадают';
      });
      return;
    }

    final emailCheck = await FirebaseFirestore.instance
        .collection('Users')
        .where('mail', isEqualTo: email)
        .get();

    if (emailCheck.docs.isNotEmpty) {
      setState(() {
        errorMessage = 'Пользователь с таким email уже существует';
      });
      return;
    }

    try {
      int newUserId = await _getNextUserId();

      await FirebaseFirestore.instance.collection('Users').doc(newUserId.toString()).set({
        'Name': name,
        'Proffesion': 'Неподтвержденный аккаунт',
        'defaultBreak': {
          'start': '00:00',
          'end': '00:00',
        },
        'mail': email,
        'password': password,
        'quota': '00:00',
        'weekends': [6, 7],
      });

      Navigator.of(context).pop();
      setState(() {
        errorMessage = 'Регистрация прошла успешно. Войдите в систему.';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Произошла ошибка при регистрации.';
      });
    }
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('Регистрация', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: Colors.white),
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: 'ФИО',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.person, color: Colors.white),
                    counterText: '',
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _registerEmailController,
                  style: TextStyle(color: Colors.white),
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.email, color: Colors.white),
                    counterText: '',
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _registerPasswordController,
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: 'Пароль',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                    counterText: '',
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: 'Подтвердите пароль',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена', style: TextStyle(color: Colors.blueAccent)),
            ),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              
              child: Text('Создать аккаунт'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 10),
                Text(
                  'Вход в систему',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.email, color: Colors.white),
                        border: InputBorder.none,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Пароль',
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.lock, color: Colors.white),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Войти',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _showRegisterDialog,
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Зарегистрироваться',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

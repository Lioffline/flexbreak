import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  final String apiUrl = "http://localhost:5000";  // Временно локально для тестирования


  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        userID = responseData['userID'];
        LoggeduserID = responseData['userID'];
        Profession = responseData['profession'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loggeduserID', LoggeduserID);
        await prefs.setString('Profession', Profession);

        if (Profession == "Модератор") {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UsersQuotaPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
        }
      } else {
        setState(() {
          errorMessage = responseData['message'] ?? 'Ошибка входа';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка подключения: $e';
      });
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Пароли не совпадают';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        setState(() {
          errorMessage = 'Регистрация успешна. Войдите в систему.';
        });
      } else {
        setState(() {
          errorMessage = responseData['message'] ?? 'Ошибка регистрации';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка подключения: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(''), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: Colors.white, size: 32),
                SizedBox(width: 10),
                Text('Вход в систему',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            SizedBox(height: 40),
            _buildInputField(_emailController, 'Email', Icons.email),
            SizedBox(height: 20),
            _buildInputField(_passwordController, 'Пароль', Icons.lock, obscureText: true),
            SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 14)),
            SizedBox(height: 20),
            _buildButton('Войти', _login),
            SizedBox(height: 20),
            TextButton(
              onPressed: _showRegisterDialog,
              child: Text('Зарегистрироваться', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white),
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.grey[900],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        minimumSize: Size(double.infinity, 50),
      ),
      child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('Регистрация', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInputField(_nameController, 'ФИО', Icons.person),
              SizedBox(height: 10),
              _buildInputField(_registerEmailController, 'Email', Icons.email),
              SizedBox(height: 10),
              _buildInputField(_registerPasswordController, 'Пароль', Icons.lock, obscureText: true),
              SizedBox(height: 10),
              _buildInputField(_confirmPasswordController, 'Подтвердите пароль', Icons.lock, obscureText: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Отмена')),
            _buildButton('Создать аккаунт', _register),
          ],
        );
      },
    );
  }
}

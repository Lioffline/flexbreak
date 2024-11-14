import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    CalendarPage(), 
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 

      body: _pages[_selectedIndex],  
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;  
          });
        },
        backgroundColor: Colors.black, 
        selectedItemColor: Colors.blue,  
        unselectedItemColor: Colors.white70,  

        items: const [
          BottomNavigationBarItem( 
            icon: Icon(Icons.done),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: '',
          ),
        ],
        iconSize: 32
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_application_2/folder/browse.dart';
import 'package:flutter_application_2/folder/stream.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [Browse(), StreamPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icons/vlc.png', height: 24),
            const SizedBox(width: 15),
            const Text("VLC Clone", style: TextStyle(fontSize: 30)),
          ],
        ),
        backgroundColor: Colors.black87,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black87,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/ic_browse.png')),
            label: 'Browse',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Stream'),
        ],
      ),
    );
  }
}

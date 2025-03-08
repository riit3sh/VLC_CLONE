import 'package:flutter/material.dart';
import 'package:flutter_application_2/folder/audio.dart';
import 'package:flutter_application_2/folder/browse.dart';
import 'package:flutter_application_2/folder/more.dart';
import 'package:flutter_application_2/folder/playlists.dart';
import 'package:flutter_application_2/folder/video.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const Video(),
    const Audio(),
    const Browse(),
    const Playlists(),
    const More(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize:
              MainAxisSize.min, // Prevents the row from taking full width
          children: [
            Image.asset(
              'assets/icons/vlc.png',
              height: 24,
            ), // Use VLC cone as logo
            const SizedBox(width: 15), // Add spacing between logo and text
            const Text("VLC Clone", style: TextStyle(fontSize: 30)),
          ],
        ),
        backgroundColor: Colors.black87,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/ic_video.png', _selectedIndex == 0),
            label: 'Video',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/ic_audio.png', _selectedIndex == 1),
            label: 'Audio',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/ic_browse.png', _selectedIndex == 2),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(
              'assets/icons/ic_playlist.png',
              _selectedIndex == 3,
            ),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/icons/ic_more.png', _selectedIndex == 4),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange, // Matches label color
        unselectedItemColor: Colors.grey, // Matches unselected label color
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black87,
      ),
    );
  }

  Widget _buildIcon(String assetPath, bool isSelected) {
    return ImageIcon(
      AssetImage(assetPath),
      size: 24,
      color:
          isSelected
              ? Colors.orange
              : Colors.grey, // Dynamic color based on selection
    );
  }
}

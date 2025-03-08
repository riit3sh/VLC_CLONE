import 'package:flutter/material.dart';

class Video extends StatefulWidget {
  const Video({super.key});

  @override
  State<Video> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Video> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.yellow);
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class Browse extends StatefulWidget {
  const Browse({super.key});

  @override
  State<Browse> createState() => _BrowseState();
}

class _BrowseState extends State<Browse> {
  List<FileSystemEntity> _entities = [];
  String _currentPath = '';
  bool _isLoading = true;
  String _errorMessage = '';
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  final List<String> _videoExtensions = [
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
    '.flv',
    '.mpeg',
    '.mpg',
    '.m4v',
    '.3gp',
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        status = await Permission.videos.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.storage.request();
    }
    setState(() => _permissionStatus = status);
    if (status.isGranted) {
      final initialPath = await _getInitialDirectory();
      if (initialPath != null) {
        await _loadDirectoryContents(initialPath);
      } else {
        setState(() {
          _errorMessage = 'Could not find a valid directory.';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Permission denied. Please allow media access.';
        _isLoading = false;
      });
    }
  }

  Future<String?> _getInitialDirectory() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Movies';
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> _loadDirectoryContents(String path) async {
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        final contents = await directory.list().toList();
        setState(() {
          _entities =
              contents.where((entity) {
                if (entity is Directory) return true;
                if (entity is File) {
                  final extension = entity.path.split('.').last.toLowerCase();
                  return _videoExtensions.contains('.$extension');
                }
                return false;
              }).toList();
          _currentPath = path;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading directory: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToParentDirectory() {
    final parentDirectory = Directory(_currentPath).parent;
    _loadDirectoryContents(parentDirectory.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Browse - $_currentPath')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                itemCount: _entities.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // ".." option at the top
                    return ListTile(
                      leading: const Icon(Icons.arrow_upward),
                      title: const Text('..'),
                      onTap: _navigateToParentDirectory,
                    );
                  }
                  final entity = _entities[index - 1];
                  return ListTile(
                    leading:
                        entity is Directory
                            ? const Icon(Icons.folder)
                            : const Icon(Icons.videocam),
                    title: Text(entity.path.split('/').last),
                    onTap: () {
                      if (entity is Directory) {
                        _loadDirectoryContents(entity.path);
                      } else if (entity is File) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    VideoPlayerScreen(videoPath: entity.path),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VlcPlayerController _vlcController;
  bool _isPlaying = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _vlcController = VlcPlayerController.file(
      File(widget.videoPath),
      hwAcc: HwAcc.auto,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    _vlcController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPosition = _vlcController.value.position;
          _totalDuration = _vlcController.value.duration;
          _isPlaying = _vlcController.value.isPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _vlcController.pause();
    } else {
      _vlcController.play();
    }
  }

  void _seekForward() {
    _vlcController.seekTo(_currentPosition + const Duration(seconds: 10));
  }

  void _seekBackward() {
    _vlcController.seekTo(_currentPosition - const Duration(seconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.videoPath.split('/').last)),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: VlcPlayer(
                controller: _vlcController,
                aspectRatio: 16 / 9,
                placeholder: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: _seekBackward,
                ),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: _seekForward,
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value:
                _totalDuration.inSeconds > 0
                    ? _currentPosition.inSeconds / _totalDuration.inSeconds
                    : 0,
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: Browse()));
}

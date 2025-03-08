import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_player/video_player.dart';

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
    print('Initializing Browse screen');
    _checkAndRequestPermissions()
        .then((_) => print('Permission check completed'))
        .catchError((e) {
          print('Error in permission check: $e');
          setState(() {
            _errorMessage = 'Error requesting permission: $e';
            _isLoading = false;
          });
        });
  }

  Future<void> _checkAndRequestPermissions() async {
    print('Checking storage permission status');
    PermissionStatus status;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      print('Android SDK Version: ${androidInfo.version.sdkInt}');

      status = await _requestPermission(Permission.videos);
      print('Permission request result: $status');
    } else {
      print('Non-Android platform detected, checking storage permission');
      status = await Permission.storage.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
        print('Storage permission request result: $status');
      }
    }

    print('Current permission status: $status');
    setState(() => _permissionStatus = status);

    if (status.isGranted) {
      final initialPath = await _getInitialDirectory();
      print('Initial path: $initialPath');
      if (initialPath != null) {
        await _loadDirectoryContents(initialPath);
      } else {
        setState(() {
          _errorMessage = 'Could not find a valid directory.';
          _isLoading = false;
        });
      }
    } else if (status.isDenied) {
      setState(() {
        _errorMessage = 'Permission denied. Please allow media access.';
        _isLoading = false;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage = 'Permission permanently denied. Enable it in settings.';
        _isLoading = false;
      });
    }
  }

  Future<PermissionStatus> _requestPermission(Permission permission) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      print('Android 13+ detected, requesting READ_MEDIA_VIDEO');
      return await Permission.videos.request();
    } else if (androidInfo.version.sdkInt >= 30) {
      print('Android 10-12 detected, requesting manageExternalStorage');
      return await Permission.manageExternalStorage.request();
    } else {
      print('Android < 10 detected, requesting storage');
      return await permission.request();
    }
  }

  Future<void> _openAppSettings() async {
    print('Opening app settings');
    await openAppSettings();
    await _checkAndRequestPermissions();
  }

  Future<void> _requestPermissionManually() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _checkAndRequestPermissions();
  }

  Future<String?> _getInitialDirectory() async {
    try {
      print('Getting initial directory');
      String? directoryPath;
      if (Platform.isAndroid) {
        final possiblePaths = [
          '/storage/emulated/0',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
        ];

        for (final path in possiblePaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            print('Found accessible directory: $path');
            directoryPath = path;
            break;
          } else {
            print('Directory does not exist: $path');
          }
        }

        if (directoryPath == null) {
          final dir =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
          directoryPath = dir?.path;
          print('Falling back to: $directoryPath');
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        directoryPath = dir?.path;
        print('Non-Android platform, using: $directoryPath');
      }
      return directoryPath;
    } catch (e) {
      print('Error getting initial directory: $e');
      return null;
    }
  }

  Future<void> _loadDirectoryContents(String path) async {
    print('Loading directory contents from: $path');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        final contents = await directory.list(recursive: false).toList();
        print('Found ${contents.length} items in $path');
        for (final entity in contents) {
          print('Item: ${entity.path} (${entity.runtimeType})');
        }

        final filteredEntities =
            contents.where((entity) {
              if (entity is Directory) {
                print('Including directory: ${entity.path}');
                return true;
              }
              if (entity is File) {
                final extension = entity.path.split('.').last.toLowerCase();
                final isVideo = _videoExtensions.contains('.$extension');
                print(
                  'File: ${entity.path}, Extension: $extension, Is Video: $isVideo',
                );
                return isVideo;
              }
              return false;
            }).toList();

        // Add ".." entry if not at root
        if (path != '/storage/emulated/0' && path != '/') {
          filteredEntities.insert(
            0,
            Directory('..'), // Special entry for parent directory
          );
        }

        print('Filtered entities: ${filteredEntities.length} items');
        for (final entity in filteredEntities) {
          print('Filtered item: ${entity.path}');
        }

        setState(() {
          _entities = filteredEntities;
          _currentPath = path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Directory does not exist: $path';
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

  Widget _subtitle(FileSystemEntity entity) {
    if (entity is File) {
      return FutureBuilder<int>(
        future: entity.length(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text('${(snapshot.data! / 1024).toStringAsFixed(2)} KB');
          }
          return const Text('Calculating...');
        },
      );
    } else if (entity is Directory) {
      return const Text('Directory');
    }
    return const Text('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VLC Clone - $_currentPath'),
        actions: [
          if (_permissionStatus.isDenied ||
              _permissionStatus.isPermanentlyDenied)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _requestPermissionManually,
              tooltip: 'Request Permission',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    if (_permissionStatus.isPermanentlyDenied)
                      ElevatedButton(
                        onPressed: _openAppSettings,
                        child: const Text('Open Settings'),
                      ),
                    if (_permissionStatus.isDenied)
                      ElevatedButton(
                        onPressed: _requestPermissionManually,
                        child: const Text('Request Permission'),
                      ),
                  ],
                ),
              )
              : _entities.isEmpty
              ? const Center(
                child: Text('No video files or directories found.'),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                itemCount: _entities.length,
                itemBuilder: (context, index) {
                  final entity = _entities[index];
                  final isDirectory = entity is Directory;
                  final isParentDir = entity.path == '..' && index == 0;
                  return Card(
                    child: ListTile(
                      leading:
                          isParentDir
                              ? const Icon(Icons.arrow_upward)
                              : (isDirectory
                                  ? const Icon(Icons.folder)
                                  : const Icon(Icons.videocam)),
                      title: Text(
                        isParentDir ? '..' : entity.path.split('/').last,
                      ),
                      subtitle: isParentDir ? null : _subtitle(entity),
                      onTap: () async {
                        if (isParentDir) {
                          final parentDir = Directory(_currentPath).parent.path;
                          print('Navigating to parent directory: $parentDir');
                          await _loadDirectoryContents(parentDir);
                        } else if (isDirectory) {
                          await _loadDirectoryContents(entity.path);
                        } else if (entity is File) {
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => VideoPlayerScreen(
                                      videoPath: entity.path,
                                    ),
                              ),
                            );
                          } catch (e) {
                            print('Error navigating to video player: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to open video: $e. Try a different file or format.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
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
  late VideoPlayerController _videoController;
  String _errorMessage = '';
  bool _isLoading = true;
  bool _isInitialized = false;
  double _aspectRatio = 16 / 9; // Default aspect ratio

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      print(
        'Initializing VideoPlayerController with path: ${widget.videoPath}',
      );
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Video file not found: ${widget.videoPath}';
          _isLoading = false;
        });
        return;
      }

      _videoController = VideoPlayerController.file(file);
      await _videoController
          .initialize()
          .then((_) {
            print('VideoPlayerController initialized successfully');
            // Calculate aspect ratio from video dimensions
            final videoWidth = _videoController.value.size.width;
            final videoHeight = _videoController.value.size.height;
            print('Video dimensions: width=$videoWidth, height=$videoHeight');

            setState(() {
              _isLoading = false;
              _isInitialized = true;
              // Use video dimensions to calculate aspect ratio, with fallback
              _aspectRatio =
                  (videoWidth > 0 && videoHeight > 0)
                      ? videoWidth / videoHeight
                      : 16 / 9;
              print('Calculated aspect ratio: $_aspectRatio');
            });
            _videoController.play();
          })
          .catchError((e) {
            print('Error initializing VideoPlayerController: $e');
            setState(() {
              _errorMessage = 'Failed to initialize video player: $e';
              _isLoading = false;
            });
          });

      _videoController.addListener(() {
        if (_videoController.value.hasError) {
          print(
            'VideoPlayerController error: ${_videoController.value.errorDescription}',
          );
          setState(() {
            _errorMessage =
                'Failed to play video: ${_videoController.value.errorDescription}';
            _isLoading = false;
          });
        }
        // Update state to reflect playback position changes
        setState(() {});
      });
    } catch (e) {
      print('Exception during initialization: $e');
      setState(() {
        _errorMessage = 'Error initializing player: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playing: ${widget.videoPath.split('/').last}'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
              : _isInitialized
              ? Column(
                children: [
                  // Use Expanded to ensure the video takes available space
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _aspectRatio,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _videoController.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (_videoController.value.isPlaying) {
                            _videoController.pause();
                          } else {
                            _videoController.play();
                          }
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () {
                          _videoController.pause();
                          _videoController.seekTo(Duration.zero);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        onPressed: () {
                          _videoController.seekTo(
                            _videoController.value.position -
                                const Duration(seconds: 10),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        onPressed: () {
                          _videoController.seekTo(
                            _videoController.value.position +
                                const Duration(seconds: 10),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Duration: ${_videoController.value.duration.inMinutes}:${(_videoController.value.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                  Text(
                    'Position: ${_videoController.value.position.inMinutes}:${(_videoController.value.position.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 20),
                ],
              )
              : const Center(child: Text('Initializing video player...')),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: Browse()));
}

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({Key? key}) : super(key: key);

  @override
  _LiveStreamScreenState createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  VlcPlayerController? _videoPlayerController; // Make it nullable
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _videoPlayerController?.dispose(); // Dispose if not null
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer(String url) async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.stop();
      await _videoPlayerController!.dispose();
    }

    // Initialize the VLC player controller
    _videoPlayerController = VlcPlayerController.network(
      url,
      hwAcc: HwAcc.auto,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    // Listen for initialization and errors
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.isInitialized && !_isInitialized) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    });

    try {
      debugPrint("Initializing VLC Player for: $url");
      await _videoPlayerController!.initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      });
    } catch (e) {
      debugPrint("Error initializing VLC player: $e");
      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load video: $e")));
    }
  }

  void _playStream() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid URL.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isInitialized = false;
    });

    _initializePlayer(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Stream")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter stream URL (https or ftp)",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _playStream,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Play Stream"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _isInitialized && _videoPlayerController != null
                      ? VlcPlayer(
                        controller: _videoPlayerController!,
                        aspectRatio: 16 / 9,
                        placeholder: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                      : const Center(
                        child: Text(
                          "Enter a valid URL and press 'Play Stream'.",
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

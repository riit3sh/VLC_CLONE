import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class StreamPage extends StatefulWidget {
  const StreamPage({super.key});

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  VlcPlayerController? _vlcController; // Make it nullable
  final TextEditingController _urlController = TextEditingController();
  bool _isInitialized = false;
  bool _isLoading = false;

  void _playStream() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _isInitialized = false;
      });

      // Dispose of the previous controller if it exists
      _vlcController?.dispose();

      debugPrint("Initializing VLC player with URL: $url");

      // Initialize the VLC player controller
      _vlcController = VlcPlayerController.network(
        url,
        hwAcc: HwAcc.auto,
        autoPlay: true,
        options: VlcPlayerOptions(),
      );

      try {
        debugPrint("Waiting for VLC player to initialize...");
        await _vlcController!.initialize();

        if (_vlcController!.value.isInitialized) {
          debugPrint("VLC player initialized successfully.");
          setState(() {
            _isInitialized = true;
            _isLoading = false;
          });
          _vlcController!.play(); // Start playing the video
        } else {
          debugPrint("VLC player failed to initialize.");
          setState(() {
            _isInitialized = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to initialize the video player."),
            ),
          );
        }
      } catch (e) {
        debugPrint("Initialization error: $e");
        setState(() {
          _isInitialized = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Initialization error: $e")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize with an empty controller
    _vlcController = VlcPlayerController.network(
      '', // Initial empty URL
      hwAcc: HwAcc.auto,
      autoPlay: false,
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _vlcController?.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Streams"),
        backgroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter network address (https or ftp)",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _playStream,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Play"),
            ),
            const SizedBox(height: 20),
            _isInitialized
                ? Expanded(
                  child: VlcPlayer(
                    controller: _vlcController!,
                    aspectRatio: 16 / 9,
                    placeholder: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
                : const Text("Enter a valid URL and press play."),
          ],
        ),
      ),
    );
  }
}

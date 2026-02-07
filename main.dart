import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicHomePage(),
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  List songs = [];
  int currentIndex = -1;
  bool isPlaying = false;

  /// 🔎 Search Songs API
  Future<void> searchSongs(String query) async {
    final url =
        "https://itunes.apple.com/search?term=$query&media=music&limit=20";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    setState(() {
      songs = data['results'];
    });
  }

  /// ▶ Play Song
  Future<void> playSong(String url, int index) async {
    await _player.setUrl(url);
    _player.play();

    setState(() {
      currentIndex = index;
      isPlaying = true;
    });
  }

  void playPause() {
    if (isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Streaming App(Bhoomi)"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          /// 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search songs...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    searchSongs(_searchController.text);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          /// 🎶 Song List
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];

                return ListTile(
                  leading: Image.network(
                    song['artworkUrl100'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(song['trackName'] ?? "Unknown"),
                  subtitle: Text(song['artistName'] ?? ""),
                  trailing: IconButton(
                    icon: Icon(
                      currentIndex == index && isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      playSong(song['previewUrl'], index);
                    },
                  ),
                );
              },
            ),
          ),

          /// ▶ Player Controls
          if (currentIndex != -1)
            Column(
              children: [
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = _player.duration ?? Duration.zero;

                    return Slider(
                      min: 0,
                      max: duration.inSeconds.toDouble(),
                      value: position.inSeconds
                          .clamp(0, duration.inSeconds)
                          .toDouble(),
                      onChanged: (value) {
                        _player.seek(Duration(seconds: value.toInt()));
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 50,
                    color: Colors.deepPurple,
                  ),
                  onPressed: playPause,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(SafetyCallApp());

class SafetyCallApp extends StatelessWidget {
  const SafetyCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Safety Call")),
        body: SafetyCallHome(),
      ),
    );
  }
}

class SafetyCallHome extends StatefulWidget {
  const SafetyCallHome({super.key});

  @override
  _SafetyCallHomeState createState() => _SafetyCallHomeState();
}

class _SafetyCallHomeState extends State<SafetyCallHome> {
  final FlutterTts _flutterTts = FlutterTts();  // TTS instance
  final stt.SpeechToText _speech = stt.SpeechToText();  // STT instance

  String _text = "";        // Text input and TTS output
  String _sttText = "";     // Stores the converted text from STT
  bool _isListening = false;  // Track if STT is currently listening

  Future<void> _speakText() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(_text);
  }

  // Method to start listening and convert speech to text
  Future<void> _startListening() async {
    // Check and request microphone permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }

    // Only proceed if microphone permission is granted
    if (status.isGranted) {
      bool available = await _speech.initialize(
        onStatus: (status) => print("STT status: $status"),
        onError: (error) => print("STT error: $error"),
      );
      print("STT initialization result: $available");

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            print("STT result: ${result.recognizedWords}"); 
            setState(() {
              _sttText = result.recognizedWords;
            });
          },
          listenFor: Duration(seconds: 10),
          pauseFor: Duration(seconds: 5),
        );

      } else {
        print("Speech recognition unavailable.");
      }
    } else {
      print("Microphone permission not granted.");
    }
  }




  // Method to stop listening
  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            onChanged: (value) {
              _text = value;
            },
            decoration: InputDecoration(hintText: "Enter text to speak"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _speakText,
            child: Text("Speak"),
          ),
          SizedBox(height: 20),
          Text(
            "Speech-to-Text Result: $_sttText",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isListening ? _stopListening : _startListening,
            child: Text(_isListening ? "Stop Listening" : "Start Listening"),
          ),
        ],
      ),
    );
  }
}

Future<String> fetchProcessedText(String text) async {
  final response = await http.post(
    Uri.parse('http://localhost:5000/process'), 
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"text": text}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["result"];
  } else {
    throw Exception("Failed to process text");
  }
}
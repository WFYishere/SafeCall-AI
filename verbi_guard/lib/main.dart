import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

void main() => runApp(SafetyCallApp());

Future<void> requestStoragePermission() async {
  await Permission.storage.request();
}

Future<String> getExternalFilePath(String filename) async {
  Directory? externalDir = await getExternalStorageDirectory();
  String filePath = '${externalDir!.path}/$filename';

  // Ensure directory exists
  if (!(await externalDir.exists())) {
    await externalDir.create(recursive: true);
  }

  return filePath;
}

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
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  String _text = "";        // Text input and TTS output
  String _sttText = "";     // Stores the converted text from STT
  String _audioPath = "";
  bool _isRecording = false;
  bool _isListening = false;  // Track if STT is currently listening
  String _result = "";

  late final GenerativeModel geminiVisionProModel;
  late final ChatSession chatSession;

  @override
  void initState() {

    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _speakText() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(_text);
  }

  // Method to start listening and convert speech to text
  Future<void> _startRecording() async {
    // Check and request microphone permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    await requestStoragePermission();

    // Only proceed if microphone permission is granted
    if (status.isGranted) {
      String filePath = await getExternalFilePath("my_recording.aac");
      //String filePath = await getRecordingFilePath("my_recording.aac");
      print("Recording to: $filePath"); // For verification
      //Directory tempDir = await getTemporaryDirectory();
      //String filePath = '${tempDir.path}/recording.aac';
      // Start recording and save the audio as MP3
      //String filePath = "my_recording.aac";
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacMP4, // MP3 codec is not natively supported; AAC is a common alternative
      );

      setState(() {
        _audioPath = filePath;
        _isRecording = true;
      });
      // bool available = await _speech.initialize(
      //   onStatus: (status) => print("STT status: $status"),
      //   onError: (error) => print("STT error: $error"),
      // );
      // print("STT initialization result: $available");
      //
      // if (available) {
      //   setState(() => _isListening = true);
      //   _speech.listen(
      //     onResult: (result) {
      //       print("STT result: ${result.recognizedWords}");
      //       setState(() {
      //         _sttText = result.recognizedWords;
      //       });
      //     },
      //     listenFor: Duration(seconds: 10),
      //     pauseFor: Duration(seconds: 5),
      //   );
      //
      // } else {
      //   print("Speech recognition unavailable.");
      // }
    } else {
      print("Microphone permission not granted.");
    }
  }

  // Method to stop recording
  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);
    print("Recording saved at: $_audioPath");
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _sendRecording() async {
    if (_audioPath.isNotEmpty) {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'AIzaSyCpOsksMlrXhUMkBAHehVmVVP4qjBG9RqM',
      );
      print("1");

      Future<DataPart> fileToPart(String mimeType, String path) async {
        return DataPart(mimeType, await File(_audioPath).readAsBytes());
      }

      final prompt = 'Turn the audio into text';
      final audio = await fileToPart('audio/aac', _audioPath);

      final response = await model.generateContent([
        Content.multi([TextPart(prompt), audio])
      ]);
      print(response.text);
      _result = response.text.toString();
    // if (_audioPath.isNotEmpty) {
    //   final file = File(_audioPath);
    //   final request = http.MultipartRequest(
    //     'POST',
    //     Uri.parse('http://10.0.2.2:5000/process'),
    //   );
    //   request.files.add(await http.MultipartFile.fromPath('file', file.path));
    //
    //   final response = await request.send();
    //
    //   if (response.statusCode == 200) {
    //     final responseData = await http.Response.fromStream(response);
    //     final data = jsonDecode(responseData.body);
    //     setState(() {
    //       _result = data['result'];  // Update the result state with the response
    //     });
    //     print("Processed result: $_result");
    //   } else {
    //     setState(() {
    //       _result = 'Failed to process audio file.';
    //     });
    //     print("Failed to process audio file.");
    //   }
    } else {
      setState(() {
        _result = 'No recording available to send.';
      });
      print("No recording available to send.");
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
            onPressed: _isRecording ? _stopRecording : _startRecording,
            child: Text(_isRecording ? "Stop Recording" : "Start Recording"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _sendRecording,
            child: Text("Send Recording for Processing"),
          ),
          SizedBox(height: 20),
          Text(
            "Response: $_result",
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),

        ],
      ),
    );
  }
}

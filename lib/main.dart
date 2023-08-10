import 'dart:io';
import 'package:editor_in_chief/markdown_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: EditorPage(key: UniqueKey(), title: 'Editor in Chief'),
    );
  }
}

TextEditingController textController = TextEditingController();

class EditorPage extends StatefulWidget {
  final String title;

  const EditorPage({required Key key, required this.title}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  Future<void> openFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['txt', 'md']);

    if (result != null) {
      File file = File(result.files.single.path!);
      String contents = await file.readAsString();
      textController.text = contents;
    } else {
      // User canceled the picker
    }
  }

  void saveFile() async {
    String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'text.txt',
        allowedExtensions: ['txt', 'md']);

    if (outputFile != null) {
      File file = File(outputFile);
      file.writeAsString(textController.text);
    } else {
      // User canceled the picker
    }
  }

  void openSettings(BuildContext context) async {
    String? results = await showDialog<String>(
        context: context,
        builder: (BuildContext context) => Dialog(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    const Text('Settings'),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Close"))
                  ],
                ),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(onPressed: openFile, icon: const Icon(Icons.file_open)),
          IconButton(onPressed: saveFile, icon: const Icon(Icons.save)),
          IconButton(
              onPressed: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Settings'),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Close"))
                            ],
                          ),
                        ),
                      )),
              icon: const Icon(Icons.settings))
        ],
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: MarkdownEditor(
          key: UniqueKey(),
          controller: textController,
        ),
      )),
    );
  }
}

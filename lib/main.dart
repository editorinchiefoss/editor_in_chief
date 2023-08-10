import 'dart:io';
import 'package:editor_in_chief/markdown_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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

enum ModelName { gpt4, gpt35turbo, gpt35turbo16k }

class EditorPage extends StatefulWidget {
  final String title;

  const EditorPage({required Key key, required this.title}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  ModelName? _modelName = ModelName.gpt35turbo16k;
  double temperature = 0.1;
  int contextLength = 7000;

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

  void saveOrShareFile() async {
    if (Platform.isIOS || Platform.isAndroid) {
      final box = context.findRenderObject() as RenderBox?;

      await Share.share(
        textController.text,
        subject: "My piece from Editor in Chief",
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    Icon shareIcon;

    if (Platform.isAndroid || Platform.isIOS) {
      shareIcon = const Icon(Icons.share);
    } else {
      shareIcon = const Icon(Icons.save);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(onPressed: openFile, icon: const Icon(Icons.file_open)),
          IconButton(onPressed: saveOrShareFile, icon: shareIcon),
          IconButton(
              onPressed: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                        title: const Text("Model Select"),
                        content: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                const Text('Model select'),
                                ListTile(
                                  title: const Text('ChatGPT'),
                                  leading: Radio<ModelName>(
                                      value: ModelName.gpt35turbo16k,
                                      groupValue: _modelName,
                                      onChanged: (ModelName? value) {
                                        setState(() {
                                          _modelName = value;
                                          if (_modelName ==
                                              ModelName.gpt35turbo16k) {
                                            contextLength = 7000;
                                          } else {
                                            contextLength = 3500;
                                          }
                                        });
                                      }),
                                ),
                                ListTile(
                                  title: const Text('GPT-4'),
                                  leading: Radio<ModelName>(
                                      value: ModelName.gpt4,
                                      groupValue: _modelName,
                                      onChanged: (ModelName? value) {
                                        setState(() {
                                          _modelName = value;
                                          if (_modelName ==
                                              ModelName.gpt35turbo16k) {
                                            contextLength = 7000;
                                          } else {
                                            contextLength = 3500;
                                          }
                                        });
                                      }),
                                )
                              ],
                            ),
                          );
                        }),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Close"))
                        ],
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

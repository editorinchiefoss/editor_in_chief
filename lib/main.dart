import 'dart:core';
import 'dart:io';
import 'package:editor_in_chief/loading_screen.dart';
import 'package:editor_in_chief/markdown_widget.dart';
import 'package:editor_in_chief/diff_widget.dart';
import 'package:editor_in_chief/utils.dart';
import 'package:editor_in_chief/first_run.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktoken/tiktoken.dart' as tiktoken;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editor in Chief',
      routes: {
        '/': (context) => LoadingScreen(key: UniqueKey(), title: 'Loading'),
        '/editor': (context) =>
            EditorPage(key: UniqueKey(), title: 'Editor in Chief'),
        '/first-run': (context) =>
            FirstRun(key: UniqueKey(), title: 'First Run')
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
    );
  }
}

TextEditingController textController = TextEditingController();
TextEditingController apiKeyController = TextEditingController();
TextEditingController promptController = TextEditingController();

enum ModelName { gpt4, gpt4turbo, gpt35turbo16k }

Map<ModelName, String> modelNameMap = {
  ModelName.gpt4: 'gpt-4',
  ModelName.gpt4turbo: 'gpt-4-turbo-preview',
  ModelName.gpt35turbo16k: 'gpt-3.5-turbo-16k'
};

Map<ModelName, int> modelContextWindow = {
  ModelName.gpt4: (8192 * 0.4).floor(),
  ModelName.gpt4turbo: (128000 * .4).floor(),
  ModelName.gpt35turbo16k: (16000 * .4).floor()
};

const String defaultSystemPrompt = """
You are a meticulous copy editor with a keen eye for detail and a deep understanding of language. Your mission is to polish a section of an article, ensuring it gleams with clarity, conciseness, and accuracy.

Approach the text with respect for the author's voice and style. While ensuring impeccable grammar and readability, preserve the unique essence of their writing.

Focus on:

* Grammar and mechanics: Eliminate errors in punctuation, spelling, subject-verb agreement, and sentence structure.
* Readability: Improve clarity by restructuring sentences, eliminating ambiguity, and simplifying complex language.
* Flow and coherence: Ensure smooth transitions between sentences and paragraphs.
* Word choice: Suggest stronger verbs, more precise nouns, and eliminate unnecessary words and repetition.
* Ultimately, return a polished manuscript that retains the author's voice and effectively communicates the intended message.

Additional Tips:

You are encouraged to make suggestions for style improvement, but the final decision rests with the human.

With your expertise, transform this piece into a masterpiece for the human reader!
"""; // rewritten by Gemini 1.5
const double defaultTemperature = 0.1;
const ModelName defaultModelName = ModelName.gpt35turbo16k;

class EditorPage extends StatefulWidget {
  final String title;

  const EditorPage({required Key key, required this.title}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  bool _firstRun = true;
  String _apiKey = '';
  ModelName? _modelName = ModelName.gpt35turbo16k;
  int _contextLength = (modelContextWindow[ModelName.gpt35turbo16k])!;
  double _temperature = 0.1;
  String _editedText = '';
  String _systemPrompt = defaultSystemPrompt;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstRun = prefs.getBool(PrefKeys.firstRun.name) ?? true;
      _apiKey = prefs.getString(PrefKeys.apiKey.name) ?? '';
      _temperature = prefs.getDouble(PrefKeys.temperture.name) ?? 0.1;
      _systemPrompt =
          prefs.getString(PrefKeys.systemPrompt.name) ?? defaultSystemPrompt;

      String storedModelName = prefs.getString(PrefKeys.modelName.name) ?? '';
      if (ModelName.values.map((e) => e.name).contains(storedModelName)) {
        _modelName =
            ModelName.values.firstWhere((e) => e.name == storedModelName);
        _contextLength = modelContextWindow[_modelName]!;
      } else {
        _modelName = ModelName.gpt35turbo16k;
        _contextLength = modelContextWindow[_modelName]!;
      }

      apiKeyController.text = _apiKey;
      promptController.text = _systemPrompt;
    });
  }

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

  void setModel(ModelName? value) {
    setState(() {
      _modelName = value;
      _contextLength = modelContextWindow[value]!;
    });
  }

  void showSettings(BuildContext context) async {
    showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text("Settings"),
              content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      SizedBox(
                        width: 350,
                        child: TextField(
                          controller: apiKeyController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              label: Text("OpenAI API Key")),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Model select'),
                      ListTile(
                        title: const Text('ChatGPT'),
                        leading: Radio<ModelName>(
                            value: ModelName.gpt35turbo16k,
                            groupValue: _modelName,
                            onChanged: (ModelName? value) {
                              setState(() {
                                _modelName = value;
                                _contextLength = modelContextWindow[value]!;
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
                                _contextLength = modelContextWindow[value]!;
                              });
                            }),
                      ),
                      ListTile(
                        title: const Text('GPT-4 Turbo'),
                        leading: Radio<ModelName>(
                            value: ModelName.gpt4turbo,
                            groupValue: _modelName,
                            onChanged: (ModelName? value) {
                              setState(() {
                                _modelName = value;
                                _contextLength = modelContextWindow[value]!;
                              });
                            }),
                      ),
                      const SizedBox(height: 20),
                      const Text("Temperture"),
                      Slider(
                          value: _temperature,
                          max: 1,
                          min: 0,
                          label: _temperature.toString(),
                          divisions: 20,
                          onChanged: (double value) {
                            setState(() {
                              _temperature = value;
                            });
                          }),
                      const SizedBox(height: 20),
                      const Text("Prompt"),
                      TextEditor(
                          text: _systemPrompt,
                          controller: promptController,
                          onChange: (String value) {
                            setState(() {
                              _systemPrompt = value;
                            });
                          })
                    ],
                  ),
                );
              }),
              actions: [
                TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() {
                        _systemPrompt = defaultSystemPrompt;
                        promptController.text = _systemPrompt;
                        _temperature = defaultTemperature;
                        _modelName = defaultModelName;
                        prefs.setString(PrefKeys.apiKey.name, _apiKey);
                        prefs.setString(
                            PrefKeys.modelName.name, _modelName!.name);
                        prefs.setDouble(PrefKeys.temperture.name, _temperature);
                        prefs.setString(
                            PrefKeys.systemPrompt.name, _systemPrompt);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Restore Defaults")),
                TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() {
                        _apiKey = apiKeyController.text;
                        _systemPrompt = promptController.text;
                        prefs.setString(PrefKeys.apiKey.name, _apiKey);
                        prefs.setString(
                            PrefKeys.modelName.name, _modelName!.name);
                        prefs.setDouble(PrefKeys.temperture.name, _temperature);
                        prefs.setString(
                            PrefKeys.systemPrompt.name, _systemPrompt);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Close"))
              ],
            ));
  }

  Future<void> callLLM() async {
    ChatOpenAI llm = ChatOpenAI(apiKey: _apiKey);
    ChatPromptTemplate prompt = ChatPromptTemplate.fromPromptMessages([
      SystemChatMessagePromptTemplate.fromTemplate(defaultSystemPrompt),
      HumanChatMessagePromptTemplate.fromTemplate('{input}')
    ]);
    LLMChain llmChain = LLMChain(llm: llm, prompt: prompt);

    List<String> chunks = [];
    String currChunk = '';
    int currChunkNumTokens = 0;

    final tiktoken.Tiktoken encoding =
        tiktoken.encodingForModel(modelNameMap[_modelName!]!);

    Map<int, String> splits = textController.text.split('\n').asMap();
    int totalSplits = splits.length;
    splits.forEach((idx, split) {
      int newNumTokens = encoding.encode(split).length;

      if (newNumTokens + currChunkNumTokens > _contextLength) {
        chunks.add(currChunk);
        currChunk = split;
        currChunkNumTokens = newNumTokens;
      } else {
        currChunk += "$split\n";
        currChunkNumTokens += newNumTokens + 1;
      }

      if (idx == totalSplits - 1) {
        chunks.add(currChunk);
      }
    });

    List<Future<Map<String, dynamic>>> openAICalls =
        chunks.map((chunk) => llmChain.call(chunk)).toList();

    List<Map<String, dynamic>> responses = await Future.wait(openAICalls);

    List<AIChatMessage> messages =
        responses.map((dynamic e) => e['output'] as AIChatMessage).toList();

    setState(() {
      _editedText = messages
          .map((AIChatMessage message) => message.content)
          .reduce((value, element) => value + element);
    });
  }

  void copyEdit(BuildContext context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text("Loading"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    height: 150,
                    width: 150,
                    child: CircularProgressIndicator()),
              ],
            ),
          );
        });

    callLLM().then((_) => Navigator.of(context).pop(), onError: ((e, s) {
      Navigator.of(context).pop();
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error!"),
              content: const Text('There was an error reaching OpenAI.'),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Dismiss'))
              ],
            );
          });
    }));
  }

  void clearEdits() {
    setState(() {
      _editedText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    Icon shareIcon;
    Widget pane;
    Widget fab;

    if (Platform.isAndroid || Platform.isIOS) {
      shareIcon = const Icon(Icons.share);
    } else {
      shareIcon = const Icon(Icons.save);
    }

    if (_editedText.isNotEmpty) {
      pane =
          DiffView(originalText: textController.text, editedText: _editedText);
      fab = FloatingActionButton(
          onPressed: clearEdits, child: const Icon(Icons.clear));
    } else {
      pane = MarkdownEditor(key: UniqueKey(), controller: textController);
      fab = FloatingActionButton(
        onPressed: () => copyEdit(context),
        child: const Icon(Icons.auto_awesome),
      );
    }

    afterBuildActions(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(onPressed: openFile, icon: const Icon(Icons.file_open)),
          IconButton(
            onPressed: saveOrShareFile,
            icon: shareIcon,
            disabledColor: Colors.grey,
          ),
          IconButton(
              onPressed: () => showSettings(context),
              icon: const Icon(Icons.settings))
        ],
      ),
      body: Center(
          child:
              Padding(padding: const EdgeInsets.only(top: 8.0), child: pane)),
      floatingActionButton: Visibility(visible: _apiKey.isNotEmpty, child: fab),
    );
  }

  Future<void> afterBuildActions(context) async {
    await Future.delayed(Duration.zero);

    if (!_firstRun && _apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          padding: const EdgeInsets.all(5),
          leading: const Icon(Icons.warning),
          content: const Text(
              'You will not be able to take full advantage of the app until you input an OpenAI API Key'),
          actions: <Widget>[
            TextButton(
              onPressed: () => showSettings(context),
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
              child: const Text('Dismiss'),
            )
          ]));
    }
  }
}

import 'package:editor_in_chief/markdown_widget.dart';
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
      home:
          const EditorPage(key: Key('damn, a test'), title: 'Editor in Chief'),
    );
  }
}

class EditorPage extends StatefulWidget {
  final String title;

  const EditorPage({required Key key, required this.title}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body:
          const Center(child: MarkdownEditor(key: Key('main_screen_preview'))),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:editor_in_chief/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

TextEditingController apiKeyController = TextEditingController();

class FirstRun extends StatefulWidget {
  final String title;

  const FirstRun({required Key key, required this.title}) : super(key: key);

  @override
  State<FirstRun> createState() => _FirstRunState();
}

class _FirstRunState extends State<FirstRun> {
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(PrefKeys.apiKey.name, apiKey);
    prefs.setBool(PrefKeys.firstRun.name, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            "Welcome to Editor in Chief!",
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          const Image(image: AssetImage('assets/icon.png')),
          const SizedBox(height: 10),
          Text(
            """Editor in Chief is your personal copy-editor. Bring your original writing and get instant feedback.
      
      In order to use this app, you will need to provide your own OpenAI API key.""",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(
              width: 350,
              child: TextField(
                controller: apiKeyController,
                obscureText: true,
                decoration:
                    const InputDecoration(label: Text("OpenAI API Key")),
              )),
          const SizedBox(height: 10),
          TextButton(
              onPressed: () {
                saveApiKey(apiKeyController.text);
                Navigator.popAndPushNamed(context, '/editor');
              },
              child: const Text("Continue"))
        ],
      ),
    ));
  }
}

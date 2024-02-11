import 'package:flutter/material.dart';
import 'package:editor_in_chief/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadingScreen extends StatefulWidget {
  final String title;

  const LoadingScreen({required Key key, required this.title})
      : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Future<void> loadPrefsAndRedirect(context) async {
    await Future.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    final firstRun = prefs.getBool(PrefKeys.firstRun.name) ?? true;

    if (firstRun) {
      Navigator.popAndPushNamed(context, '/first-run');
    } else {
      Navigator.popAndPushNamed(context, '/editor');
    }
  }

  @override
  Widget build(BuildContext context) {
    loadPrefsAndRedirect(context);

    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Image(image: AssetImage('assets/icon.png')),
          )
        ],
      ),
    );
  }
}

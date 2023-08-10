// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum TextEditMode { edit, preview }

// ignore: avoid_implementing_value_types, must_be_immutable
class MarkdownEditor extends StatefulWidget {
  TextEditingController controller;

  MarkdownEditor({super.key, required this.controller});

  static const String _title = 'Basic Markdown Demo';

  String get title => MarkdownEditor._title;

  Future<String> get data => Future<String>.value('');

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  TextEditMode currMode = TextEditMode.edit;
  String editorText = "";

  void setTextEditMode(TextEditMode newMode) {
    setState(() {
      editorText = widget.controller.value.text;
      currMode = newMode;
    });
  }

  void setText(String value) {
    setState(() {
      editorText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget pane;

    if (currMode == TextEditMode.edit) {
      pane = TextEditor(
        text: editorText,
        controller: widget.controller,
        onChange: setText,
      );
    } else {
      pane = Markdown(
        key: UniqueKey(),
        data: editorText,
        onTapLink: (String text, String? href, String title) =>
            linkOnTapHandler(context, text, href, title),
      );
    }

    return FutureBuilder<String>(
      future: widget.data,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: <Widget>[
              PreviewSelect(
                  selected: currMode, onSelectionChange: setTextEditMode),
              Expanded(child: pane),
            ],
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  // Handle the link. The [href] in the callback contains information
  // from the link. The url_launcher package or other similar package
  // can be used to execute the link.
  Future<void> linkOnTapHandler(
    BuildContext context,
    String text,
    String? href,
    String title,
  ) async {
    unawaited(showDialog<Widget>(
      context: context,
      builder: (BuildContext context) =>
          _createDialog(context, text, href, title),
    ));
  }

  Widget _createDialog(
          BuildContext context, String text, String? href, String title) =>
      AlertDialog(
        title: const Text('Reference Link'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'See the following link for more information:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Link text: $text',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Link destination: $href',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Link title: $title',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      );
}

// ignore: must_be_immutable
class TextEditor extends StatefulWidget {
  String text;
  final void Function(String) onChange;
  TextEditingController controller;

  TextEditor(
      {super.key,
      this.text = '',
      required this.controller,
      required this.onChange});

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18.0),
      child: TextField(
          controller: widget.controller,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          autocorrect: true,
          decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Your next great project starts here...")),
    );
  }
}

// ignore: must_be_immutable
class PreviewSelect extends StatefulWidget {
  final void Function(TextEditMode) onSelectionChange;
  TextEditMode selected;

  PreviewSelect(
      {super.key,
      this.selected = TextEditMode.edit,
      required this.onSelectionChange});

  @override
  State<PreviewSelect> createState() => _PreviewSelectState();
}

class _PreviewSelectState extends State<PreviewSelect> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<TextEditMode>(
        segments: const <ButtonSegment<TextEditMode>>[
          ButtonSegment(
              value: TextEditMode.edit,
              label: Text("Edit"),
              icon: Icon(Icons.edit)),
          ButtonSegment(
              value: TextEditMode.preview,
              label: Text("Preview"),
              icon: Icon(Icons.preview)),
        ],
        selected: <TextEditMode>{widget.selected},
        onSelectionChanged: (Set<TextEditMode> newMode) {
          setState(() {
            widget.selected = newMode.first;
            widget.onSelectionChange(newMode.first);
          });
        },
      ),
    );
  }
}

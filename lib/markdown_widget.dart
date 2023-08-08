// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// ignore_for_file: public_member_api_docs

const String _notes = """
# Basic Markdown Demo
---
The Basic Markdown Demo shows the effect of the four Markdown extension sets
on formatting basic and extended Markdown tags.

## Overview

The Dart [markdown](https://pub.dev/packages/markdown) package parses Markdown
into HTML. The flutter_markdown package builds on this package using the
abstract syntax tree generated by the parser to make a tree of widgets instead
of HTML elements.

The markdown package supports the basic block and inline Markdown syntax
specified in the original Markdown implementation as well as a few Markdown
extensions. The markdown package uses extension sets to make extension
management easy. There are four pre-defined extension sets; none, Common Mark,
GitHub Flavored, and GitHub Web. The default extension set used by the
flutter_markdown package is GitHub Flavored.

The Basic Markdown Demo shows the effect each of the pre-defined extension sets
has on a test Markdown document with basic and extended Markdown tags. Use the
Extension Set dropdown menu to select an extension set and view the Markdown
widget's output.

## Comments

Since GitHub Flavored is the default extension set, it is the initial setting
for the formatted Markdown view in the demo.
""";

enum TextEditMode { edit, preview }

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
TextEditingController textController = TextEditingController();

// TODO(goderbauer): Restructure the examples to avoid this ignore, https://github.com/flutter/flutter/issues/110208.
// ignore: avoid_implementing_value_types
class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key});

  static const String _title = 'Basic Markdown Demo';

  String get title => MarkdownEditor._title;

  String get description => 'Shows the effect the four Markdown extension sets '
      'have on basic and extended Markdown tagged elements.';

  Future<String> get data => Future<String>.value('');

  Future<String> get notes => Future<String>.value(_notes);

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  TextEditMode currMode = TextEditMode.edit;
  String editorText = _notes;

  void setTextEditMode(TextEditMode newMode) {
    setState(() {
      editorText = textController.value.text;
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

  TextEditor({super.key, this.text = '', required this.onChange});

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.text);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: _formKey,
      controller: textController,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      autocorrect: true,
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
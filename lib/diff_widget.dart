import 'package:flutter/material.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';

enum DiffMode { original, diffs, edited }

// ignore: avoid_implementing_value_types, must_be_immutable
class DiffView extends StatefulWidget {
  String originalText;
  String editedText;

  DiffView({super.key, required this.originalText, required this.editedText});

  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  DiffMode currMode = DiffMode.diffs;

  void setDiffMode(DiffMode newMode) {
    setState(() {
      currMode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget pane;

    switch (currMode) {
      case DiffMode.original:
        pane = Text(widget.originalText,
            style: Theme.of(context).textTheme.bodyLarge!);
        break;
      case DiffMode.edited:
        pane = Text(widget.editedText,
            style: Theme.of(context).textTheme.bodyLarge!);
        break;
      case DiffMode.diffs:
        pane = PrettyDiffText(
          oldText: widget.originalText,
          newText: widget.editedText,
          defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
          addedTextStyle:
              const TextStyle(color: Colors.black, backgroundColor: Colors.green),
          deletedTextStyle:
              const TextStyle(color: Colors.black, backgroundColor: Colors.redAccent),
        );
        break;
      default:
        throw UnimplementedError('no widget for $currMode');
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DiffSelect(selected: currMode, onSelectionChange: setDiffMode),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(child: pane),
        )),
      ],
    );
  }
}

// ignore: must_be_immutable
class DiffSelect extends StatefulWidget {
  final void Function(DiffMode) onSelectionChange;
  DiffMode selected;

  DiffSelect(
      {super.key,
      this.selected = DiffMode.diffs,
      required this.onSelectionChange});

  @override
  State<DiffSelect> createState() => _DiffSelectState();
}

class _DiffSelectState extends State<DiffSelect> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<DiffMode>(
        segments: const <ButtonSegment<DiffMode>>[
          ButtonSegment(
              value: DiffMode.original,
              label: Text("Original"),
              icon: Icon(Icons.description)),
          ButtonSegment(
              value: DiffMode.diffs,
              label: Text("Edits"),
              icon: Icon(Icons.difference)),
          ButtonSegment(
              value: DiffMode.edited,
              label: Text("Edited"),
              icon: Icon(Icons.edit_document)),
        ],
        selected: <DiffMode>{widget.selected},
        onSelectionChanged: (Set<DiffMode> newMode) {
          setState(() {
            widget.selected = newMode.first;
            widget.onSelectionChange(newMode.first);
          });
        },
      ),
    );
  }
}

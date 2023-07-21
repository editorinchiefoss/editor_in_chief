import React, { useEffect } from 'react';
import { $getRoot, EditorState } from 'lexical';
import { LexicalComposer } from '@lexical/react/LexicalComposer';
import { PlainTextPlugin } from '@lexical/react/LexicalPlainTextPlugin';
import { ContentEditable } from '@lexical/react/LexicalContentEditable';
import { HistoryPlugin } from '@lexical/react/LexicalHistoryPlugin';
import { OnChangePlugin } from '@lexical/react/LexicalOnChangePlugin';
import { useLexicalComposerContext } from '@lexical/react/LexicalComposerContext';
import LexicalErrorBoundary from '@lexical/react/LexicalErrorBoundary';

// Plugin to autofocus editor
function MyCustomAutoFocusPlugin() {
  const [editor] = useLexicalComposerContext();

  useEffect(() => {
    editor.focus();
  }, [editor]);

  return null;
}

function onError(error: any) {
  console.error(error);
}

function Placeholder() {
  return (
    <div className="editor-placeholder">
      Your next great writing project awaits...
    </div>
  );
}

interface EditorProps {
  setEditorContent: React.Dispatch<React.SetStateAction<string>>;
}

export default function Editor({ setEditorContent }: EditorProps) {
  const initialConfig = {
    namespace: 'MyEditor',
    onError,
  };

  // When the editor changes, you can get notified via the
  // LexicalOnChangePlugin!
  const onChange = (editorState: EditorState) => {
    editorState.read(() => {
      // read the contents of EditorState here
      const root = $getRoot();
      // const selection = $getSelection();
      setEditorContent(root.getTextContent());
    });
  };

  return (
    <LexicalComposer initialConfig={initialConfig}>
      <PlainTextPlugin
        contentEditable={<ContentEditable />}
        placeholder={<Placeholder />}
        ErrorBoundary={LexicalErrorBoundary}
      />
      <OnChangePlugin onChange={onChange} />
      <HistoryPlugin />
      <MyCustomAutoFocusPlugin />
    </LexicalComposer>
  );
}

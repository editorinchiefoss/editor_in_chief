import React, { useState, useEffect } from 'react';
import {
  Container,
  Stack,
  Button,
  TextareaAutosize,
  Typography,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  IconButton,
  TextField,
} from '@mui/material';
import { Settings } from '@mui/icons-material';
import { encodingForModel } from 'js-tiktoken';
import { ChatOpenAI } from 'langchain/chat_models/openai';
import {
  ChatPromptTemplate,
  SystemMessagePromptTemplate,
  HumanMessagePromptTemplate,
} from 'langchain/prompts';
import { ConversationChain } from 'langchain/chains';

function App() {
  const [doc, setDoc] = useState('');
  const [paste, setPaste] = useState(false);
  const [pasteText, setPasteText] = useState('');
  const [loading, setLoading] = useState(false);
  const [articleEdited, setArticleEdited] = useState(false);
  const [showSettingsDialog, setShowSettingsDialog] = useState(false);
  const [openAIApiKey, setOpenAIApiKey] = useState(() => {
    return localStorage.getItem('openAIApiKey');
  });

  // Store OpenAI API Key to localStorage
  useEffect(() => {
    localStorage.setItem('openAIApiKey', openAIApiKey);
  }, [openAIApiKey]);


  const modelName = 'gpt-4';
  const enc = encodingForModel(modelName);
  const chunkTokenSize = 1000;

  const uploadFile = (e1: React.ChangeEvent<HTMLInputElement>) => {
    e1.preventDefault();
    const reader = new FileReader();
    reader.onload = (e2) => {
      // keep newlines in FF
      // https://stackoverflow.com/questions/18898036/how-to-keep-newline-characters-when-i-import-a-javascript-file-with-filereader
      const result = (e2.target?.result || '').toString();
      setDoc(result.replace(/\r/g, '\n'));
    };

    if (e1.target.files) {
      reader.readAsBinaryString(e1.target.files[0]);
    }
  };

  const startPaste = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setPaste(true);
  };

  const savePaste = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setDoc(pasteText);
    setPaste(false);
  };

  const updatePasteText = (e: {
    preventDefault: () => void;
    target: { value: React.SetStateAction<string> };
  }) => {
    e.preventDefault();
    setPasteText(e.target.value);
  };

  const clearDoc = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setDoc('');
    setArticleEdited(false);
  };

  const openSettingsDialog = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setShowSettingsDialog(true);
  };

  const handleSettingsClose = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setShowSettingsDialog(false);
  };

  const updateApiKey = (e: {
    preventDefault: () => void;
    target: { value: React.SetStateAction<string> };
  }) => {
    e.preventDefault();
    const newApiKey = e.target.value;
    setOpenAIApiKey(newApiKey);
  };

  const proofRead = async (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setLoading(true);

    // LangChain Setup
    const llm = new ChatOpenAI({
      modelName,
      openAIApiKey,
      temperature: 0,
    });
    const promptTemplate = ChatPromptTemplate.fromPromptMessages([
      SystemMessagePromptTemplate.fromTemplate(
        'You are an expert copy editor. It is your task to take a piece of an article and proof-read it for grammar and style. Provide a rewritten copy of the article portion back to the human.'
      ),
      HumanMessagePromptTemplate.fromTemplate('{input}'),
    ]);
    const chain = new ConversationChain({
      llm,
      prompt: promptTemplate,
    });

    // eslint-disable-next-line prefer-const
    let chunks: String[] = [];
    let currChunk = '';
    let currChunkNumTokens = 0;

    // Split the document into chunks of max token length chunk_token_size
    doc.split('\n').forEach((split, idx, source) => {
      const numNewTokens = enc.encode(split).length;

      // if adding the current chunk would spill over the limit,
      // add the existing chunk to chunks, else continue building chunks
      if (currChunkNumTokens + numNewTokens > chunkTokenSize) {
        chunks.push(currChunk);
        currChunk = split;
        currChunkNumTokens = numNewTokens;
      } else {
        currChunk += `${split}\n`;
        currChunkNumTokens += numNewTokens + 1;
      }

      // if last index, make sure to push current chunk to chunks
      if (idx === source.length - 1) {
        chunks.push(currChunk);
      }
    });

    // Proof-read each chunk and combined the proof-read pieces
    const openAICalls = chunks.map((chunk) => chain.call({ input: chunk }));
    const proofReadChunks = await Promise.all(openAICalls).finally(() => {
      setLoading(false);
      setArticleEdited(true);
    });

    const finalArticle = proofReadChunks
      .map((resp) => resp.response)
      .reduce((prev: string, curr: string) => `${prev}\n\n${curr}`);
    setDoc(finalArticle);
  };

  return (
    <Container sx={{ flexGrow: 1 }}>
      <div style={{ float: 'right' }}>
        <IconButton onClick={openSettingsDialog}>
          <Settings />
        </IconButton>
      </div>
      {!loading && (
        <>
          {!doc && !paste && (
            <Stack spacing={2} direction="row">
              <input
                accept="text/markdown"
                style={{ display: 'none' }}
                id="raised-button-file"
                type="file"
                onChange={uploadFile}
              />
              <Button component="span">Upload</Button>
              <Button onClick={startPaste}>Free Text</Button>
            </Stack>
          )}
          {!doc && paste && (
            <Stack spacing={2} direction="column">
              <TextareaAutosize
                onChange={updatePasteText}
                aria-label="Free Text"
                minRows={25}
                style={{ minWidth: '100%' }}
                placeholder="Input your article here..."
              />
              <Button onClick={savePaste}>Submit</Button>
            </Stack>
          )}
          {doc && (
            <>
              <pre>{doc}</pre>
              <Stack direction="row">
                {!articleEdited && (
                  <Button onClick={proofRead}>Proof-Read</Button>
                )}
                <Button onClick={clearDoc}>Clear</Button>
              </Stack>
            </>
          )}
        </>
      )}
      {loading && <Typography variant="h6">Loading ...</Typography>}
      <Dialog
        open={showSettingsDialog}
        onClose={handleSettingsClose}
        aria-labelledby="Settings Modal"
        aria-describedby="Where App-Wide Settings are configured"
      >
        <DialogTitle>Settings</DialogTitle>
        <DialogContent>
          <DialogContentText>
            In order to use this app, you need to set an OpenAI API Key.
          </DialogContentText>
          <TextField
            autoFocus
            onChange={updateApiKey}
            margin="dense"
            id="OpenAIApiKey"
            label="OpenAI API Key"
            type="password"
            fullWidth
            variant="standard"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleSettingsClose}>Cancel</Button>
          <Button onClick={handleSettingsClose}>Save</Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
}

export default App;

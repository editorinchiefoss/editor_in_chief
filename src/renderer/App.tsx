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
  Select,
  MenuItem,
  InputLabel,
  FormControl,
} from '@mui/material';
import { Settings } from '@mui/icons-material';
import { encodingForModel, TiktokenModel } from 'js-tiktoken';
import { ChatOpenAI } from 'langchain/chat_models/openai';
import {
  ChatPromptTemplate,
  SystemMessagePromptTemplate,
  HumanMessagePromptTemplate,
} from 'langchain/prompts';
import { ConversationChain } from 'langchain/chains';

import models, { OpenAIModel } from './models';
import DiffView from './DiffView';

function App() {
  const [doc, setDoc] = useState('');
  const [editedText, setEditedText] = useState('');
  const [paste, setPaste] = useState(false);
  const [pasteText, setPasteText] = useState('');
  const [loading, setLoading] = useState(false);
  const [showSettingsDialog, setShowSettingsDialog] = useState(false);
  const [openAIApiKey, setOpenAIApiKey] = useState(() => {
    return localStorage.getItem('openAIApiKey') || '';
  });
  const [modelName, setModelName] = useState(() => {
    return localStorage.getItem('openAIModel') || 'gpt-4';
  });

  // Store OpenAI API Key to localStorage
  useEffect(() => {
    localStorage.setItem('openAIApiKey', openAIApiKey);
  }, [openAIApiKey]);

  // Store OpenAI API Key to localStorage
  useEffect(() => {
    localStorage.setItem('openAIModel', modelName);
  }, [modelName]);

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

  const updateModelName = (e: {
    preventDefault: () => void;
    target: { value: React.SetStateAction<string> };
  }) => {
    e.preventDefault();
    setModelName(e.target.value);
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

    // model config
    const enc = encodingForModel(modelName as TiktokenModel);
    const chunkTokenSize = 500;

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
    });

    const finalArticle = proofReadChunks
      .map((resp) => resp.response)
      .reduce((prev: string, curr: string) => `${prev}\n\n${curr}`);
    setEditedText(finalArticle);
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
              <Button onClick={startPaste}>Input Text</Button>
            </Stack>
          )}
          {!doc && paste && (
            <Stack spacing={2} direction="column">
              <Button onClick={savePaste}>Submit</Button>
              <TextareaAutosize
                onChange={updatePasteText}
                aria-label="Free Text"
                minRows={25}
                style={{
                  minWidth: '100%',
                  minHeight: window.innerHeight - 80,
                  maxHeight: window.innerHeight - 80,
                  overflow: 'scroll',
                }}
                placeholder="Input your article here..."
              />
            </Stack>
          )}
          {doc && !editedText && (
            <>
              <Stack direction="row">
                <Button onClick={proofRead}>Proof-Read</Button>
                <Button onClick={clearDoc}>Clear</Button>
              </Stack>
              <pre>{doc}</pre>
            </>
          )}
          {doc && editedText && (
            <>
              <Stack direction="row">
                <Button onClick={proofRead}>Proof-Read</Button>
                <Button onClick={clearDoc}>Clear</Button>
              </Stack>
              <DiffView src={doc} target={editedText} />
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
        <DialogContent style={{ paddingTop: '.5em' }}>
          <FormControl fullWidth>
            <InputLabel id="model-select-label">OpenAI Model</InputLabel>
            <Select
              labelId="model-select-label"
              id="model-select"
              value={modelName}
              label="OpenAI Model"
              onChange={updateModelName}
            >
              {Object.values(models).map((m: OpenAIModel) => (
                <MenuItem value={m.id}>{m.name}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <DialogContentText>
            In order to use this app, you need to set an OpenAI API Key.
          </DialogContentText>
          <TextField
            autoFocus
            onChange={updateApiKey}
            defaultValue={openAIApiKey}
            margin="dense"
            id="OpenAIApiKey"
            label="OpenAI API Key"
            type="password"
            fullWidth
            variant="standard"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleSettingsClose}>Close</Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
}

export default App;

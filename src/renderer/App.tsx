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
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Slider,
  Alert,
  AlertTitle,
} from '@mui/material';
import { ExpandMore, Settings } from '@mui/icons-material';
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
import FirstRun from './FirstRun';
import Editor from './Editor';

const defaultPrompt =
  "You are an expert copy editor. It is your task to take a piece of an article and proof-read it for grammar and readability. Please preserve the author's voice when editing. Return the resulting text to the human.";
const defaultTemperature = 0.0;

function App() {
  const [originalText, setOriginalText] = useState('');
  const [editedText, setEditedText] = useState('');
  const [loading, setLoading] = useState(false);
  const [showSettingsDialog, setShowSettingsDialog] = useState(false);
  const [firstRun, setFirstRun] = useState(() => {
    return Boolean(JSON.parse(localStorage.getItem('firstRun') || 'true'));
  });
  const [openAIApiKey, setOpenAIApiKey] = useState(() => {
    return localStorage.getItem('openAIApiKey') || '';
  });
  const [modelName, setModelName] = useState(() => {
    return localStorage.getItem('openAIModel') || 'gpt-4';
  });
  const [systemPrompt, setSystemPrompt] = useState(() => {
    return localStorage.getItem('systemPrompt') || defaultPrompt;
  });
  const [temperature, setTemperature] = useState(() => {
    return JSON.parse(
      localStorage.getItem('temperature') || String(defaultTemperature)
    );
  });

  // Store First Run Key to localStorage
  useEffect(() => {
    localStorage.setItem('firstRun', JSON.stringify(firstRun));
  }, [firstRun]);

  // Store OpenAI API Key to localStorage
  useEffect(() => {
    localStorage.setItem('openAIApiKey', openAIApiKey);
  }, [openAIApiKey]);

  // Store Open AI Model Key to localStorage
  useEffect(() => {
    localStorage.setItem('openAIModel', modelName);
  }, [modelName]);

  // Store systemPrompt Key to localStorage
  useEffect(() => {
    // only write prompt if it isn't the default, prevents issues with changing the default
    // prompt in the future
    if (systemPrompt !== defaultPrompt) {
      localStorage.setItem('systemPrompt', systemPrompt);
    }
  }, [systemPrompt]);

  // Store Temperature Key to localStorage
  useEffect(() => {
    localStorage.setItem('temperature', JSON.stringify(temperature));
  }, [temperature]);

  const clearDoc = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setOriginalText('');
    setEditedText('');
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

  const updateTemperature = (
    e: { preventDefault: () => void },
    value: number | Array<number>
  ) => {
    e.preventDefault();
    setTemperature(
      Array.isArray(value) ? (value[0] as number) : (value as number)
    );
  };

  const updateSystemPrompt = (e: {
    preventDefault: () => void;
    target: { value: React.SetStateAction<string> };
  }) => {
    e.preventDefault();
    setSystemPrompt(e.target.value);
  };

  const resetDefaults = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setTemperature(0);
    setSystemPrompt(defaultPrompt);
  };

  const proofRead = async (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setLoading(true);

    // LangChain Setup
    const llm = new ChatOpenAI({
      modelName,
      openAIApiKey,
      temperature,
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
    originalText.split('\n').forEach((split, idx, source) => {
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
    <Container sx={{ flexGrow: 1, marginTop: '1em', marginBottom: '1em' }}>
      {firstRun && (
        <FirstRun setOpenAIApiKey={setOpenAIApiKey} setFirstRun={setFirstRun} />
      )}
      {!firstRun && (
        <div>
          {!openAIApiKey && (
            <Alert severity="warning">
              <AlertTitle>Missing OpenAI API Key</AlertTitle>
              You must set an OpenAI API Key before using this application. This
              must be set in the settings menu.
            </Alert>
          )}
          <div style={{ float: 'right' }}>
            <IconButton onClick={openSettingsDialog}>
              <Settings />
            </IconButton>
          </div>
          {!loading && (
            <>
              {!editedText && (
                <>
                  <Stack spacing={2} direction="row">
                    <Button onClick={proofRead}>Proof-Read</Button>
                  </Stack>
                  <Stack spacing={2} direction="column">
                    <Editor setEditorContent={setOriginalText} />
                  </Stack>
                </>
              )}
              {editedText && (
                <>
                  <Button onClick={clearDoc} style={{ float: 'left' }}>
                    Clear
                  </Button>
                  <DiffView src={originalText} target={editedText} />
                </>
              )}
            </>
          )}
          {loading && <Typography variant="h6">Loading ...</Typography>}
        </div>
      )}
      <Dialog
        open={showSettingsDialog}
        onClose={handleSettingsClose}
        aria-labelledby="Settings Modal"
        aria-describedby="Where App-Wide Settings are configured"
      >
        <DialogTitle>Settings</DialogTitle>
        <DialogContent>
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              General
            </AccordionSummary>
            <AccordionDetails>
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
                    <MenuItem value={m.id} key={m.id}>
                      {m.name}
                    </MenuItem>
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
            </AccordionDetails>
          </Accordion>
          <Accordion>
            <AccordionSummary expandIcon={<ExpandMore />}>
              Advanced
            </AccordionSummary>
            <AccordionDetails>
              <Typography id="input-temperature">Temperature</Typography>
              <Slider
                value={temperature}
                onChange={updateTemperature}
                getAriaValueText={() => `{temperature}`}
                min={0}
                max={1}
                step={0.1}
                aria-labelledby="input-temperture"
                valueLabelDisplay="auto"
              />
              <Typography id="input-system-prompt">System Prompt</Typography>
              <TextareaAutosize
                value={systemPrompt}
                onChange={updateSystemPrompt}
                aria-label="Free Text"
                minRows={5}
                maxRows={5}
                style={{
                  minWidth: '100%',
                  overflowX: 'scroll',
                }}
                placeholder="System prompt here..."
              />
              <Button onClick={resetDefaults}>Reset Defaults</Button>
            </AccordionDetails>
          </Accordion>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleSettingsClose}>Close</Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
}

export default App;

import React, { useState } from 'react';
import { Typography, TextField, Button, Container } from '@mui/material';

import logo from '../../assets/icons/256x256.png';

interface FirstRunProps {
  setOpenAIApiKey: React.Dispatch<React.SetStateAction<string>>;
  setFirstRun: React.Dispatch<React.SetStateAction<boolean>>;
}

export default function FirstRun({
  setOpenAIApiKey,
  setFirstRun,
}: FirstRunProps) {
  const [newApiKey, setNewApiKey] = useState('');

  const updateNewApiKey = (e: {
    preventDefault: () => void;
    target: { value: React.SetStateAction<string> };
  }) => {
    e.preventDefault();
    setNewApiKey(e.target.value);
  };

  const saveApiKey = (e: { preventDefault: () => void }) => {
    e.preventDefault();
    setOpenAIApiKey(newApiKey);
    setFirstRun(false);
  };

  return (
    <Container sx={{ marginLeft: 'auto', marginRight: 'auto' }}>
      <Typography variant="h4" align="center">
        Welcome to Editor in Chief!
      </Typography>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '2em 0 2em 0',
        }}
      >
        <img src={logo} alt="Editor in Chief Logo" />
      </div>
      <Container maxWidth="sm">
        <Typography variant="body1" gutterBottom>
          Editor in Chief if your personal copy-editor. Bring your original
          writing and get instant feedback.
        </Typography>
        <Typography variant="body1" gutterBottom>
          In order to use this app, you will need to provide your own OpenAI API
          key.
        </Typography>
        <TextField
          autoFocus
          onChange={updateNewApiKey}
          defaultValue={newApiKey}
          margin="dense"
          id="OpenAIApiKey"
          label="OpenAI API Key"
          type="password"
          fullWidth
          variant="standard"
        />
        <Button onClick={saveApiKey}>Save</Button>
      </Container>
    </Container>
  );
}

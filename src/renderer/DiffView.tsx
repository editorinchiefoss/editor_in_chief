import React, { JSX, useState } from 'react';
import { diffWordsWithSpace, Change } from 'diff';
import { ToggleButtonGroup, ToggleButton, Stack } from '@mui/material';

interface DiffViewProps {
  src: string;
  target: string;
}

function DiffView({ src, target }: DiffViewProps): JSX.Element {
  const [docVersion, setDocVersion] = useState('edits');

  const diff = diffWordsWithSpace(src, target);

  const changeToJSX = (change: Change): JSX.Element => {
    if (change.removed) {
      return change.value ? <del>{change.value}</del> : <span>&nbsp;</span>;
    }

    if (change.added) {
      return change.value ? <mark>{change.value}</mark> : <span>&nbsp;</span>;
    }

    return change.value ? <span>{change.value}</span> : <span>&nbsp;</span>;
  };

  const paragraphs: Array<Array<Change>> = [];
  let currParagraph: Array<Change> = [];
  diff.forEach((change: Change, idx: number) => {
    if (change.value.split('\n').length > 1) {
      // When at least one newline character is found, split the string and make a new paragraph for
      change.value
        .split('\n')
        .forEach((part: string, pIdx: number, splits: Array<string>) => {
          const newChange: Change = JSON.parse(JSON.stringify(change));
          newChange.value = part;
          currParagraph.push(newChange);

          // Don't make a new paragraph for the last split
          if (pIdx < splits.length - 1) {
            paragraphs.push(JSON.parse(JSON.stringify(currParagraph)));
            currParagraph = [];
          }
        });
    } else {
      currParagraph.push(change);
    }

    // If last change, do the necesary cleanup
    if (idx === diff.length - 1) {
      paragraphs.push(JSON.parse(JSON.stringify(currParagraph)));
    }
  });

  const updateDocVersion = (e: React.MouseEvent, newDocVersion: string) => {
    e.preventDefault();
    setDocVersion(newDocVersion);
  };

  return (
    <div>
      <Stack alignItems="center" style={{ marginBottom: '0.5em' }}>
        <ToggleButtonGroup
          value={docVersion}
          exclusive
          onChange={updateDocVersion}
          aria-label="toggle to select which document version to view"
        >
          <ToggleButton value="original" aria-label="Original Document">
            Original
          </ToggleButton>
          <ToggleButton value="edits" aria-label="Document Edits">
            Edits
          </ToggleButton>
          <ToggleButton value="edited" aria-label="Edited Document">
            Edited
          </ToggleButton>
        </ToggleButtonGroup>
      </Stack>
      {docVersion === 'original' &&
        src
          .split('\n')
          .map((curr) => (curr ? <div>{curr}</div> : <div>&nbsp;</div>))}
      {docVersion === 'edits' &&
        paragraphs.map((curr) => (
          <div>{curr.map((change: Change) => changeToJSX(change))}</div>
        ))}
      {docVersion === 'edited' &&
        target
          .split('\n')
          .map((curr) => (curr ? <div>{curr}</div> : <div>&nbsp;</div>))}
    </div>
  );
}

export default DiffView;

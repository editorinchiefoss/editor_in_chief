import { JSX } from 'react';
import { diffWordsWithSpace, Change } from 'diff';

interface DiffViewProps {
  src: string;
  target: string;
}

function DiffView({ src, target }: DiffViewProps): JSX.Element {
  const diff = diffWordsWithSpace(src, target);

  const changeToJSX = (change: Change): JSX.Element => {
    if (change.removed) {
      return change.value ? <del>{change.value}</del> : <del>&nbsp;</del>;
    }

    if (change.added) {
      return change.value ? <mark>{change.value}</mark> : <mark>&nbsp;</mark>;
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

  return (
    <div>
      {paragraphs.map((curr) => (
        <div>{curr.map((change: Change) => changeToJSX(change))}</div>
      ))}
    </div>
  );
}

export default DiffView;

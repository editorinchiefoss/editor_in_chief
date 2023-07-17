import { diffWordsWithSpace, Change } from 'diff';

interface DiffViewProps {
  src: string;
  target: String;
}

function DiffView({ src, target }: DiffViewProps) {
  const diff = diffWordsWithSpace(src, target) || [];
  return diff.map((change as Change) => {
    <div>
      {change.value &&
        <div>{change.value}</div>
      }
    </div>
  });
}

export default DiffView;

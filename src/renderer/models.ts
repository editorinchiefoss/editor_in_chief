export interface OpenAIModel {
  id: string;
  name: string;
  contextWindow: number;
}

export interface OpenAIModelMap {
  [key: string]: OpenAIModel;
}

const models: OpenAIModelMap = {
  'gpt-4-turbo-preview': { id: 'gpt-4-turbo-preview', name: 'GPT-4 Turbo', contextWindow: 128000 },
  'gpt-4': { id: 'gpt-4', name: 'GPT-4', contextWindow: 8000 },
  'gpt-3.5-turbo-16k': {
    id: 'gpt-3.5-turbo-16k',
    name: 'ChatGPT Long Context',
    contextWindow: 16000,
  },
};

export default models;

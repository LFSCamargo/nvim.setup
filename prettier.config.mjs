/** @type {import('prettier').Config} */
const config = {
  plugins: [
    'prettier-plugin-packagejson',
    'prettier-plugin-sh',
    'prettier-plugin-tailwindcss',
  ],
  tailwindStylesheet: './apps/web/src/styles.css',
  tailwindFunctions: ['cn'],
  semi: true,
  singleQuote: true,
  jsxSingleQuote: false,
  trailingComma: 'all',
  printWidth: 80,
  tabWidth: 2,
  useTabs: false,
  arrowParens: 'always',
  endOfLine: 'lf',
  bracketSpacing: true,
  bracketSameLine: false,
};

export default config;

import { Navigate, Route, Routes } from 'react-router-dom';
import { ThemeProvider } from '@/hooks/use-theme';
import { HomePage } from '@/pages/home-page';
import { DocsPage } from '@/pages/docs-page';

export default function App() {
  return (
    <ThemeProvider>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route
          path="/docs"
          element={<Navigate to="/docs/getting-started" replace />}
        />
        <Route path="/docs/:slug" element={<DocsPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </ThemeProvider>
  );
}

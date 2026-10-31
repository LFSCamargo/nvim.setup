import { Navigate, Route, Routes } from 'react-router-dom';
import { ThemeProvider } from '@/modules/theme/hooks/use-theme';
import { HomePage } from '@/modules/home/home-page';
import { DocsPage } from '@/modules/docs/docs-page';

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

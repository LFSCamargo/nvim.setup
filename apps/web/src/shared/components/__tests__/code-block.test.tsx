import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
} from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { CodeBlock } from '@/shared/components/code-block';

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

describe('CodeBlock', () => {
  it('renders line numbers and highlighted shell tokens', () => {
    render(
      <CodeBlock
        language="sh"
        filename="terminal"
        code={
          'curl -fsSL https://example.com/install.sh | bash\nNVIM_APPNAME=nvim-preview nvim .'
        }
      />,
    );
    const sample = screen.getByLabelText('terminal code sample');
    expect(sample.textContent).toContain('01');
    expect(sample.textContent).toContain('02');
    expect(sample.textContent).toContain('https://example.com/install.sh');
    expect(sample.textContent).toContain('NVIM_APPNAME=nvim-preview');
    expect(sample.className).toContain('whitespace-pre-wrap');
  });

  it('does not wrap ASCII diagrams', () => {
    render(
      <CodeBlock
        language="text"
        filename="layout"
        code={'┌────┐\n│ hi │\n└────┘'}
      />,
    );
    expect(screen.getByLabelText('layout code sample').className).toContain(
      'whitespace-pre',
    );
    expect(screen.getByLabelText('layout code sample').className).not.toContain(
      'whitespace-pre-wrap',
    );
  });

  it('copies the raw sample and falls back when the clipboard is denied', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText },
      configurable: true,
    });
    const { rerender } = render(
      <CodeBlock language="sh" code={'echo hello\n'} copyLabel="Copy code" />,
    );
    fireEvent.click(screen.getByRole('button', { name: 'Copy code' }));
    await waitFor(() => expect(writeText).toHaveBeenCalledWith('echo hello'));
    expect(await screen.findByText('Copied ✓')).toBeTruthy();

    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText: vi.fn().mockRejectedValue(new Error('denied')) },
      configurable: true,
    });
    rerender(
      <CodeBlock language="sh" code={'echo hello'} copyLabel="Copy code" />,
    );
    fireEvent.click(screen.getByRole('button', { name: 'Copy code' }));
    expect(await screen.findByText('Select and copy below')).toBeTruthy();
  });
});

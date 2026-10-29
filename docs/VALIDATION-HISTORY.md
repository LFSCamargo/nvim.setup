# Installation validation — 2026-10-29

- Neovim 0.12.6 installed through Homebrew; clean final configuration load.
- Lazy plugins installed and revisions recorded in lazy-lock.json.
- All 18 configured Mason tools installed.
- Syntax parsers installed for the configured languages.
- Real language-server initialization/attachment passed for TS, TSX/React, Vue (both servers), Svelte, Go, Rust, Solidity, TOML, JSON and YAML in disposable sample projects.
- TypeScript returned 52 member completion suggestions and diagnostics for an intentional type error.
- File tree opened with `nvim .`; FZF file picker, Trouble window, Git blame and JSON formatting passed.
- Both authenticated CLI terminal panes started, hid and reopened with the same buffers; no agent prompts were sent.
- Node, Go and Rust debug adapters each launched a disposable local program and stopped execution. Node adapter explicitly binds IPv4 to match its client.
- Mouse support enabled; physical mouse interaction and terminal Command key forwarding were not automated.
- Final headless startup measurement: approximately 37 ms on this machine (warm cache; interactive timing varies).

Browser attach, project-specific launch.json configurations, Vue 2, Bun inspector debugging and Solidity debugging were not validated. Bun editing uses TypeScript and project @types/bun; the supplied Node debug profiles target Node. See README.md for runtime/project requirements.

General checkhealth reports optional providers for Python/Ruby/Perl/Node remote plugins, image preview tools and unrelated Mason ecosystems if absent. This setup does not require those providers/tools. Lazy LuaRocks support is disabled because no configured plugin requires it.

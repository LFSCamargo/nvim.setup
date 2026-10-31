# Project structure

The editor and website both use feature folders. A module owns its UI, state, and feature-specific helpers. Shared code holds only helpers used by more than one module.

```text
nvim/
  init.lua                    options, Lazy bootstrap, module startup
  lua/modules/
    agents/init.lua           chat sessions
    diff/init.lua             editor diff view
    extensions/init.lua       plugin and Mason browser
    format/init.lua           formatter configuration
    images/init.lua           open image files in the system viewer
    sidebar/
      init.lua                public sidebar API and Git actions
      tree.lua                file tree options and highlights
      status.lua              asynchronous Git status parser
    plugins/{init,ui,tools}.lua
    shared/buffer.lua         read-only UI buffer updates

apps/web/src/
  main.tsx                    browser entry
  app/                        routing and app-level tests
  modules/
    home/                     landing sections, screenshots, install content
    docs/                     documentation reader and its content
    theme/                    theme state, switch, persistence
  shared/
    components/               navigation, footer, brand, reusable UI
    hooks/                    document meta and nav contrast
    utils/                    class names, highlight, SEO, SPA fallback
    constants/                site-wide URLs and metadata
```

Neovim entry points are `modules/<name>/init.lua`, imported as `require('modules.<name>')`. Put code used by only one feature beside that entry point. Plugin specs belong in `modules/plugins/`; Mason package and parser lists remain in `modules/tooling/`. Keep `nvim/init.lua` limited to startup wiring.

Website features live in `src/modules/<name>/`. Import across features through a specific file, and move a helper to `src/shared/` only when multiple features need it. Keep tests beside the code they cover. Route wiring stays in `src/app/`; `src/main.tsx` only mounts the app.

The `scripts/` directory owns installation and validation. It is outside the deployed `nvim/` tree. Documentation of module ownership stays in [PLUGINS.md](PLUGINS.md), and UI behavior stays in [EDITOR.md](EDITOR.md).

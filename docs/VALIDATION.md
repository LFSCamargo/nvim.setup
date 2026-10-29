# Packaging validation

Validated on macOS, 2026-10-29:

- Shell syntax checks and compilation of every Lua file passed.
- Prerequisite checks passed against Neovim 0.12.6, Node 24 and Tree-sitter CLI 0.27.1.
- Complete installation and repeat installation passed using temporary XDG config/state directories and existing Neovim data. The original configuration fixture was preserved in a timestamped backup.
- Plugin restore checked installed Git commits against the saved lockfile.
- All 18 Mason tools and 21 syntax parsers were present.
- Vimscript and Zsh syntax highlighters activated successfully.
- Gruvbox transparency and required keybindings passed validation.
- Configuration capture, semantic version input, dirty-update refusal and paths containing spaces passed workflow checks.

The active user configuration was not replaced during packaging tests. Linux package-manager branches are provided but were not executed on this macOS machine. A fresh-machine download of every native Mason package was not repeated; package availability depends on platform and upstream releases.

Run `make check`, `make doctor`, and `make validate` on the destination machine. Run `make e2e` to exercise the repository's chat and key configurations with a simulated Neovim UI and fake agent processes; it checks mouse focus, terminal input, and Escape delivery without launching the real CLIs. Earlier interactive editor checks are recorded separately in [the history](VALIDATION-HISTORY.md).

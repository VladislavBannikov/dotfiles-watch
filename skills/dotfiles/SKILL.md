---
name: dotfiles
description: Rules for editing config files tracked by chezmoi (~/.zshrc, ~/.claude/CLAUDE.md, ~/.claude/settings.json, ~/.codex/config.toml, ~/.codex/AGENTS.md, agterm configs and others). Use BEFORE changing any file in the home folder or ~/.config, when the user asks to add a config file to tracking, or asks about the dotfiles repo, chezmoi, or the SwiftBar dotfiles menu.
---

# Tracked config files (chezmoi)

The user's config files are tracked by chezmoi in a private repo
(`~/.local/share/chezmoi`).
A watcher shows every change in a SwiftBar menu bar icon. The USER reviews the diff
and approves (commits) or rejects each change. Agents do not commit.

## Before editing

Check if the file is tracked:

```sh
chezmoi managed --path-style absolute | grep -x /full/path/to/file
```

## Rules

1. Edit the real file (for example `~/.zshrc`), never the copy in `~/.local/share/chezmoi`.
2. Do NOT run `chezmoi re-add`, `chezmoi add`, `chezmoi apply`, `git commit` or `git push`
   for tracked files. The user does that from the menu bar.
   Exception: the user explicitly asks you to.
3. Never put secrets (passwords, tokens, keys) in a tracked file.
   Shell secrets go to `~/.zshrc.local` (stored encrypted, already sourced by `~/.zshrc`).
   A commit with a secret is blocked anyway, and the user has to clean it up.
4. Do not start tracking new files unless the user asks. To track one:
   `chezmoi add <file>` (or `chezmoi add --encrypt <file>` if it holds secrets).
5. In your final reply, list every tracked file you changed and why, in one line each, e.g.
   `Tracked config changed: ~/.zshrc (added codex_pers function), review it in the menu bar.`

## Useful read-only commands

- `chezmoi status`: tracked files that differ from the repo
- `chezmoi diff --reverse --no-pager <file>`: what changed locally
- `dotfiles list`: changed files, absolute paths

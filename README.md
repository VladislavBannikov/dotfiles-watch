# dotfiles-watch

A menu bar tool for macOS that watches config files tracked by [chezmoi](https://www.chezmoi.io).

Changes to tracked files are detected within seconds and shown in the menu bar.
You review each change and **approve** (commit) or **reject** (restore) it.
AI agents (Claude Code, Codex) may edit config files, but never commit them.

This repo holds only the tool. Your own config files stay in your own (private) chezmoi repo.

## How it works

```
 you / an AI agent edit ~/.zshrc
        │
        ▼
 launchd watcher (WatchPaths)  ──►  dotfiles check  ──►  banner "Changed: ~/.zshrc" (optional)
        │                                  │
        │                                  ▼
        │                           SwiftBar menu bar icon  ⚠ 1
        ▼
 click the icon:  Show diff (IntelliJ) · Approve (commit) · Reject (restore) · Push
```

| Part | Installed to | Job |
|---|---|---|
| `bin/dotfiles` | `~/.local/bin/dotfiles` | All logic: check, menu, diff, approve, reject, push, track |
| `swiftbar/dotfiles.5m.sh` | `~/.config/swiftbar/plugins/` | Runs `dotfiles menu` for [SwiftBar](https://github.com/swiftbar/SwiftBar); refreshes every 5 min as a backup |
| watcher (generated) | `~/Library/LaunchAgents/local.dotfiles-watch.plist` | macOS runs `dotfiles check` when a tracked file or its folder changes |
| `config/gitleaks.toml` | `~/.config/dotfiles-watch/gitleaks.toml` | [gitleaks](https://github.com/gitleaks/gitleaks) default rules + `NAME_WITH_PASS/TOKEN/SECRET/KEY=value` lines |
| `githooks/pre-commit` | `<chezmoi repo>/.githooks/` | Blocks any commit with a plain-text secret |
| `skills/dotfiles/SKILL.md` | `~/.claude/skills/`, `~/.codex/skills/` | Agent rules: edit the real file, don't commit, no secrets, report changed files |
| `bin/local-llm-up` | `~/.local/bin/` (optional) | Starts the LM Studio server at login for AI commit messages |

Settings: `~/.config/dotfiles-watch/settings` (`banners`, `ai`, `ai_model`, `approve_diff`, each `on|off` or a value).
State: `~/.cache/dotfiles-watch/` (change list, temporary diff copies deleted after 10 min, watcher log).

## Install

1. Install tools:
   ```sh
   brew install chezmoi gitleaks
   brew install --cask swiftbar
   ```
2. Set up chezmoi with your own private repo, if you don't have one yet:
   ```sh
   chezmoi init                 # creates ~/.local/share/chezmoi
   chezmoi add ~/.zshrc         # track your first file
   chezmoi cd                   # then: git remote add origin <your private repo>; git push -u origin main
   ```
3. Install this tool:
   ```sh
   git clone <this repo> && cd dotfiles-watch
   ./install.sh                 # or ./install.sh --llm for AI commit messages
   open -a SwiftBar
   ```
4. In SwiftBar Preferences turn on **Launch at Login**.
   Without it, after a restart the watcher still runs, but there is no icon and no Approve/Reject menu.
5. On the first banner, allow notifications for "Script Editor".
6. Optional: add a short note to `~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md`:
   "Before changing a file in the home folder, use the `dotfiles` skill."

After you track a new file by hand (`chezmoi add`), run `dotfiles install-watcher` so the watcher sees it.
**Track a new file…** in the menu does this for you.

## Menu bar icon

| Icon | Meaning |
|---|---|
| grey ✓ | All tracked files match the repo |
| orange ⚠ N | N tracked files changed locally |
| ↑ N | N commits waiting to be pushed |

Menu items:

- **Show diff**: IntelliJ diff, left = repo version, right = local file. Without IntelliJ a text diff opens.
- **Approve (commit)…**: checks for secrets, shows the diff, asks for a commit message, runs `chezmoi re-add` + `git commit`.
- **Reject (restore repo version)…**: asks first, then `chezmoi apply --force <file>`. The local change is lost.
- **Approve all…**: one commit for every changed file.
- **Commits waiting to push**: click a commit to see its patch; **Review all before push**; **Undo last commit…**
  (the files keep the change and show as changed again).
- **Push to GitHub**: `git push`. Nothing leaves the Mac without this click.
- **Open repo in IntelliJ** / **Open repo on GitHub**: the local chezmoi repo, or its GitHub page (from the `origin` remote).
- **Banners: ON/OFF**: one macOS notification when a file *first* changes.
- **AI commit messages: ON/OFF**: pre-fill the commit message with a local model.
- **Track a new file…**: pick a file, it is checked for secrets, added and committed.

## AI commit messages (optional)

- Uses any OpenAI-compatible server on `127.0.0.1:1234` (the [LM Studio](https://lmstudio.ai) default).
  `./install.sh --llm` adds a login agent that starts the server and loads the model.
- Default model: `google/gemma-4-e4b` (MLX, ~7 GB). Change it with `ai_model=<id>` in the settings file,
  and `FAST_MODEL` in `~/.local/bin/local-llm-up`.
- The diff (max 200 lines per file) is sent to localhost only. Encrypted files are never sent.
  If the server is down, the message falls back to `<file>: update`.
- Test: `dotfiles suggest ~/.zshrc`.

## Secrets

Secrets never go into a tracked file in plain text.

1. Create an age key: `chezmoi age-keygen -o ~/.config/chezmoi/key.txt && chmod 600 ~/.config/chezmoi/key.txt`
2. Put the public key into `~/.config/chezmoi/chezmoi.toml` (see `config/chezmoi.toml.example`).
3. Move shell secrets to `~/.zshrc.local` (mode 600), add `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local` to `~/.zshrc`.
4. Track it encrypted: `chezmoi add --encrypt ~/.zshrc.local`.
5. Back up `key.txt` somewhere safe outside the repo. Without it the encrypted files cannot be read.

Don't track files with tokens you can't move out: for example `.npmrc`, `.kube/config`, `.docker/config.json`,
`gh/hosts.yml`, `auth.json`. If you must, use `chezmoi add --encrypt`.

## Everyday commands

```sh
dotfiles list                       # changed tracked files
chezmoi diff --reverse --no-pager   # what changed locally
chezmoi re-add ~/.zshrc             # keep local change (then commit)
chezmoi apply --force ~/.zshrc      # throw away local change
chezmoi add ~/.config/foo.conf      # start tracking (then: dotfiles install-watcher)
chezmoi forget ~/.config/foo.conf   # stop tracking, file stays
chezmoi managed                     # list tracked files
```

Do not run `chezmoi apply` without a file name while there are local changes: it overwrites them.

## Troubleshooting

| Problem | Check |
|---|---|
| No menu bar icon after restart | SwiftBar **Launch at Login** is off. Start it now with `open -a SwiftBar` |
| No menu bar icon | SwiftBar running? Plugin folder = `~/.config/swiftbar/plugins`? `dotfiles menu` prints the menu? |
| Change not detected | `launchctl print gui/$(id -u)/local.dotfiles-watch`, `~/.cache/dotfiles-watch/watcher.log`. A newly tracked file needs `dotfiles install-watcher` |
| Show diff does nothing | IntelliJ launcher: `~/Library/Application Support/JetBrains/Toolbox/scripts/idea` (Toolbox → Settings → Shell scripts) |
| Approve says "Blocked" | The file looks like it holds a secret. Move it to `~/.zshrc.local`. False alarm: adjust `gitleaks.toml` |
| Commit fails in the terminal | The pre-commit hook found a secret; run the gitleaks command from `.githooks/pre-commit` to see it |
| Menu broken after editing the script | It runs under macOS `/bin/bash` 3.2. Check with `/bin/bash -n ~/.local/bin/dotfiles` |

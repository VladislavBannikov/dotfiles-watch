#!/bin/bash
# Install dotfiles-watch: copy the tools into place, turn on the pre-commit hook,
# start the watcher and point SwiftBar at the plugin folder.
# Run after `chezmoi init` (your chezmoi repo must exist). Safe to run again.
#
#   ./install.sh            install the review tool
#   ./install.sh --llm      also start LM Studio at login (for AI commit messages)

set -e
cd "$(dirname "$0")"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

for cmd in chezmoi gitleaks git; do
  command -v "$cmd" >/dev/null || { echo "missing: $cmd (brew install $cmd)" >&2; exit 1; }
done
SRC_DIR="$(chezmoi source-path)" || { echo "run 'chezmoi init' first" >&2; exit 1; }

install -d -m 755 ~/.local/bin ~/.config/swiftbar/plugins ~/.claude/skills/dotfiles ~/.codex/skills/dotfiles
install -d -m 700 ~/.config/dotfiles-watch
install -m 755 bin/dotfiles ~/.local/bin/dotfiles
install -m 755 swiftbar/dotfiles.5m.sh ~/.config/swiftbar/plugins/dotfiles.5m.sh
[ -f ~/.config/dotfiles-watch/gitleaks.toml ] || install -m 644 config/gitleaks.toml ~/.config/dotfiles-watch/gitleaks.toml
install -m 644 skills/dotfiles/SKILL.md ~/.claude/skills/dotfiles/SKILL.md
install -m 644 skills/dotfiles/SKILL.md ~/.codex/skills/dotfiles/SKILL.md

# pre-commit hook in the chezmoi repo
install -d "$SRC_DIR/.githooks"
install -m 755 githooks/pre-commit "$SRC_DIR/.githooks/pre-commit"
git -C "$SRC_DIR" config core.hooksPath .githooks

~/.local/bin/dotfiles install-watcher
defaults write com.ameba.SwiftBar PluginDirectory -string "$HOME/.config/swiftbar/plugins"

if [ "$1" = "--llm" ]; then
  install -m 755 bin/local-llm-up ~/.local/bin/local-llm-up
  mkdir -p ~/.cache/local-llm ~/Library/LaunchAgents
  cat > ~/Library/LaunchAgents/local.llm-server.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>local.llm-server</string>
  <key>ProgramArguments</key>
  <array>
    <string>$HOME/.local/bin/local-llm-up</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$HOME/.cache/local-llm/server.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/.cache/local-llm/server.log</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)/local.llm-server" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/local.llm-server.plist
fi

echo "Done. Now: open -a SwiftBar, and turn on Launch at Login in SwiftBar Preferences."

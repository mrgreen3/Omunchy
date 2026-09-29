---
name: claude-code-setup
description: Install Anthropic's Claude Code CLI ("claude") into the user's home directory with Anthropic's own installer. Use when the user asks to set up, install, or update Claude Code. No root, no Node, nothing outside ~/.local.
---

# claude-code-setup

Claude Code is not in the Arch repos. Install it with Anthropic's native
installer, which needs no Node and no sudo and lives entirely under `~/.local`.
Docs: https://code.claude.com/docs/en/setup

## 1. Check the ground

- Confirm network: `curl -fsS --max-time 6 -o /dev/null https://claude.ai`.
- Existing install: `command -v claude && claude --version`. If it works and
  the user only wants an update, jump to "Update".
- On the live ISO, say the install is lost on reboot unless the system is
  installed to disk.

## 2. Install

    curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh
    bash /tmp/claude-install.sh

It puts a launcher at `~/.local/bin/claude` pointing into
`~/.local/share/claude/versions/`. Remove with `rm ~/.local/bin/claude` and
`rm -r ~/.local/share/claude`.

## PATH

`~/.local/bin` must be on PATH. Check:

    case ":$PATH:" in *":$HOME/.local/bin:"*) echo ok;; *) echo missing;; esac

If missing, add `export PATH="$HOME/.local/bin:$PATH"` to `~/.bashrc` after a
yes. It applies to new terminals; until then call `~/.local/bin/claude`.

## Verify

Run `claude --version` and report the exact output.

## First run and auth

The user runs `claude` themselves and logs in with `/login` (subscription or
API key). Never ask for the key in chat and never paste it for them.

## Update

`claude update`, then `claude --version`.

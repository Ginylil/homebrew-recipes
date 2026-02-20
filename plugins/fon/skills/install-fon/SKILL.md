---
name: install-fon
description: Install fon (fifth-of-november) via Homebrew and add it to the user's IDE. Use when the user wants to install fon or when fon commands are missing.
---

# Install fon

## When to use

- User asks to install fon or the “terminal learning agent”
- Commands like `fon check` or `fon web` are not found
- User is onboarding to a repo that uses fon

## Instructions

1. **Install fon** (recommended method):
   ```bash
   brew install ginylil/recipes/fon
   ```
   If the user doesn’t use Homebrew, suggest the official installer:  
   `curl -sSL https://fon.ginylil.com/fon_install.py | python3 -`

2. **Add fon to the IDE** (Cursor, Kiro, Windsurf, etc.):
   ```bash
   fon add-to-ide
   ```
   If install failed the IDE step (e.g. no network), they can run later:
   ```bash
   curl -sSL https://fon.ginylil.com/fon_install.py | python3 - --ide-only
   ```

3. Tell the user to **reload MCP** in Cursor (and restart the terminal if needed), then they can run in chat: **`fon web`** or **`fon check`**.

Do not edit Homebrew formula files to “install” fon; the formula is in this tap and is updated via CI. Recommend `brew install ginylil/recipes/fon` as the user-facing install.

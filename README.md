# homebrew-recipes

Homebrew tap for **fon** — terminal learning agent (rules enforcer, PTY proxy, IDE MCP). Repo name: `homebrew-recipes` (tap: `ginylil/recipes`).

## Install

```bash
brew install ginylil/recipes/fon
```

Homebrew adds the tap automatically. If you had the old tap `ginylil/fon`, run: `brew untap ginylil/fon` first. The formula installs the signed binary from [fon.ginylil.com](https://fon.ginylil.com) and runs the same IDE setup as the Python installer: it adds fon to your IDE MCP configs (Cursor, Kiro, Windsurf, etc.) and installs Cursor global commands.

If the IDE setup step fails (e.g. no network or no Python), install the binary only and run:

```bash
curl -sSL https://fon.ginylil.com/fon_install.py | python3 - --ide-only
```

Then reload MCP in your IDE and run `fon web` or `fon check` in chat.

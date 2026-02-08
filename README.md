# homebrew-fon

Homebrew tap for **fon** — terminal learning agent (rules enforcer, PTY proxy, IDE MCP).

## Install

```bash
brew install ginylil/fon
```

Homebrew adds this tap automatically. The formula installs the signed binary from [fon.ginylil.com](https://fon.ginylil.com) and runs the same IDE setup as the Python installer: it adds fon to your IDE MCP configs (Cursor, Kiro, Windsurf, etc.) and installs Cursor global commands.

If the IDE setup step fails (e.g. no network or no Python), install the binary only and run:

```bash
curl -sSL https://fon.ginylil.com/fon_install.py | python3 - --ide-only
```

Then reload MCP in your IDE and run `fon web` or `fon check` in chat.

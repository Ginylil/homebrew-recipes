# homebrew-recipes

Homebrew tap for **fon** — terminal learning agent (rules enforcer, PTY proxy, IDE MCP). Repo name: `homebrew-recipes` (tap: `ginylil/recipes`).

## Install

```bash
brew install ginylil/recipes/fon
```

Homebrew adds the tap automatically. If you had the old tap `ginylil/fon`, run: `brew untap ginylil/fon` first. The formula installs the signed binary from [fon.ginylil.com](https://fon.ginylil.com). It does not mutate IDE config during `brew install`.

After install, use the browser-first onboarding flow:

```bash
fon web --open
```

Terminal alternative:

```bash
fon add-to-ide --list
fon add-to-ide --enable cursor
```

Then reload MCP in your IDE and run `fon web` or `fon check` in chat.

**Formula updates:** The formula pins a specific fon version (same idea as `make download-web-latest VERSION=x.y.z`). To set or bump it: **Actions → Update fon formula → Run workflow**, enter the version (e.g. `1.0.2`). That version must be deployed so that `fon.ginylil.com/releases/{version}/version` exists. Do not edit version or sha256 in the formula by hand.

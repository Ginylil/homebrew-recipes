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

**Formula updates:** Use the local maintenance entrypoints instead of editing workflow YAML or `fon_versions.yaml` by hand.

```bash
make verify-release VERSION=0.0.26
make update-formula VERSION=0.0.26
make test
```

The GitHub Actions workflow uses the same `Makefile` and `scripts/` entrypoints. A stable release is only allowed through when both `fon.ginylil.com/releases/{version}/version` and `fon.ginylil.com/releases/version` match the target version.

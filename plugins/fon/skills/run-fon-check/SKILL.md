---
name: run-fon-check
description: Run fon code-quality checks. Use when the user or repo uses fon and you need to validate code quality or regenerate IDE rules.
---

# Run fon check

## When to use

- Repo uses fon and you’ve made code or config changes that should pass checks
- User asks to “run fon check” or “run checks”
- Regenerating Cursor rules from fon (e.g. in fifth-of-november: `fon check --docs cursor`)

## Instructions

1. **Ensure fon is installed.** If not, recommend:
   ```bash
   brew install ginylil/recipes/fon
   fon add-to-ide
   ```
   Then reload MCP.

2. **Run checks:**
   ```bash
   fon check
   ```
   Fix any reported issues; treat `fon check` as part of the definition of done for this repo.

3. **Regenerate IDE rules** (only in the fifth-of-november repo or when the user needs updated Cursor rules from fon):
   ```bash
   fon check --docs cursor
   ```
   This writes `.cursor/rules/` from code and YAML; don’t duplicate that content elsewhere.

Use the project’s Makefile when present (e.g. `make check` in fifth-of-november), which typically runs `fon check` or equivalent.

#!/usr/bin/env python3
"""Verify published fon release metadata before updating the Homebrew tap."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.release_tools import RELEASES_BASE_DEFAULT, ReleaseError, validate_release


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments."""
    parser = argparse.ArgumentParser(
        description="Verify one published fon release and optionally write metadata JSON.",
    )
    parser.add_argument("--version", required=True, help="Release version, for example 0.0.26.")
    parser.add_argument(
        "--sha256",
        default="",
        help="Optional override SHA-256 for releases/<version>/version.",
    )
    parser.add_argument(
        "--base-url",
        default=RELEASES_BASE_DEFAULT,
        help="Base releases URL.",
    )
    parser.add_argument(
        "--allow-latest-drift",
        action="store_true",
        help="Allow releases/version to differ from the pinned release version.",
    )
    parser.add_argument(
        "--output-json",
        default="",
        help="Optional path to write verification metadata as JSON.",
    )
    return parser.parse_args()


def main() -> int:
    """Run release verification."""
    args = parse_args()
    try:
        result = validate_release(
            version=args.version,
            sha256_override=args.sha256 or None,
            require_latest_match=not args.allow_latest_drift,
            base_url=args.base_url,
        )
    except ReleaseError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    print(f"Verified release {result['version']}")
    print(f"  pinned: {result['pinned_url']}")
    print(f"  latest: {result['latest_url']} -> {result['latest_version']}")
    print(f"  sha256: {result['sha256']}")
    if args.output_json:
        path = Path(args.output_json)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(f"  wrote: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Update Formula/fon_versions.yaml from verified release metadata."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.release_tools import ReleaseError, normalize_sha256, update_versions_file


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments."""
    parser = argparse.ArgumentParser(
        description="Update Formula/fon_versions.yaml for one verified release.",
    )
    parser.add_argument("--version", required=True, help="Release version, for example 0.0.26.")
    parser.add_argument(
        "--metadata-json",
        default="",
        help="Path to metadata JSON written by scripts/verify_release.py.",
    )
    parser.add_argument(
        "--sha256",
        default="",
        help="Explicit SHA-256 override. Use only if metadata JSON is not provided.",
    )
    parser.add_argument(
        "--versions-file",
        default="Formula/fon_versions.yaml",
        help="Path to the tap version table.",
    )
    return parser.parse_args()


def resolve_sha256(args: argparse.Namespace) -> str:
    """Resolve the SHA-256 from metadata JSON or explicit CLI input."""
    if args.metadata_json:
        data = json.loads(Path(args.metadata_json).read_text(encoding="utf-8"))
        file_version = str(data.get("version", "")).strip()
        sha256_value = str(data.get("sha256", "")).strip()
        if file_version != args.version:
            raise ReleaseError(
                f"Metadata version mismatch: expected {args.version}, got {file_version or '<empty>'}."
            )
        return normalize_sha256(sha256_value)
    if args.sha256:
        return normalize_sha256(args.sha256)
    raise ReleaseError("Provide --metadata-json or --sha256.")


def main() -> int:
    """Update the tap version table."""
    args = parse_args()
    try:
        sha256_value = resolve_sha256(args)
        versions_path = Path(args.versions_file)
        latest, _ = update_versions_file(
            versions_path,
            version=args.version,
            sha256_value=sha256_value,
        )
    except (ReleaseError, json.JSONDecodeError, OSError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    print(f"Updated {args.versions_file}")
    print(f"  latest: {latest}")
    print(f"  sha256: {sha256_value}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

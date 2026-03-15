"""Tests for tap release maintenance helpers."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from scripts.release_tools import ReleaseError, load_versions_file, update_versions_file, validate_release
from scripts import release_tools


class ReleaseToolsTest(unittest.TestCase):
    """Coverage for release validation and version-table updates."""

    def test_load_and_update_versions_file(self) -> None:
        """The version table should parse and rewrite in a stable format."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "fon_versions.yaml"
            path.write_text(
                "---\nlatest: 0.0.22\nversions:\n  0.0.21: aaaa\n  0.0.22: bbbb\n",
                encoding="utf-8",
            )
            latest, versions = load_versions_file(path)
            self.assertEqual(latest, "0.0.22")
            self.assertEqual(versions["0.0.21"], "aaaa")

            update_versions_file(
                path,
                version="0.0.26",
                sha256_value="c" * 64,
            )
            rewritten = path.read_text(encoding="utf-8")
            self.assertIn("latest: 0.0.26", rewritten)
            self.assertIn("  0.0.26: " + ("c" * 64), rewritten)

    def test_validate_release_rejects_latest_drift(self) -> None:
        """Stable release validation should fail when latest metadata still lags."""
        original_fetch = release_tools.fetch_json_bytes

        def fake_fetch(url: str) -> tuple[bytes, str]:
            if url.endswith("/0.0.26/version"):
                payload = {"version": "0.0.26"}
            else:
                payload = {"version": "0.0.23"}
            return json.dumps(payload).encode("utf-8"), "application/json"

        release_tools.fetch_json_bytes = fake_fetch
        try:
            with self.assertRaises(ReleaseError):
                validate_release(version="0.0.26")
        finally:
            release_tools.fetch_json_bytes = original_fetch

    def test_validate_release_accepts_matching_metadata(self) -> None:
        """Release validation should return the computed SHA-256 when metadata matches."""
        original_fetch = release_tools.fetch_json_bytes

        def fake_fetch(url: str) -> tuple[bytes, str]:
            payload = {"version": "0.0.26"}
            raw = json.dumps(payload).encode("utf-8")
            return raw, "application/json; charset=utf-8"

        release_tools.fetch_json_bytes = fake_fetch
        try:
            result = validate_release(version="0.0.26")
        finally:
            release_tools.fetch_json_bytes = original_fetch

        self.assertEqual(result["version"], "0.0.26")
        self.assertEqual(result["latest_version"], "0.0.26")
        self.assertEqual(len(result["sha256"]), 64)


if __name__ == "__main__":
    unittest.main()

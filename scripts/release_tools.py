"""Utilities for validating published fon releases and updating tap metadata."""

from __future__ import annotations

import hashlib
import json
import re
import urllib.error
import urllib.request
from pathlib import Path

RELEASES_BASE_DEFAULT = "https://fon.ginylil.com/releases"
CONTENT_TYPE_JSON = "application/json"
SHA256_RE = re.compile(r"^[a-f0-9]{64}$")


class ReleaseError(RuntimeError):
    """Raised when published release metadata is invalid."""


def normalize_sha256(value: str) -> str:
    """Normalize and validate an optional SHA-256 string."""
    cleaned = value.strip().lower()
    if not SHA256_RE.fullmatch(cleaned):
        raise ReleaseError("SHA-256 must be exactly 64 lowercase hex characters.")
    return cleaned


def fetch_json_bytes(url: str) -> tuple[bytes, str]:
    """Fetch one JSON endpoint and return raw bytes plus content type."""
    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            content_type = response.headers.get("Content-Type", "")
            status = getattr(response, "status", 200)
            payload = response.read()
    except urllib.error.HTTPError as exc:
        raise ReleaseError(f"Expected HTTP 200 from {url}, got {exc.code}.") from exc
    except urllib.error.URLError as exc:
        raise ReleaseError(f"GET {url} failed: {exc.reason}.") from exc
    if status != 200:
        raise ReleaseError(f"Expected HTTP 200 from {url}, got {status}.")
    if not content_type.lower().startswith(CONTENT_TYPE_JSON):
        preview = payload[:200].decode("utf-8", errors="replace")
        raise ReleaseError(
            f"Expected application/json from {url}, got {content_type or '<empty>'}. First bytes: {preview}"
        )
    return payload, content_type


def parse_json(payload: bytes, url: str) -> dict:
    """Parse one JSON response as an object."""
    try:
        data = json.loads(payload.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise ReleaseError(f"Invalid JSON at {url}: {exc}.") from exc
    if not isinstance(data, dict):
        raise ReleaseError(f"Expected JSON object at {url}.")
    return data


def compute_sha256(payload: bytes) -> str:
    """Return SHA-256 for raw bytes."""
    return hashlib.sha256(payload).hexdigest()


def semver_key(version: str) -> tuple[int, ...]:
    """Sort versions numerically by dot-separated components."""
    parts = []
    for piece in version.split("."):
        if piece.isdigit():
            parts.append(int(piece))
        else:
            parts.append(-1)
    return tuple(parts)


def validate_release(
    *,
    version: str,
    sha256_override: str | None = None,
    require_latest_match: bool = True,
    base_url: str = RELEASES_BASE_DEFAULT,
) -> dict:
    """Validate pinned and latest release metadata for one version."""
    pinned_url = f"{base_url.rstrip('/')}/{version}/version"
    latest_url = f"{base_url.rstrip('/')}/version"

    pinned_payload, _ = fetch_json_bytes(pinned_url)
    pinned = parse_json(pinned_payload, pinned_url)
    pinned_version = str(pinned.get("version", "")).strip()
    if pinned_version != version:
        raise ReleaseError(
            f"Version mismatch at {pinned_url}: expected {version}, got {pinned_version or '<empty>'}."
        )

    latest_payload, _ = fetch_json_bytes(latest_url)
    latest = parse_json(latest_payload, latest_url)
    latest_version = str(latest.get("version", "")).strip()
    if require_latest_match and latest_version != version:
        raise ReleaseError(
            f"Version mismatch at {latest_url}: expected {version}, got {latest_version or '<empty>'}."
        )

    sha256_value = (
        normalize_sha256(sha256_override)
        if sha256_override is not None and sha256_override.strip()
        else compute_sha256(pinned_payload)
    )
    return {
        "version": version,
        "sha256": sha256_value,
        "pinned_url": pinned_url,
        "latest_url": latest_url,
        "latest_version": latest_version,
    }


def load_versions_file(path: Path) -> tuple[str, dict[str, str]]:
    """Parse Formula/fon_versions.yaml without external YAML dependencies."""
    latest = ""
    versions: dict[str, str] = {}
    in_versions = False
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        if not line or line == "---":
            continue
        if line.startswith("latest:"):
            latest = line.split(":", 1)[1].strip()
            continue
        if line == "versions:":
            in_versions = True
            continue
        if in_versions and line.startswith("  "):
            key, value = line.strip().split(":", 1)
            versions[key.strip()] = value.strip()
    if not latest:
        raise ReleaseError(f"Could not parse latest version from {path}.")
    return latest, versions


def write_versions_file(path: Path, latest: str, versions: dict[str, str]) -> None:
    """Write Formula/fon_versions.yaml in a stable format."""
    ordered_versions = sorted(versions.items(), key=lambda item: semver_key(item[0]))
    lines = ["---", f"latest: {latest}", "versions:"]
    lines.extend(f"  {version}: {sha}" for version, sha in ordered_versions)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def update_versions_file(path: Path, *, version: str, sha256_value: str) -> tuple[str, dict[str, str]]:
    """Update one version entry and latest pointer, then write the file."""
    _, versions = load_versions_file(path)
    versions[version] = normalize_sha256(sha256_value)
    write_versions_file(path, latest=version, versions=versions)
    return version, versions

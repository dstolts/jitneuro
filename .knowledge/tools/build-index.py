# Vendored from dstolts/jit-knowledge skills/knowledge-index @ 7350473 -- refresh via rollout PRs, do not hand-edit.
#!/usr/bin/env python3
"""Scaffold and maintain a .knowledge/index.md routing index.

Portable, stdlib-first generator. PyYAML is used when available; falls back
to a minimal flat-frontmatter parser for the fields this script needs.

Usage:
  python build-index.py [--dir DIR] [--init [--title NAME] [--date YYYY-MM-DD]]
  python build-index.py [--dir DIR] [--refresh]     # default action
  python build-index.py [--dir DIR] [--check]       # CI: exit 1 if stale

Marker convention (matches scripts/rebuild-manifest.py):
  <!-- ARTIFACT-MANIFEST-AUTO-START -->
  <!-- ARTIFACT-MANIFEST-AUTO-END -->

Entry format:
  - <relpath> * <type> * <tags-csv> * <purpose-one-line> * scope:<scope>
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Marker constants (must match the template and the portfolio-level script)
# ---------------------------------------------------------------------------
START_MARKER = "<!-- ARTIFACT-MANIFEST-AUTO-START -->"
END_MARKER = "<!-- ARTIFACT-MANIFEST-AUTO-END -->"

EXCLUDE_DIRS = {".archive", ".git", "node_modules", "__fixtures__", "archive"}
TEMPLATE_NAME = "index-template.md"
INDEX_NAME = "index.md"

# ---------------------------------------------------------------------------
# YAML / frontmatter parsing
# ---------------------------------------------------------------------------
try:
    import yaml as _yaml  # type: ignore

    def _parse_yaml(text: str) -> dict:
        try:
            parsed = _yaml.safe_load(text) or {}
            return parsed if isinstance(parsed, dict) else {}
        except Exception:
            return {}

except ImportError:
    _yaml = None  # type: ignore

    def _parse_yaml(text: str) -> dict:  # type: ignore[no-redef]
        """Minimal flat-frontmatter parser for the fields we need."""
        result: dict = {}
        for line in text.splitlines():
            line = line.rstrip()
            if not line or line.startswith("#"):
                continue
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)', line)
            if not m:
                continue
            key, val = m.group(1), m.group(2).strip()
            # Handle inline list: [a, b, c]
            if val.startswith("[") and val.endswith("]"):
                inner = val[1:-1]
                result[key] = [v.strip().strip('"').strip("'") for v in inner.split(",") if v.strip()]
            else:
                result[key] = val
        return result


def load_frontmatter(path: Path) -> tuple[dict, str]:
    """Return (frontmatter_dict, body). Empty dict if no frontmatter."""
    try:
        text = path.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeDecodeError):
        return {}, ""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    fm_raw = text[3:end].lstrip("\n")
    body = text[end + 4:].lstrip("\n")
    return _parse_yaml(fm_raw), body


def _str(val) -> str:
    if val is None:
        return ""
    return str(val).strip()


def extract_field(fm: dict, *keys: str) -> str:
    for k in keys:
        v = fm.get(k)
        if v is not None:
            return _str(v)
    return ""


def extract_tags(fm: dict) -> str:
    raw = fm.get("tags")
    if isinstance(raw, list):
        return ",".join(_str(t) for t in raw if t)
    if raw:
        return _str(raw)
    return ""


def first_paragraph(body: str) -> str:
    lines: list[str] = []
    in_para = False
    for line in body.splitlines():
        s = line.strip()
        if not s:
            if in_para:
                break
            continue
        if s.startswith("#"):
            continue
        lines.append(s)
        in_para = True
    text = " ".join(lines)
    return text[:140] + ("..." if len(text) > 140 else "")


# ---------------------------------------------------------------------------
# File walking
# ---------------------------------------------------------------------------
def walk_md(base: Path, index_path: Path) -> list[Path]:
    result: list[Path] = []
    for path in sorted(base.rglob("*.md"), key=lambda p: p.relative_to(base).as_posix().lower()):
        if path == index_path:
            continue
        rel_parts = path.relative_to(base).parts
        if any(part in EXCLUDE_DIRS for part in rel_parts):
            continue
        result.append(path)
    return result


# ---------------------------------------------------------------------------
# Manifest building
# ---------------------------------------------------------------------------
def render_entry(path: Path, base: Path) -> str:
    fm, body = load_frontmatter(path)
    rel = path.relative_to(base).as_posix()
    ftype = extract_field(fm, "type") or "doc"
    tags = extract_tags(fm) or ftype
    purpose = extract_field(fm, "purpose", "description")
    if not purpose:
        # Try first paragraph of body
        purpose = first_paragraph(body) or "(no description)"
    # Truncate and flatten
    purpose = purpose.replace("\n", " ").replace("*", "\\*")
    if len(purpose) > 140:
        purpose = purpose[:137] + "..."
    scope = extract_field(fm, "scope") or "internal"
    if not scope.startswith("scope:"):
        scope = f"scope:{scope}"
    return f"- {rel} * {ftype} * {tags} * {purpose} * {scope}"


def build_manifest(base: Path, index_path: Path) -> str:
    files = walk_md(base, index_path)
    sections: dict[str, list[str]] = {}
    section_order: list[str] = []

    for path in files:
        rel_parts = path.relative_to(base).parts
        section = rel_parts[0] if len(rel_parts) > 1 else "."
        if section not in sections:
            sections[section] = []
            section_order.append(section)
        sections[section].append(render_entry(path, base))

    lines: list[str] = [
        "Machine-generated by build-index.py. Do not edit by hand between the AUTO markers.",
        "",
        "Entry format: `<relpath> * <type> * <tags> * <1-line purpose> * scope:<scope>`",
        "",
    ]
    for section in section_order:
        entries = sections[section]
        if not entries:
            continue
        lines.append(f"## {section}")
        lines.extend(entries)
        lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Index file operations
# ---------------------------------------------------------------------------
def resolve_dir(dir_arg: Optional[str]) -> Path:
    if dir_arg:
        return Path(dir_arg).resolve()
    candidate = Path(".knowledge")
    if candidate.is_dir():
        return candidate.resolve()
    return Path(".").resolve()


def resolve_template() -> Path:
    return Path(__file__).resolve().parent / TEMPLATE_NAME


def do_init(base: Path, title: str, date: str) -> int:
    index_path = base / INDEX_NAME
    if index_path.exists():
        print(f"init: {index_path} already exists -- no action taken.")
        return 0
    template = resolve_template()
    if not template.exists():
        print(f"ERROR: template not found at {template}", file=sys.stderr)
        return 1
    text = template.read_text(encoding="utf-8")
    text = text.replace("<TITLE>", title or "Knowledge Index")
    text = text.replace("<DATE>", date or "<DATE>")
    base.mkdir(parents=True, exist_ok=True)
    index_path.write_text(text, encoding="utf-8")
    print(f"init: created {index_path}")
    return 0


def patch_index(index_path: Path, manifest: str, check_only: bool = False) -> bool:
    text = index_path.read_text(encoding="utf-8")
    if START_MARKER not in text or END_MARKER not in text:
        print(
            "ERROR: index.md is missing the AUTO-START / AUTO-END markers.\n"
            "Run with --init to create the file from the template, or add the markers manually:\n\n"
            f"  {START_MARKER}\n"
            f"  {END_MARKER}\n",
            file=sys.stderr,
        )
        return False
    pattern = re.compile(re.escape(START_MARKER) + ".*?" + re.escape(END_MARKER), re.DOTALL)
    new_block = f"{START_MARKER}\n{manifest}\n{END_MARKER}"
    new_text = pattern.sub(new_block, text)
    if new_text == text:
        print("build-index: index.md is up to date (no changes).")
        return True
    if check_only:
        # Show a brief diff summary
        old_lines = set(text.splitlines())
        new_lines = set(new_text.splitlines())
        added = [l for l in new_lines - old_lines if l.strip()]
        removed = [l for l in old_lines - new_lines if l.strip()]
        print("CHECK FAILED: index.md manifest is out of date.", file=sys.stderr)
        if removed:
            print("  Lines removed:", len(removed), file=sys.stderr)
            for l in removed[:5]:
                print(f"  - {l[:100]}", file=sys.stderr)
        if added:
            print("  Lines added:", len(added), file=sys.stderr)
            for l in added[:5]:
                print(f"  + {l[:100]}", file=sys.stderr)
        return False
    index_path.write_text(new_text, encoding="utf-8")
    manifest_lines = len([l for l in manifest.splitlines() if l.startswith("- ")])
    print(f"build-index: index.md updated ({manifest_lines} manifest entries).")
    return True


def do_refresh(base: Path, check_only: bool = False) -> int:
    index_path = base / INDEX_NAME
    if not index_path.exists():
        print(
            f"ERROR: {index_path} does not exist. Run with --init first.",
            file=sys.stderr,
        )
        return 1
    manifest = build_manifest(base, index_path)
    ok = patch_index(index_path, manifest, check_only=check_only)
    return 0 if ok else 1


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Scaffold and maintain a .knowledge/index.md routing index."
    )
    parser.add_argument("--dir", default=None, help="Target surface directory (default: .knowledge if present, else cwd).")
    parser.add_argument("--init", action="store_true", help="Create index.md from template if missing.")
    parser.add_argument("--title", default="Knowledge Index", help="Title for --init (default: 'Knowledge Index').")
    parser.add_argument("--date", default="", help="Date for --init header (YYYY-MM-DD). Defaults to placeholder.")
    parser.add_argument("--refresh", action="store_true", help="Regenerate manifest (default action).")
    parser.add_argument("--check", action="store_true", help="Exit 1 if manifest is out of date (CI mode).")
    args = parser.parse_args()

    base = resolve_dir(args.dir)

    if args.init:
        return do_init(base, args.title, args.date)

    if args.check:
        return do_refresh(base, check_only=True)

    # Default: --refresh
    return do_refresh(base)


if __name__ == "__main__":
    sys.exit(main())
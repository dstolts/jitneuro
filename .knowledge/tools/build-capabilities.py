# Vendored from dstolts/jit-knowledge skills/knowledge-index @ 7350473 -- refresh via rollout PRs, do not hand-edit.
#!/usr/bin/env python3
"""Scaffold and maintain a .knowledge/capabilities.md Capability Index.

Implements the tooling contract defined by the design of record:
  references/capability-index-design.md (ticket #3227, PR #536)

Sibling to build-index.py (same directory, same stdlib-first / PyYAML-if-available
posture, same marker-patch idempotency spirit) but addressed at PER-ENTRY
granularity via `<!-- CAP-START:<id> --> ... <!-- CAP-END:<id> -->` markers
instead of one whole-file AUTO-START/AUTO-END block.

Usage:
  python build-capabilities.py --init --dir DIR [--title NAME] [--date YYYY-MM-DD]
  python build-capabilities.py --refresh --dir DIR [--repo-root PATH] [--no-scan]
  python build-capabilities.py --check --dir DIR [--repo-root PATH] [--no-scan] [--since REF]

Modes:
  --init     Scaffold DIR/capabilities.md from the template if missing. No-op if present.
  --refresh  (default) Validate existing entries (flip status to `stale` when every
             entry_point is gone), then -- unless --no-scan -- scan the repo for new
             scannable capability signals (see classify_signal) and append a `draft`
             entry for each one not already claimed by an existing entry's
             entry_points. Writes only if the rendered file differs (idempotent).
  --check    CI staleness gate. Validates structural integrity (duplicate id,
             malformed CAP-START/END pairing, invalid `kind`/`status` enum, missing
             required fields) and existing-entry path rot -- always blocking.
             Unless --no-scan, also scans for unclaimed capability signals and
             reports them; this is INFORMATIONAL ONLY unless --since REF is given,
             in which case only signals ADDED since REF (git diff --diff-filter=A)
             are blocking -- mirrors manifest-check.yml's diff-scoped
             routing-row-check gate, applied to capability signals instead of
             INDEX.md routing rows. A signal file carrying a `capability_exempt:
             true` marker (see is_capability_exempt()) is excluded from both the
             draft-creation pass and the --since blocking gate. The exemption is
             always reported in the check output -- never applied silently.

Design simplifications made explicit here (see PR body for the same list):
  - No filename-similarity "this looks like a rename" heuristic. An entry whose
    entry_points are PARTIALLY missing is left untouched and reported as a
    non-blocking warning (never silently rewritten). Only a FULLY missing
    entry_points list triggers the automatic stale flip the design describes as
    "signal disappeared entirely."
  - classify_signal() only implements heuristics for the five `kind`s this repo's
    seed actually populates (job, hook, module, skill, schema). `service`,
    `endpoint`, and `component` need a repo-specific routing convention per the
    design doc itself ("matching the repo's own routing convention") -- add
    patterns to classify_signal() when a consuming repo needs them.
  - is_capability_exempt() reads a marker, not a schema. Markdown files (the
    only scanned `kind` with an established frontmatter convention -- see
    governance/FRONTMATTER-SCHEMA.md) are checked for `capability_exempt: true`
    inside a leading `---` YAML frontmatter block. Every other scanned
    extension (.py, .sh, .yml/.yaml, .sql) has its own comment grammar, so
    rather than write a parser per language, the same marker is matched as a
    plain-text line inside a small leading window of the file -- consistent
    with classify_signal()'s own posture of "narrow, extensible heuristics"
    rather than full-language parsing.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
KIND_ENUM = ["service", "module", "endpoint", "hook", "job", "skill", "schema", "component"]
STATUS_ENUM = ["draft", "verified", "stale", "deprecated"]

CAPABILITIES_NAME = "capabilities.md"
TEMPLATE_NAME = "capabilities-template.md"
BOOTSTRAP_ANCHOR = "<!-- CAPABILITIES-ENTRIES-HERE -->"

KIND_HEADING_RE = re.compile(r"^## (" + "|".join(KIND_ENUM) + r")\s*$", re.MULTILINE)
CAP_BLOCK_RE = re.compile(
    r"<!-- CAP-START:(?P<id1>[A-Za-z0-9][A-Za-z0-9_-]*) -->\n"
    r"```yaml\n(?P<yaml>.*?)\n```\n"
    r"<!-- CAP-END:(?P<id2>[A-Za-z0-9][A-Za-z0-9_-]*) -->",
    re.DOTALL,
)
CAP_START_ONLY_RE = re.compile(r"<!-- CAP-START:([A-Za-z0-9][A-Za-z0-9_-]*) -->")
CAP_END_ONLY_RE = re.compile(r"<!-- CAP-END:([A-Za-z0-9][A-Za-z0-9_-]*) -->")

EXCLUDE_DIR_NAMES = {"node_modules", ".git", ".archive", "zArchive", "__fixtures__"}

REQUIRED_FIELDS = ["id", "name", "kind", "purpose", "entry_points", "owner_lane", "status"]

# ---------------------------------------------------------------------------
# YAML block parsing -- stdlib-first, PyYAML used when available.
# Mirrors build-index.py's "PyYAML if present, else minimal fallback" posture,
# extended to handle a block-style (`key:\n  - item`) list, which
# build-index.py's fallback parser does not need for frontmatter but this
# schema's `entry_points` field requires.
# ---------------------------------------------------------------------------
try:
    import yaml as _yaml  # type: ignore

    def parse_entry_yaml(text: str) -> dict:
        try:
            parsed = _yaml.safe_load(text) or {}
            return parsed if isinstance(parsed, dict) else {}
        except Exception:
            return {}

except ImportError:
    _yaml = None  # type: ignore

    def parse_entry_yaml(text: str) -> dict:  # type: ignore[no-redef]
        """Minimal fallback parser: flat scalars, inline `[a, b]` lists, and
        block-style `key:\n  - item` lists (the only list shape this schema uses)."""
        result: dict = {}
        lines = text.splitlines()
        i = 0
        while i < len(lines):
            line = lines[i].rstrip()
            i += 1
            if not line.strip() or line.strip().startswith("#"):
                continue
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$", line)
            if not m:
                continue
            key, val = m.group(1), m.group(2).strip()
            if val == "":
                # Possible block list on following indented `- ` lines.
                items = []
                while i < len(lines) and re.match(r"^\s+- ", lines[i]):
                    items.append(lines[i].strip()[2:].strip())
                    i += 1
                result[key] = items
            elif val.startswith("[") and val.endswith("]"):
                inner = val[1:-1]
                result[key] = [v.strip().strip('"').strip("'") for v in inner.split(",") if v.strip()]
            else:
                if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                result[key] = val
        return result


# ---------------------------------------------------------------------------
# Signal classification (auto-scan heuristics, per the design's field table)
# ---------------------------------------------------------------------------
def classify_signal(relpath: str) -> Optional[str]:
    """Return a `kind` guess for a repo-relative path, or None if unclassified.

    Narrow, extensible heuristic set. Only covers the five kinds this repo's
    own seed populates (job, hook, module, skill, schema) -- see module
    docstring. Add patterns here for `service` / `endpoint` / `component` when
    a consuming repo's own routing convention needs them.
    """
    p = relpath.replace("\\", "/")
    if re.match(r"^skills/[^/]+/SKILL\.md$", p):
        return "skill"
    if re.match(r"^templates/claude-hooks/.*\.sh$", p):
        return "hook"
    if re.match(r"^\.github/workflows/.*\.ya?ml$", p):
        return "job"
    if re.match(r"^db/.*\.sql$", p):
        return "schema"
    if re.match(r"^scripts/.*\.(py|sh)$", p):
        return "module"
    return None


def scan_signals(repo_root: Path) -> list[str]:
    """Walk repo_root, return repo-relative paths matching classify_signal()."""
    found: list[str] = []
    for path in sorted(repo_root.rglob("*")):
        if not path.is_file():
            continue
        rel_parts = path.relative_to(repo_root).parts
        if any(part in EXCLUDE_DIR_NAMES for part in rel_parts):
            continue
        rel = path.relative_to(repo_root).as_posix()
        if classify_signal(rel):
            found.append(rel)
    return found


# ---------------------------------------------------------------------------
# capability_exempt marker (see module docstring "Design simplifications")
# ---------------------------------------------------------------------------
CAPABILITY_EXEMPT_RE = re.compile(r"capability_exempt\s*:\s*true\b", re.IGNORECASE)
FRONTMATTER_RE = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.DOTALL)
EXEMPT_SCAN_LINES = 20  # leading-window size for the non-frontmatter comment scan


def is_capability_exempt(path: Path) -> bool:
    """Return True if `path` declares itself exempt from the new-signal gate.

    - Markdown files (`.md`): the marker must appear inside a leading YAML
      frontmatter block (`--- ... ---`), matching this repo's existing
      frontmatter convention -- so a `capability_exempt: true` mentioned in
      body prose does not accidentally exempt the file.
    - Every other scanned extension (.py, .sh, .yml/.yaml, .sql, ...): the
      marker is matched as a plain-text line inside the first
      EXEMPT_SCAN_LINES lines, tolerant of whatever comment syntax the file
      uses (#, //, --, <!-- -->). classify_signal() covers multiple
      languages; a single per-language comment grammar is not worth building
      for a one-line opt-out marker (see module docstring).

    Unreadable files (permissions, encoding) are treated as NOT exempt --
    fails closed so a marker that cannot be verified never silently skips the
    gate.
    """
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False

    if path.suffix.lower() == ".md":
        m = FRONTMATTER_RE.match(text)
        if not m:
            return False
        return bool(CAPABILITY_EXEMPT_RE.search(m.group(1)))

    head = "\n".join(text.splitlines()[:EXEMPT_SCAN_LINES])
    return bool(CAPABILITY_EXEMPT_RE.search(head))


def partition_exempt(repo_root: Path, relpaths: list[str]) -> tuple[list[str], list[str]]:
    """Split repo-relative paths into (non_exempt, exempt) via is_capability_exempt()."""
    non_exempt: list[str] = []
    exempt: list[str] = []
    for rel in relpaths:
        if is_capability_exempt(repo_root / rel):
            exempt.append(rel)
        else:
            non_exempt.append(rel)
    return non_exempt, exempt


def diff_added_files(repo_root: Path, since_ref: str) -> list[str]:
    """Return repo-relative paths ADDED since `since_ref` (git diff --diff-filter=A)."""
    try:
        result = subprocess.run(
            ["git", "diff", "--diff-filter=A", "--name-only", since_ref, "HEAD"],
            cwd=str(repo_root),
            capture_output=True,
            text=True,
            check=True,
        )
    except Exception as exc:  # pragma: no cover - defensive
        print(f"WARNING: git diff --since failed ({exc}); treating as empty.", file=sys.stderr)
        return []
    return [f.strip() for f in result.stdout.splitlines() if f.strip()]


# ---------------------------------------------------------------------------
# Entry model
# ---------------------------------------------------------------------------
class Entry:
    def __init__(self, entry_id: str, kind_section: str, fm: dict, raw_block: str, start: int, end: int):
        self.id = entry_id
        self.kind_section = kind_section  # the ## heading this block was found under
        self.fm = fm
        self.raw_block = raw_block
        self.start = start
        self.end = end

    @property
    def entry_points(self) -> list[str]:
        ep = self.fm.get("entry_points")
        return ep if isinstance(ep, list) else ([ep] if ep else [])


class ParseResult:
    def __init__(self):
        self.entries: list[Entry] = []
        self.errors: list[str] = []
        self.prefix = ""
        self.suffix = ""
        self.has_anchor = False


def parse_capabilities(text: str) -> ParseResult:
    result = ParseResult()

    headings = list(KIND_HEADING_RE.finditer(text))
    blocks = list(CAP_BLOCK_RE.finditer(text))

    # Malformed-block detection: a CAP-START with no matching CAP-END (or vice
    # versa) shows up as a start/end count mismatch against the paired regex.
    starts = CAP_START_ONLY_RE.findall(text)
    ends = CAP_END_ONLY_RE.findall(text)
    if len(starts) != len(blocks) or len(ends) != len(blocks):
        result.errors.append(
            f"malformed capability block(s): found {len(starts)} CAP-START marker(s), "
            f"{len(ends)} CAP-END marker(s), but only {len(blocks)} well-formed pair(s) "
            "(mismatched id, missing fence, or unterminated block)"
        )

    seen_ids: dict[str, int] = {}
    for b in blocks:
        id1, id2, yaml_text = b.group("id1"), b.group("id2"), b.group("yaml")
        if id1 != id2:
            result.errors.append(f"CAP-START:{id1} does not match CAP-END:{id2} -- mismatched marker pair")
            continue
        fm = parse_entry_yaml(yaml_text)
        seen_ids[id1] = seen_ids.get(id1, 0) + 1

        # Which kind heading precedes this block?
        preceding = [h.group(1) for h in headings if h.start() < b.start()]
        kind_section = preceding[-1] if preceding else "(none)"

        entry = Entry(id1, kind_section, fm, b.group(0), b.start(), b.end())
        result.entries.append(entry)

    for eid, count in seen_ids.items():
        if count > 1:
            result.errors.append(f"duplicate capability id '{eid}' ({count} occurrences)")

    # Structural validation per entry
    for e in result.entries:
        for field in REQUIRED_FIELDS:
            if field not in e.fm or e.fm.get(field) in (None, "", []):
                result.errors.append(f"'{e.id}': missing required field '{field}'")
        kind = e.fm.get("kind")
        if kind is not None and kind not in KIND_ENUM:
            result.errors.append(f"'{e.id}': invalid kind '{kind}' -- must be one of {KIND_ENUM}")
        if kind is not None and kind != e.kind_section and e.kind_section != "(none)":
            result.errors.append(
                f"'{e.id}': yaml kind '{kind}' does not match its '## {e.kind_section}' section heading"
            )
        status = e.fm.get("status")
        if status is not None and status not in STATUS_ENUM:
            result.errors.append(f"'{e.id}': invalid status '{status}' -- must be one of {STATUS_ENUM}")
        if status in ("verified", "stale", "deprecated"):
            lv = e.fm.get("last_verified")
            if not lv or not re.match(r"^\d{4}-\d{2}-\d{2}$", str(lv)):
                result.errors.append(
                    f"'{e.id}': status '{status}' requires a valid last_verified (YYYY-MM-DD)"
                )

    # Prefix / suffix split: managed region runs from the first kind heading
    # through the end of the last CAP-END marker. Everything else (frontmatter,
    # intro prose, trailing hand-written notes) is preserved byte-for-byte.
    if headings:
        first_heading_start = headings[0].start()
        result.prefix = text[:first_heading_start]
        if blocks:
            last_block_end = blocks[-1].end()
            result.suffix = text[last_block_end:]
        else:
            # Heading(s) present but zero entries under them -- per the design,
            # empty kind sections should be OMITTED, not headed-and-empty.
            result.errors.append(
                "one or more '## <kind>' headings present with no capability entries "
                "underneath -- remove the empty heading, or add an entry"
            )
            result.suffix = text[first_heading_start:]
            result.prefix = text[:first_heading_start]
    elif BOOTSTRAP_ANCHOR in text:
        idx = text.index(BOOTSTRAP_ANCHOR)
        result.prefix = text[:idx]
        result.suffix = text[idx + len(BOOTSTRAP_ANCHOR):]
        result.has_anchor = True
    else:
        result.errors.append(
            f"no '## <kind>' heading and no {BOOTSTRAP_ANCHOR} bootstrap anchor found -- "
            "file is missing its insertion point. Run --init to scaffold a fresh file."
        )

    return result


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------
def render_new_entry(entry_id: str, name: str, kind: str, purpose: str, entry_points: list[str], owner_lane: str, status: str) -> str:
    lines = [f"<!-- CAP-START:{entry_id} -->", "```yaml"]
    lines.append(f"id: {entry_id}")
    lines.append(f"name: {name}")
    lines.append(f"kind: {kind}")
    lines.append(f"purpose: {purpose}")
    lines.append("entry_points:")
    for ep in entry_points:
        lines.append(f"  - {ep}")
    lines.append(f"owner_lane: {owner_lane}")
    lines.append(f"status: {status}")
    lines.append("```")
    lines.append(f"<!-- CAP-END:{entry_id} -->")
    return "\n".join(lines)


def flip_to_stale(raw_block: str) -> str:
    """Targeted single-line substitution -- never touches any other field."""
    return re.sub(r"(?m)^status: \w+$", "status: stale", raw_block, count=1)


def slugify(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "capability"


def humanize(slug: str) -> str:
    return " ".join(w.capitalize() for w in slug.replace("_", "-").split("-"))


def render_file(parsed: ParseResult, sections: dict[str, list[Entry]], section_order: list[str]) -> str:
    """Render the full file: prefix + managed region (headings + blocks) + suffix."""
    prefix = parsed.prefix.rstrip("\n")
    lead = "\n\n" if prefix else ""
    parts = [prefix]
    body_chunks = []
    for kind in section_order:
        entries = sections.get(kind) or []
        if not entries:
            continue
        block_text = "\n\n".join(e.raw_block for e in entries)
        body_chunks.append(f"## {kind}\n\n{block_text}")
    managed = "\n\n".join(body_chunks)
    if managed:
        parts.append(lead + managed)
    else:
        parts.append(lead + BOOTSTRAP_ANCHOR)
    parts.append(parsed.suffix)
    return "".join(parts)


# ---------------------------------------------------------------------------
# Path resolution (mirrors build-index.py's resolve_dir -- kept as a small,
# intentional duplication rather than a fragile hyphenated-module import;
# see module docstring)
# ---------------------------------------------------------------------------
def resolve_dir(dir_arg: Optional[str]) -> Path:
    if dir_arg:
        return Path(dir_arg).resolve()
    candidate = Path(".knowledge")
    if candidate.is_dir():
        return candidate.resolve()
    return Path(".").resolve()


def resolve_repo_root(base: Path, repo_root_arg: Optional[str]) -> Path:
    if repo_root_arg:
        return Path(repo_root_arg).resolve()
    if base.name == ".knowledge":
        return base.parent
    return Path(".").resolve()


def resolve_template() -> Path:
    return Path(__file__).resolve().parent / TEMPLATE_NAME


# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------
def do_init(base: Path, title: str, date: str) -> int:
    cap_path = base / CAPABILITIES_NAME
    if cap_path.exists():
        print(f"init: {cap_path} already exists -- no action taken.")
        return 0
    template = resolve_template()
    if not template.exists():
        print(f"ERROR: template not found at {template}", file=sys.stderr)
        return 1
    text = template.read_text(encoding="utf-8")
    text = text.replace("<REPO_NAME>", title or "this repo")
    text = text.replace("<DATE>", date or "<DATE>")
    base.mkdir(parents=True, exist_ok=True)
    cap_path.write_text(text, encoding="utf-8")
    print(f"init: created {cap_path}")
    return 0


def validate_and_update(parsed: ParseResult, repo_root: Path) -> tuple[list[str], list[str], bool]:
    """Returns (blocking_errors, warnings, changed).

    `changed` is True if any entry's raw_block was mutated in place (stale flip)."""
    blocking = list(parsed.errors)
    warnings: list[str] = []
    changed = False

    for e in parsed.entries:
        if e.fm.get("status") == "deprecated":
            continue
        eps = e.entry_points
        if not eps:
            continue
        resolved = [ep for ep in eps if (repo_root / ep).exists()]
        if not resolved:
            if e.fm.get("status") != "stale":
                warnings.append(f"'{e.id}': all entry_points missing -- flip to stale")
                e.raw_block = flip_to_stale(e.raw_block)
                e.fm["status"] = "stale"
                changed = True
        elif len(resolved) < len(eps):
            warnings.append(
                f"'{e.id}': partial path rot -- {len(eps) - len(resolved)}/{len(eps)} entry_points missing "
                "(not auto-updated; no rename-detection heuristic is implemented -- see module docstring)"
            )

    return blocking, warnings, changed


def claimed_paths(parsed: ParseResult) -> set[str]:
    claimed: set[str] = set()
    for e in parsed.entries:
        claimed.update(e.entry_points)
    return claimed


def build_sections(parsed: ParseResult) -> tuple[dict[str, list[Entry]], list[str]]:
    sections: dict[str, list[Entry]] = {}
    order: list[str] = []
    for e in parsed.entries:
        k = e.kind_section
        if k not in sections:
            sections[k] = []
            order.append(k)
        sections[k].append(e)
    return sections, order


def insert_new_entry(sections: dict[str, list[Entry]], order: list[str], kind: str, block_text: str, entry_id: str) -> None:
    fake_entry = Entry(entry_id, kind, {}, block_text, -1, -1)
    if kind in sections:
        sections[kind].append(fake_entry)
        return
    # New kind section: place it per KIND_ENUM order relative to existing sections.
    sections[kind] = [fake_entry]
    new_idx = KIND_ENUM.index(kind)
    insert_at = len(order)
    for i, existing_kind in enumerate(order):
        if existing_kind in KIND_ENUM and KIND_ENUM.index(existing_kind) > new_idx:
            insert_at = i
            break
    order.insert(insert_at, kind)


def do_refresh(base: Path, repo_root: Path, no_scan: bool, check_only: bool, since_ref: Optional[str]) -> int:
    cap_path = base / CAPABILITIES_NAME
    if not cap_path.exists():
        print(f"ERROR: {cap_path} does not exist. Run with --init first.", file=sys.stderr)
        return 1

    text = cap_path.read_text(encoding="utf-8")
    parsed = parse_capabilities(text)

    if parsed.errors:
        print("CHECK FAILED: structural errors in capabilities.md:" if check_only else "ERRORS in capabilities.md:", file=sys.stderr)
        for err in parsed.errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    blocking, warnings, changed = validate_and_update(parsed, repo_root)
    for w in warnings:
        print(f"WARNING: {w}")
    if blocking:
        print("CHECK FAILED:" if check_only else "ERRORS:", file=sys.stderr)
        for err in blocking:
            print(f"  - {err}", file=sys.stderr)
        return 1

    sections, order = build_sections(parsed)

    new_draft_count = 0
    blocking_uncovered: list[str] = []
    if not no_scan:
        already_claimed = claimed_paths(parsed)
        signals = scan_signals(repo_root)
        candidate_unclaimed = [s for s in signals if s not in already_claimed]
        # A `capability_exempt: true` marker removes a signal from the whole
        # unclaimed pipeline -- not just the --since blocking gate -- so an
        # exempt file is never proposed as a draft entry either (it declared
        # itself "not a distinct capability", per the error text's promise).
        # ALWAYS reported below; exemption is never applied silently.
        unclaimed, exempted = partition_exempt(repo_root, candidate_unclaimed)

        if since_ref:
            added = set(diff_added_files(repo_root, since_ref))
            uncovered_new = [s for s in unclaimed if s in added]
            if uncovered_new:
                blocking_uncovered = uncovered_new

        if exempted:
            print(f"INFO: {len(exempted)} scannable capability signal(s) marked "
                  "capability_exempt -- excluded from the coverage gate:")
            for s in exempted[:20]:
                print(f"  - {s} (kind guess: {classify_signal(s)})")
            if len(exempted) > 20:
                print(f"  ... and {len(exempted) - 20} more")

        if unclaimed:
            print(f"INFO: {len(unclaimed)} scannable capability signal(s) not yet catalogued:")
            for s in unclaimed[:20]:
                print(f"  - {s} (kind guess: {classify_signal(s)})")
            if len(unclaimed) > 20:
                print(f"  ... and {len(unclaimed) - 20} more")

        if not check_only:
            used_ids = {e.id for e in parsed.entries}
            for s in unclaimed:
                kind = classify_signal(s) or "module"
                p = Path(s)
                # SKILL.md's own filename is uninformative -- the skill's
                # identity is its containing directory name.
                slug_source = p.parent.name if p.name == "SKILL.md" else p.stem
                base_slug = slugify(slug_source)
                slug = base_slug
                n = 2
                while slug in used_ids:
                    slug = f"{base_slug}-{n}"
                    n += 1
                used_ids.add(slug)
                block_text = render_new_entry(
                    entry_id=slug,
                    name=humanize(base_slug),
                    kind=kind,
                    purpose=f"TODO -- describe this capability (see {s}).",
                    entry_points=[s],
                    owner_lane="unknown",
                    status="draft",
                )
                insert_new_entry(sections, order, kind, block_text, slug)
                new_draft_count += 1
                changed = True

    if blocking_uncovered:
        print("CHECK FAILED: new capability signal(s) added since "
              f"{since_ref} with no capability-index entry:", file=sys.stderr)
        for s in blocking_uncovered:
            print(f"  - {s} (kind guess: {classify_signal(s)})", file=sys.stderr)
        print(
            "Fix: add a capability entry citing this path in entry_points "
            f"(run `python {Path(__file__).name} --refresh` to auto-add a draft entry), "
            "or add a `capability_exempt: true` marker to the new file if it is not a "
            "distinct capability.",
            file=sys.stderr,
        )
        return 1

    new_text = render_file(parsed, sections, order)
    if new_text == text:
        print(f"{'check' if check_only else 'refresh'}: capabilities.md is up to date (no changes).")
        return 0

    if check_only:
        print("CHECK FAILED: capabilities.md is out of date (stale entries or unclaimed signals).", file=sys.stderr)
        return 1

    cap_path.write_text(new_text, encoding="utf-8")
    print(
        f"refresh: capabilities.md updated ({len(parsed.entries)} existing entries, "
        f"{new_draft_count} new draft(s) added)."
    )
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Scaffold and maintain a .knowledge/capabilities.md Capability Index."
    )
    parser.add_argument("--dir", default=None, help="Target .knowledge directory (default: .knowledge if present, else cwd).")
    parser.add_argument("--init", action="store_true", help="Create capabilities.md from template if missing.")
    parser.add_argument("--title", default="", help="Repo name for --init header (default: 'this repo').")
    parser.add_argument("--date", default="", help="Date for --init header (YYYY-MM-DD).")
    parser.add_argument("--refresh", action="store_true", help="Regenerate capabilities.md (default action).")
    parser.add_argument("--check", action="store_true", help="Exit 1 if capabilities.md is out of date (CI mode).")
    parser.add_argument("--repo-root", default=None, help="Repo root for entry_points resolution and scanning (default: parent of --dir).")
    parser.add_argument("--no-scan", action="store_true", help="Skip scanning the repo for new capability signals.")
    parser.add_argument("--since", default=None, metavar="REF", help="Make new-signal coverage BLOCKING for files added since this git ref (diff-scoped, mirrors manifest-check.yml's routing-row-check).")
    args = parser.parse_args()

    base = resolve_dir(args.dir)
    repo_root = resolve_repo_root(base, args.repo_root)

    if args.init:
        return do_init(base, args.title, args.date)

    if args.check:
        return do_refresh(base, repo_root, args.no_scan, check_only=True, since_ref=args.since)

    return do_refresh(base, repo_root, args.no_scan, check_only=False, since_ref=args.since)


if __name__ == "__main__":
    sys.exit(main())

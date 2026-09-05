#!/usr/bin/env python3
"""Check a pull request body against the PR standard in .github/PR_STANDARD.md.

Standard library only, so it runs the same on a laptop and in Actions:

    python3 .github/scripts/check_pr_standard.py --body body.md --files changed.txt

`body.md` is the PR description; `changed.txt` lists the changed paths, one per
line (used to detect docs-only PRs, which skip the demo and proof). Exit code 0
means every required check passed. `--summary out.md` also writes a markdown
report suitable for a step summary or a PR comment.

Redaction findings never echo the matched text in full: only the pattern name
and a masked prefix are reported, so the report itself cannot leak.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass, field

ERROR, WARN, INFO = "error", "warn", "info"

# --- what counts as a docs-only change --------------------------------------
DOCS_ONLY_PATTERNS = [
    re.compile(p)
    for p in (
        r"(?i)\.(md|rst|txt|adoc)$",
        r"^docs/",
        r"(?i)^(LICENSE|NOTICE|CHANGELOG|CODEOWNERS|AUTHORS|CONTRIBUTORS)(\..*)?$",
        r"^\.github/(PULL_REQUEST_TEMPLATE|ISSUE_TEMPLATE|CODEOWNERS)",
    )
]

# --- media / waiver detection in the Demo section ----------------------------
MEDIA_RE = re.compile(
    r"(!\[[^\]]*\]\([^)]+\)"  # markdown image (gif/png)
    r"|<video\b|<img\b"  # inline html player / image
    r"|github\.com/user-attachments/assets/"  # drag-and-drop upload
    r"|/releases/download/[^\s)]+\.(?:gif|mp4|webm|mov)\b"  # prerelease asset
    r"|https?://\S+\.(?:gif|mp4|webm)\b)",  # any other direct media link
    re.I,
)
WAIVER_RE = re.compile(
    r"^\s*(?:[*_]{0,2})(?:demo waived|no demo)(?:[*_]{0,2})\s*[:—–-]\s*(?:[*_]{0,2})\s*(?P<reason>\S.*)$",
    re.I | re.M,
)
WAIVER_MIN_REASON = 10

PLACEHOLDER_RE = re.compile(r"\[\[[^\]\n]+\]\]")
FOOTER_RE = re.compile(r"^\s*[_*]*(?:🤖\s*)?Generated (?:with|by) \[?Claude Code\]?", re.I | re.M)
CHECKED_RE = re.compile(r"^\s*[-*]\s+\[[xX]\]\s+\S", re.M)
UNCHECKED_RE = re.compile(r"^\s*[-*]\s+\[ \]\s+\S", re.M)
BULLET_RE = re.compile(r"^\s*[-*]\s+\S", re.M)
FENCE_RE = re.compile(r"^\s*(```|~~~)[^\n]*\n(.*?)^\s*\1\s*$", re.M | re.S)
DETAILS_RE = re.compile(
    r"<details\b[^>]*>\s*<summary\b[^>]*>(?P<label>.*?)</summary>(?P<body>.*?)</details>",
    re.I | re.S,
)
COMMENT_RE = re.compile(r"<!--.*?-->", re.S)
TAG_RE = re.compile(r"<[^>]+>")
ALLOW_RE = re.compile(r"<!--\s*pr-standard-allow:\s*([a-z0-9_, -]+)\s*-->", re.I)

REQUIRED_DETAILS = ("full summary", "files")
OPTIONAL_DETAILS = ("architecture",)
PROOF_INLINE_MAX_LINES = 15

# --- redaction patterns ------------------------------------------------------
# id -> (regex, why). Findings report the id and a masked sample only.
REDACTION_PATTERNS: dict[str, tuple[re.Pattern[str], str]] = {
    "email": (
        re.compile(r"\b[A-Za-z0-9._%+-]+@(?!(?:users\.)?noreply\.|example\.)[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
        "email address",
    ),
    "home-path": (
        re.compile(r"/(?:Users|home)/(?!runner\b|user\b|<)[A-Za-z0-9._-]+"),
        "home directory with a real user name (use ~ or /Users/<you>)",
    ),
    "ipv4": (
        re.compile(
            r"(?<![\w.])(?!0\.0\.0\.0|127\.0\.0\.1|255\.255\.255\.255)"
            r"(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?![\w.])"
        ),
        "IP address",
    ),
    "mac": (
        re.compile(r"\b(?:[0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\b"),
        "MAC address",
    ),
    "lan-host": (
        re.compile(r"\b[A-Za-z0-9-]+\.(?:local|lan|internal|home\.arpa)\b(?![.\w-])"),
        "LAN hostname",
    ),
    "serial": (
        re.compile(r"(?i)(?<![\w-])(?:serial(?:\s*(?:number|no\.?))?|--device)\s*[:#=]?\s*\d{6,10}\b"),
        "hardware serial number (mask it: ******64)",
    ),
    "api-key": (
        re.compile(
            r"(?:\bsk-ant-[A-Za-z0-9_-]{20,}|\bsk-[A-Za-z0-9]{32,}|\bgh[pousr]_[A-Za-z0-9]{20,}"
            r"|\bgithub_pat_[A-Za-z0-9_]{20,}|\bAKIA[0-9A-Z]{16}\b|\bxox[baprs]-[A-Za-z0-9-]{10,})"
        ),
        "API key or token",
    ),
    "jwt": (
        re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}"),
        "JWT",
    ),
    "private-key": (
        re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
        "private key block",
    ),
    "session-url": (
        re.compile(r"https?://claude\.ai/code/session_[A-Za-z0-9]+"),
        "agent session link (name the tool in Provenance instead)",
    ),
}
BLOCKED_DOMAINS_ENV = "PR_STANDARD_BLOCKED_DOMAINS"


@dataclass
class Finding:
    check: str
    level: str
    message: str


@dataclass
class Report:
    findings: list[Finding] = field(default_factory=list)
    docs_only: bool = False

    def add(self, check: str, level: str, message: str) -> None:
        self.findings.append(Finding(check, level, message))

    @property
    def errors(self) -> list[Finding]:
        return [f for f in self.findings if f.level == ERROR]

    @property
    def ok(self) -> bool:
        return not self.errors


# --- parsing -----------------------------------------------------------------
def strip_comments(text: str) -> str:
    return COMMENT_RE.sub("", text)


def normalise_label(label: str) -> str:
    label = TAG_RE.sub("", label)
    label = re.sub(r"[^A-Za-z0-9 ]+", " ", label)
    return re.sub(r"\s+", " ", label).strip().lower()


def split_sections(text: str) -> tuple[str, list[tuple[str, str]]]:
    """Return (preamble, [(heading, body)]) for every `## ` heading outside code fences."""
    preamble: list[str] = []
    sections: list[tuple[str, list[str]]] = []
    in_fence = None
    for line in text.splitlines():
        fence = re.match(r"^\s*(```|~~~)", line)
        if fence:
            in_fence = None if in_fence == fence.group(1) else (in_fence or fence.group(1))
        if not in_fence and re.match(r"^##\s+\S", line):
            sections.append((line[2:].strip(), []))
            continue
        (sections[-1][1] if sections else preamble).append(line)
    return "\n".join(preamble), [(h, "\n".join(b)) for h, b in sections]


def find_section(sections: list[tuple[str, str]], key: str) -> tuple[str, str] | None:
    for heading, body in sections:
        if normalise_label(heading).startswith(key):
            return heading, body
    return None


def is_docs_only(paths: list[str]) -> bool:
    paths = [p.strip() for p in paths if p.strip()]
    return bool(paths) and all(any(p.search(path) for p in DOCS_ONLY_PATTERNS) for path in paths)


def mask(sample: str) -> str:
    keep = min(3, max(1, len(sample) // 4))
    return sample[:keep] + "…" * 1 + "*" * min(8, max(0, len(sample) - keep))


# --- checks ------------------------------------------------------------------
def check_lede(report: Report, visible: str, preamble: str) -> None:
    lines = [l for l in visible.splitlines() if l.strip()]
    if not lines or not re.match(r"^#\s+\S", lines[0]):
        report.add("lede", ERROR, "Start with an H1 title line (`# repo — what this PR does`).")
    prose = [l for l in preamble.splitlines() if l.strip() and not l.lstrip().startswith("#")]
    if not prose:
        report.add("lede", ERROR, "Follow the title with a one-paragraph lede before the first `## ` section.")


def check_demo(report: Report, sections: list[tuple[str, str]]) -> None:
    sec = find_section(sections, "demo")
    if report.docs_only:
        report.add("demo", INFO, "Docs-only change: demo not required.")
        if sec and MEDIA_RE.search(sec[1]):
            report.add("demo", INFO, "Demo present anyway; thank you.")
        return
    if sec is None:
        report.add("demo", ERROR, "Add a `## Demo` section: a GIF plus an mp4 link, or `**Demo waived:** <reason>`.")
        return
    body = sec[1]
    waiver = WAIVER_RE.search(body)
    media = MEDIA_RE.search(body)
    if media:
        if not re.search(r"\.gif\b", body, re.I) and "user-attachments" not in body and "<video" not in body.lower():
            report.add("demo", WARN, "Demo has no GIF; a GIF autoplays inline, an mp4 link does not.")
        if not re.search(r"\.(?:mp4|webm|mov)\b", body, re.I) and "user-attachments" not in body:
            report.add("demo", WARN, "Demo has no mp4 link; a GIF has no player controls.")
        prose = [
            l for l in body.splitlines()
            if l.strip() and not MEDIA_RE.search(l) and not l.strip().startswith("<") and not WAIVER_RE.match(l)
        ]
        if not prose:
            report.add("demo", ERROR, "Caption the demo: one italic line saying what happens on screen and what was redacted.")
        return
    if waiver:
        reason = waiver.group("reason").strip()
        if len(reason) < WAIVER_MIN_REASON:
            report.add("demo", ERROR, "Demo waiver needs a real reason (at least a short sentence).")
        else:
            report.add("demo", WARN, f"Demo waived by the author: {reason}")
        return
    report.add("demo", ERROR, "`## Demo` has no media. Add a GIF + mp4 (`scripts/publish-demo.sh`), or `**Demo waived:** <reason>`.")


def check_test_plan(report: Report, sections: list[tuple[str, str]]) -> None:
    sec = find_section(sections, "test plan")
    if sec is None:
        report.add("test-plan", ERROR, "Add a `## Test Plan` with checked boxes for what was actually run.")
        return
    checked, unchecked = CHECKED_RE.findall(sec[1]), UNCHECKED_RE.findall(sec[1])
    if not checked:
        report.add("test-plan", ERROR, "Test Plan has no checked item (`- [x]`). Run it, then check it.")
    if unchecked:
        report.add("test-plan", WARN, f"{len(unchecked)} Test Plan item(s) unchecked; say why on the line, or run them.")


def check_proof(report: Report, sections: list[tuple[str, str]]) -> None:
    sec = find_section(sections, "proof")
    if report.docs_only:
        report.add("proof", INFO, "Docs-only change: proof not required.")
        return
    if sec is None:
        report.add("proof", ERROR, "Add `## Proof (redacted)` with real, collapsed terminal output.")
        return
    heading, body = sec
    if "redact" not in (heading + body).lower():
        report.add("proof", ERROR, "State the redaction: head it `## Proof (redacted)`, or say `nothing to redact` in the section.")
    fences = FENCE_RE.findall(body)
    if not fences:
        report.add("proof", ERROR, "Proof needs at least one fenced block of real output.")
        return
    inside_details = "".join(m.group("body") for m in DETAILS_RE.finditer(body))
    for _, content in fences:
        n = len(content.splitlines())
        if n > PROOF_INLINE_MAX_LINES and content not in inside_details:
            report.add("proof", ERROR, f"A {n}-line output block is not collapsed; wrap it in `<details><summary>`.")
            break


def check_details(report: Report, visible: str) -> None:
    labels = {normalise_label(m.group("label")) for m in DETAILS_RE.finditer(visible)}
    for want in REQUIRED_DETAILS:
        if not any(l.endswith(want) or want in l for l in labels):
            report.add("details", ERROR, f"Add a collapsed `<details><summary><strong>{want.title()}</strong></summary>` section.")
    for want in OPTIONAL_DETAILS:
        if not any(want in l for l in labels):
            report.add("details", INFO, f"No `{want.title()}` section; fine if the shape of the system did not change.")


def check_provenance(report: Report, sections: list[tuple[str, str]]) -> None:
    sec = find_section(sections, "provenance")
    if sec is None or not BULLET_RE.search(sec[1]):
        report.add("provenance", ERROR, "End with `## Provenance`: who authored, who reviewed, how each commit was tested, where demo assets live.")


def check_placeholders(report: Report, visible: str) -> None:
    left = sorted({m.group(0) for m in PLACEHOLDER_RE.finditer(visible)})
    if left:
        shown = ", ".join(f"`{p}`" for p in left[:5]) + (" …" if len(left) > 5 else "")
        report.add("placeholders", ERROR, f"Template placeholders left in the body: {shown}")


def check_footer(report: Report, visible: str) -> None:
    if FOOTER_RE.search(visible):
        report.add("footer", ERROR, "Drop the `Generated with/by Claude Code` footer; Provenance already says who authored the PR.")


def check_redaction(report: Report, raw: str, blocked_domains: list[str]) -> None:
    allowed: set[str] = set()
    for m in ALLOW_RE.finditer(raw):
        allowed.update(x.strip().lower() for x in m.group(1).split(","))
    patterns = dict(REDACTION_PATTERNS)
    for dom in blocked_domains:
        dom = dom.strip().lower()
        if dom:
            patterns[f"domain:{dom}"] = (re.compile(re.escape(dom), re.I), "blocked production domain")
    for pid, (rx, why) in patterns.items():
        if pid in allowed:
            report.add("redaction", INFO, f"`{pid}` findings allowed by `<!-- pr-standard-allow -->`.")
            continue
        hits = [m.group(0) for m in rx.finditer(raw)]
        if hits:
            report.add(
                "redaction", ERROR,
                f"{why} ({pid}) appears {len(hits)}x, e.g. `{mask(hits[0])}`. Redact it before merging.",
            )


def run(body: str, changed_files: list[str], blocked_domains: list[str] | None = None) -> Report:
    report = Report(docs_only=is_docs_only(changed_files))
    visible = strip_comments(body)
    preamble, sections = split_sections(visible)
    check_lede(report, visible, preamble)
    check_demo(report, sections)
    check_test_plan(report, sections)
    check_proof(report, sections)
    check_details(report, visible)
    check_provenance(report, sections)
    check_placeholders(report, visible)
    check_footer(report, visible)
    check_redaction(report, body, blocked_domains or [])
    return report


# --- output ------------------------------------------------------------------
def render_text(report: Report) -> str:
    glyph = {ERROR: "✗", WARN: "!", INFO: "·"}
    lines = [f"{glyph[f.level]} [{f.check}] {f.message}" for f in report.findings]
    n_err, n_warn = len(report.errors), sum(f.level == WARN for f in report.findings)
    verdict = "PASS" if report.ok else "FAIL"
    lines.append(f"{verdict}: {n_err} error(s), {n_warn} warning(s)" + (" [docs-only]" if report.docs_only else ""))
    return "\n".join(lines)


def render_markdown(report: Report) -> str:
    head = "### PR standard: " + ("passed" if report.ok else "failed")
    if report.docs_only:
        head += " (docs-only change)"
    rows = ["| | check | detail |", "|---|---|---|"]
    glyph = {ERROR: "❌", WARN: "⚠️", INFO: "ℹ️"}
    for f in report.findings:
        rows.append(f"| {glyph[f.level]} | {f.check} | {f.message} |")
    if len(rows) == 2:
        rows.append("| ✅ | all | every section present, nothing to redact |")
    tail = "Rules: `.github/PR_STANDARD.md`. Run locally: `python3 .github/scripts/check_pr_standard.py --body body.md --files changed.txt`."
    return "\n".join([head, "", *rows, "", tail, ""])


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--body", required=True, help="file holding the PR description")
    ap.add_argument("--files", help="file listing changed paths, one per line")
    ap.add_argument("--summary", help="write a markdown report here")
    ap.add_argument("--blocked-domains", default=os.environ.get(BLOCKED_DOMAINS_ENV, ""),
                    help=f"comma-separated domains that must not appear (default: ${BLOCKED_DOMAINS_ENV})")
    args = ap.parse_args(argv)

    with open(args.body, encoding="utf-8") as fh:
        body = fh.read()
    changed: list[str] = []
    if args.files:
        with open(args.files, encoding="utf-8") as fh:
            changed = fh.read().splitlines()
    report = run(body, changed, args.blocked_domains.split(","))
    print(render_text(report))
    if args.summary:
        with open(args.summary, "w", encoding="utf-8") as fh:
            fh.write(render_markdown(report))
    return 0 if report.ok else 1


if __name__ == "__main__":
    sys.exit(main())

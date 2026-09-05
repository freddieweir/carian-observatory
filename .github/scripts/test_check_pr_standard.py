"""Self-tests for check_pr_standard.py (stdlib unittest; the workflow runs these first).

    python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v
"""
from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import check_pr_standard as c  # noqa: E402

GOLDEN = """# tracksplit — anchor-continuity segmentation

Takes the scaffold from "never run" to a pipeline that has processed two VODs end to end. 15 commits, each one behaviour change with the test that pins it.

## Demo

![tracksplit demo](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.gif)

_[mp4 with player controls](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.mp4)_
<!-- for an inline player instead: drag the mp4 into this section -->

_Test suite → status → replay from cache. The VOD name and every title are redacted on screen._

## Test Plan

- [x] `uv run --with pytest pytest -q tests` — 26 pass, verified at every commit
- [x] Two multi-hour VODs through `make run`; clips inspected

## Proof (redacted)

<details>
<summary><strong>Replay from cache, no credentials</strong></summary>

```
$ uv run --with pytest pytest -q tests
26 passed in 3.03s
$ make run
[fp] <vod>: 233 queries, 231 hits
        0.0m ->     2.3m  <artist> - <title>  (anchor -1.0m)
        2.3m ->     6.3m  <artist> - <title>  (anchor 2.3m)
        6.3m ->    10.3m  <artist> - <title>  (anchor 6.3m)
       10.3m ->    12.7m  <artist> - <title>  (anchor 10.3m)
       12.7m ->    16.6m  <artist> - <title>  (anchor 12.7m)
       16.6m ->    20.7m  <artist> - <title>  (anchor 16.6m)
       20.7m ->    25.4m  <artist> - <title>  (anchor 20.7m)
       25.4m ->    29.7m  <artist> - <title>  (anchor 25.4m)
       29.7m ->    31.8m  <artist> - <title>  (anchor 29.7m)
       31.8m ->    34.9m  <artist> - <title>  (anchor 31.8m)
       34.9m ->    37.8m  <artist> - <title>  (anchor 34.9m)
       37.8m ->    41.2m  <artist> - <title>  (anchor 37.8m)
       41.2m ->    45.0m  <artist> - <title>  (anchor 41.2m)
[cut] <vod>: 34 clips
```

</details>

<details>
<summary><strong>Full Summary</strong></summary>

- **segment**: rewritten around continuity.

</details>

<details>
<summary><strong>Files</strong></summary>

- `tracksplit/segment.py` — continuity rules

</details>

<details>
<summary><strong>Architecture</strong></summary>

```
vods/<creator>/*.mp4 -> extract -> gate -> fp -> segment -> cut
```

</details>

---

## Provenance

- Opened and authored by @bot; reviewed and merged by the repository owner
- Every commit was tested before it was made
- Demo assets live on prerelease `demo-pr-1`
"""

CODE_FILES = ["tracksplit/segment.py", "tests/test_segment.py"]
DOC_FILES = ["README.md", "docs/guide.md"]


def run(body: str, files=None, domains=None) -> c.Report:
    return c.run(body, CODE_FILES if files is None else files, domains or [])


def errors(report: c.Report) -> set[str]:
    return {f.check for f in report.errors}


class GoldenTests(unittest.TestCase):
    def test_golden_body_passes(self):
        r = run(GOLDEN)
        self.assertTrue(r.ok, c.render_text(r))

    def test_template_itself_fails_on_placeholders(self):
        here = os.path.dirname(os.path.abspath(__file__))
        with open(os.path.join(here, "..", "PULL_REQUEST_TEMPLATE.md"), encoding="utf-8") as fh:
            r = run(fh.read())
        self.assertIn("placeholders", errors(r))

    def test_template_only_fails_on_placeholders(self):
        """Filling every [[placeholder]] with plausible text must satisfy the structural checks."""
        here = os.path.dirname(os.path.abspath(__file__))
        with open(os.path.join(here, "..", "PULL_REQUEST_TEMPLATE.md"), encoding="utf-8") as fh:
            filled = c.PLACEHOLDER_RE.sub("https://github.com/o/r/releases/download/demo-pr-2/x.gif", fh.read())
        filled = filled.replace("x.gif](https://github.com/o/r/releases/download/demo-pr-2/x.gif)_", "x.mp4](https://github.com/o/r/releases/download/demo-pr-2/x.mp4)_")
        r = run(filled)
        self.assertTrue(r.ok, c.render_text(r))


class DemoTests(unittest.TestCase):
    def test_missing_demo_section(self):
        r = run(GOLDEN.replace("## Demo", "## Video"))
        self.assertIn("demo", errors(r))

    def test_demo_without_media(self):
        body = GOLDEN.replace("![tracksplit demo](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.gif)", "")
        body = body.replace("_[mp4 with player controls](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.mp4)_", "")
        self.assertIn("demo", errors(run(body)))

    def test_waiver_with_reason_passes_with_warning(self):
        body = GOLDEN.replace("![tracksplit demo](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.gif)", "**Demo waived:** pure refactor, the CLI output is byte-identical before and after.")
        body = body.replace("_[mp4 with player controls](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.mp4)_", "")
        r = run(body)
        self.assertTrue(r.ok, c.render_text(r))
        self.assertTrue(any(f.check == "demo" and f.level == c.WARN for f in r.findings))

    def test_waiver_without_reason_fails(self):
        body = GOLDEN.replace("![tracksplit demo](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.gif)", "**Demo waived:** n/a")
        body = body.replace("_[mp4 with player controls](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.mp4)_", "")
        self.assertIn("demo", errors(run(body)))

    def test_drag_and_drop_upload_counts_as_media(self):
        body = GOLDEN.replace("![tracksplit demo](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.gif)", "https://github.com/user-attachments/assets/a2415f4f-64a4-41c1-b397-6c11fe1ee7fb")
        body = body.replace("_[mp4 with player controls](https://github.com/o/r/releases/download/demo-pr-1/tracksplit-demo.mp4)_", "")
        self.assertTrue(run(body).ok)

    def test_media_without_caption_fails(self):
        body = GOLDEN.replace("_Test suite → status → replay from cache. The VOD name and every title are redacted on screen._", "")
        self.assertIn("demo", errors(run(body)))

    def test_docs_only_skips_demo_and_proof(self):
        body = GOLDEN.replace("## Demo", "## Was Demo").replace("## Proof (redacted)", "## Was Proof")
        r = run(body, files=DOC_FILES)
        self.assertTrue(r.docs_only)
        self.assertTrue(r.ok, c.render_text(r))

    def test_docs_plus_code_is_not_docs_only(self):
        self.assertFalse(c.is_docs_only(DOC_FILES + ["src/x.py"]))
        self.assertFalse(c.is_docs_only([]))
        self.assertTrue(c.is_docs_only(["LICENSE", ".github/PULL_REQUEST_TEMPLATE.md", "docs/a/b.png"]))


class SectionTests(unittest.TestCase):
    def test_no_h1_or_lede(self):
        body = GOLDEN.replace("# tracksplit — anchor-continuity segmentation\n\nTakes the scaffold", "Takes the scaffold")
        self.assertIn("lede", errors(run(body)))
        body = GOLDEN.replace("Takes the scaffold from \"never run\" to a pipeline that has processed two VODs end to end. 15 commits, each one behaviour change with the test that pins it.", "")
        self.assertIn("lede", errors(run(body)))

    def test_test_plan_needs_checked_item(self):
        body = GOLDEN.replace("- [x]", "- [ ]")
        r = run(body)
        self.assertIn("test-plan", errors(r))

    def test_unchecked_item_only_warns(self):
        body = GOLDEN.replace("- [x] Two multi-hour", "- [ ] Two multi-hour")
        r = run(body)
        self.assertTrue(r.ok)
        self.assertTrue(any(f.check == "test-plan" and f.level == c.WARN for f in r.findings))

    def test_proof_needs_redaction_statement(self):
        body = GOLDEN.replace("## Proof (redacted)", "## Proof")
        self.assertIn("proof", errors(run(body)))
        body = GOLDEN.replace("## Proof (redacted)", "## Proof\n\nNothing to redact: the output is only test counts.")
        self.assertNotIn("proof", errors(run(body)))

    def test_long_proof_block_must_be_collapsed(self):
        body = GOLDEN.replace("<details>\n<summary><strong>Replay from cache, no credentials</strong></summary>\n", "").replace("[cut] <vod>: 34 clips\n```\n\n</details>", "[cut] <vod>: 34 clips\n```\n")
        self.assertIn("proof", errors(run(body)))

    def test_short_proof_block_may_be_inline(self):
        body = GOLDEN.replace("## Proof (redacted)", "## Proof (redacted)\n\n```\n26 passed in 3.03s\n```\n")
        self.assertTrue(run(body).ok, c.render_text(run(body)))

    def test_required_details_sections(self):
        body = GOLDEN.replace("<summary><strong>Full Summary</strong></summary>", "<summary><strong>Summary</strong></summary>")
        self.assertIn("details", errors(run(body)))
        body = GOLDEN.replace("<summary><strong>Files</strong></summary>", "<summary><strong>📁 New Files</strong></summary>")
        self.assertTrue(run(body).ok)

    def test_emoji_summary_labels_are_normalised(self):
        body = GOLDEN.replace("<summary><strong>Full Summary</strong></summary>", "<summary><strong>📋 Full Summary</strong></summary>")
        self.assertTrue(run(body).ok)

    def test_provenance_required(self):
        body = GOLDEN[: GOLDEN.index("## Provenance")]
        self.assertIn("provenance", errors(run(body)))

    def test_headings_inside_code_fences_are_ignored(self):
        body = GOLDEN.replace("[cut] <vod>: 34 clips", "## Provenance\n[cut] <vod>: 34 clips")
        r = run(body)
        self.assertTrue(r.ok, c.render_text(r))

    def test_placeholders_left_behind(self):
        body = GOLDEN.replace("@bot", "[[@who]]")
        self.assertIn("placeholders", errors(run(body)))


class RedactionTests(unittest.TestCase):
    def leaked(self, extra: str) -> c.Report:
        return run(GOLDEN.replace("- Every commit was tested before it was made", f"- {extra}"))

    def test_serial_number(self):
        self.assertIn("redaction", errors(self.leaked("ykman --device 30945664 otp info")))
        self.assertIn("redaction", errors(self.leaked("selected serial 12345678")))
        self.assertNotIn("redaction", errors(self.leaked("selected serial ******64")))

    def test_email_and_home_path(self):
        self.assertIn("redaction", errors(self.leaked("mail me at someone@corp.example.org")))
        self.assertNotIn("redaction", errors(self.leaked("bot <1234+bot@users.noreply.github.com>")))
        self.assertIn("redaction", errors(self.leaked("cd /Users/freddie/git/x")))
        self.assertNotIn("redaction", errors(self.leaked("cd /Users/<you>/git/x and /home/runner/work")))

    def test_ip_mac_and_lan_hosts(self):
        self.assertIn("redaction", errors(self.leaked("bound to 192.168.1.20")))
        self.assertIn("redaction", errors(self.leaked("tailnet 100.101.102.103")))
        self.assertNotIn("redaction", errors(self.leaked("listening on 127.0.0.1 and 0.0.0.0; version 1.2.3")))
        self.assertIn("redaction", errors(self.leaked("nas.local answers")))
        self.assertNotIn("redaction", errors(self.leaked("edit .claude/settings.local.json")))
        self.assertIn("redaction", errors(self.leaked("aa:bb:cc:dd:ee:ff")))

    def test_tokens(self):
        self.assertIn("redaction", errors(self.leaked("ghp_" + "a" * 36)))
        self.assertIn("redaction", errors(self.leaked("sk-ant-api03-" + "x" * 40)))
        self.assertIn("redaction", errors(self.leaked("eyJ" + "a" * 12 + ".eyJ" + "b" * 12 + ".sig")))
        self.assertIn("redaction", errors(self.leaked("-----BEGIN OPENSSH PRIVATE KEY-----")))

    def test_agent_session_url(self):
        self.assertIn("redaction", errors(self.leaked("see https://claude.ai/code/session_01ABCdefGHIjklMNOpqrSTUv")))

    def test_generated_with_footer_rejected(self):
        body = GOLDEN + "\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n"
        self.assertIn("footer", errors(run(body)))
        body = GOLDEN + "\nGenerated with Claude Code\n"
        self.assertIn("footer", errors(run(body)))

    def test_generated_by_footer_rejected(self):
        """The shape a PR-creation tool appends server-side: italic, 'by', a link."""
        body = GOLDEN + "\n---\n_Generated by [Claude Code](https://example.com/)_\n"
        self.assertIn("footer", errors(run(body)))

    def test_blocked_domain_from_env(self):
        body = GOLDEN.replace("@bot", "https://vault.corp-example.com")
        self.assertNotIn("redaction", errors(run(body)))
        self.assertIn("redaction", errors(run(body, domains=["corp-example.com"])))

    def test_leaks_inside_html_comments_still_count(self):
        body = GOLDEN + "\n<!-- serial 87654321 -->\n"
        self.assertIn("redaction", errors(run(body)))

    def test_allow_comment_disables_a_pattern(self):
        body = self.leaked("bound to 192.168.1.20")
        self.assertIn("redaction", errors(body))
        allowed = run(GOLDEN.replace("- Every commit was tested before it was made", "- bound to 192.168.1.20") + "\n<!-- pr-standard-allow: ipv4 -->\n")
        self.assertNotIn("redaction", errors(allowed))

    def test_report_masks_the_sample(self):
        r = self.leaked("ghp_" + "a" * 36)
        text = c.render_text(r) + c.render_markdown(r)
        self.assertNotIn("ghp_" + "a" * 36, text)


class OutputTests(unittest.TestCase):
    def test_markdown_report_shape(self):
        md = c.render_markdown(run(GOLDEN))
        self.assertTrue(md.startswith("### PR standard: passed"))
        self.assertIn("| ✅ | all |", md)
        md = c.render_markdown(run(GOLDEN.replace("## Demo", "## Nope")))
        self.assertTrue(md.startswith("### PR standard: failed"))
        self.assertIn("| ❌ | demo |", md)


if __name__ == "__main__":
    unittest.main()

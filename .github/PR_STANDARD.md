# Pull request standard

Every pull request in this repository is written to one shape, the shape of
[tracksplit PR #1](https://github.com/freddieweir/tracksplit/pull/1). The
reviewer should be able to see the change run, see the real output that proves
it, and drill into detail only when they choose to. Nothing private reaches the
page. `.github/PULL_REQUEST_TEMPLATE.md` pre-fills the shape; the **PR Standard**
workflow checks every PR body against the rules below and reports what is
missing as a sticky comment and a job summary.

## The shape

```
# repo — one line saying what the PR does
One-paragraph lede: from where to where, how many commits, the one-line proof.

## Demo                       GIF (autoplays) + mp4 (player controls) + one-line caption
## <domain table>             optional: rules, levels, behaviour, before/after
## Test Plan                  checked boxes, command in backticks, result after the dash
## Proof (redacted)           real terminal output, collapsed in <details>
<details> Full Summary        what changed, by area, with the why
<details> Files               each path and what it now does
<details> Architecture        optional: ascii diagram of the flow this PR touches
---
## Provenance                 who authored, who reviewed, how commits were tested, where assets live
```

Headings can carry an emoji prefix (`📋 Full Summary`); the check ignores it.

## Section rules

**Title and lede.** The body starts with an H1 and one paragraph of prose
before the first `##`. The paragraph says where the branch takes the project,
not what files it touches.

**Demo.** Required for any PR that changes code. Two assets: a GIF that plays
inline in the PR page and an mp4 with player controls for anyone who wants to
pause. One italic caption says what happens on screen and what was redacted.
Produce and host them with `scripts/publish-demo.sh <PR> recording.mp4`, which
converts the recording and uploads both files to a prerelease tag `demo-pr-<N>`
(marked "Not a software release"), then prints the two markdown lines. Dragging
the mp4 into the editor also works: GitHub hosts it and renders an inline player.

Exceptions to the demo, both visible to the reviewer:

- A PR that only touches docs (`*.md`, `docs/`, `LICENSE`, templates) skips the
  demo and the proof automatically; the check says so in its report.
- Anything else that genuinely has nothing to show replaces the media with one
  line, `**Demo waived:** <reason>`, where the reason is a real sentence. The
  check passes with a warning that quotes the reason, so the waiver is on record.

**Test Plan.** A checked box is something that was actually run, with the
command in backticks and the result after it. Unchecked boxes are allowed only
with the reason on the same line; the check warns about each one.

**Proof (redacted).** Real terminal output that proves the Test Plan, pasted
into a fenced block inside `<details><summary><strong>What this proves</strong>`.
Blocks longer than 15 lines must be collapsed; a short one may sit inline. The
heading keeps "(redacted)" so the reader knows the output was scrubbed; if
there was truly nothing to scrub, write "nothing to redact" in the section.

**Full Summary, Files, Architecture.** Collapsed `<details>` blocks. The first
two are required. Architecture is for when the shape of the system changed and
an ascii diagram of the touched flow tells the reader where the change sits.

**Provenance.** Who opened and authored the PR (a bot account counts), who
reviewed and merged it, how each commit was tested before it was made, and
where the demo assets live so they can be regenerated. This is the only place
the authoring tool is named: no `Generated with …` footer after it, and no
session link anywhere in the body. The check fails on both.

## Redaction

Redact on screen before recording and in text before pasting. A GIF cannot be
withdrawn from the browser cache of everyone who opened the PR. Replace, do not
delete: `<vod>`, `<artist> - <title>`, `<host>`, `/Users/<you>`, `******64` keep
the output readable and prove the shape of what ran.

Always redacted: real names and titles of private media, hostnames and LAN
addresses, home directories with a user name, hardware serial numbers, email
addresses, tokens and keys, any production domain. Times, counts, hashes of
public data, test names and version numbers stay real: they are the evidence.

The check scans the whole body, HTML comments included, for these patterns and
fails on any hit, reporting only a masked prefix so the report cannot leak:

| id | catches |
|---|---|
| `email` | any address except `noreply` and `example.` domains |
| `home-path` | `/Users/<name>` or `/home/<name>` other than `runner`, `user`, `<...>` |
| `ipv4` | any address except loopback, `0.0.0.0` and broadcast |
| `mac` | `aa:bb:cc:dd:ee:ff` |
| `lan-host` | `*.local`, `*.lan`, `*.internal`, `*.home.arpa` (not `settings.local.json`) |
| `serial` | 6 to 10 digits after `serial` or `--device` |
| `api-key` | Anthropic, OpenAI, GitHub, AWS and Slack token shapes |
| `jwt`, `private-key` | `eyJ…eyJ` pairs and `BEGIN … PRIVATE KEY` |
| `session-url` | `claude.ai/code/session_…` links; the tool is named in Provenance, the session stays private |
| `domain:<d>` | each domain in the `PRODUCTION_DOMAIN` repository variable |

A pattern with a legitimate hit (a public IP in a docs example, say) can be
switched off for one PR with `<!-- pr-standard-allow: ipv4 -->` anywhere in
the body. The report lists the allowance, so the reviewer sees it.

## Enforcement

`.github/workflows/pr-standard.yml` runs on `opened`, `edited`, `reopened`,
`synchronize` and `ready_for_review`, so fixing the description re-runs the
check without a push. It first runs the checker's own unit tests, then feeds
the checker the PR body and the list of changed files. The result lands in the
job summary and, for same-repo PRs that are not drafts, in one comment on the
PR that is updated in place on every run. A failing body fails the check.

To make the standard blocking, add the check `PR Standard / body` to the
required status checks in the branch ruleset for `main`
(Settings → Rules → Rulesets → require status checks to pass).

Run the same check before opening a PR:

```
git diff --name-only origin/main...HEAD > /tmp/changed.txt
python3 .github/scripts/check_pr_standard.py --body /tmp/pr-body.md --files /tmp/changed.txt
```

`check_pr_standard.py` and its tests are standard-library Python, so they run
identically on a laptop, in Actions, and in an agent sandbox.

## For agents

An agent opening a PR here writes the body from `.github/PULL_REQUEST_TEMPLATE.md`,
replaces every `[[placeholder]]`, records and publishes a demo with
`scripts/publish-demo.sh` when it can, and otherwise states the waiver reason
honestly. It names itself once, in Provenance, and appends no attribution
footer and no session link: the body and the commit messages carry nothing
that identifies a private session. It runs the checker on the drafted body and fixes every error before
the PR is opened. `CLAUDE.md` in the repository root repeats this in short.

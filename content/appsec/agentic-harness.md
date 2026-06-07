+++
title = "The Missing Layer"
date = "2026-05-31"
toc = true
aliases = ["appsec"]
tags = ["ai"]
categories = ["security", "software", "dev"]
[ author ]
  name = "onereddog"
+++

# The Missing Layer: Why Claude Code Needs a Harness

I recently took part in a company hackathon. A colleague had an idea, so I built the app: native Swift for iPhone, one day, with an agent doing the heavy lifting. The app worked, the demo impressed the judges. We didn't win. That's not the point.

The point is that the capability is real. You can ship something that works, fast, with an agent handling most of the implementation, following sound engineering principles. What we always did (describe the problem, write the code, run it, repeat) now happens at a speed and scale that wasn't possible two years ago.

There is a demo version of agentic coding and a production version. The demo is impressive. You describe a feature, the agent opens files, writes code, runs tests, and commits, all while you watch. It feels like the future.

The production version is messier. The agent writes capable code, but it skips the plan step because you didn't explicitly require one. It formats inconsistently because nothing enforced a formatter. It commits directly to main because nobody told it not to. It opens a PR without a security review because that wasn't in its instructions. Six weeks later, a human engineer inherits a codebase that works but that nobody can confidently change.

This is not a failure of the model. Claude Code, Codex, and their peers are genuinely capable of production-quality output. Writing the code was never the bottleneck. The failure is architectural: there is no process layer between the model's raw capability and your codebase. The missing piece is a harness.

---

## What a Harness Is Not

A harness is not a system prompt. It is not a README asking the agent to please write clean code. It is not a list of coding conventions the agent will skim and then ignore when it is in the middle of implementing something.

A harness is an operating manual that the agent treats as authoritative: a structured set of workflow rules, quality gates, and skill definitions that the agent follows as a process, not as suggestions. The distinction matters because suggestion-following is fragile under pressure. When an agent is mid-implementation and the fastest path forward involves skipping a step, it will skip the step unless that step is encoded as a gate it cannot pass through.

The AGENTS.md and CLAUDE.md files that agentic tools load at session start are the surface where this process layer lives. Used naively, they are documentation. Used deliberately, they are an enforcement mechanism.

---

## The Gates That Actually Matter

Not every possible rule deserves to be a gate. The ones that matter are the ones that prevent the categories of failure that compound: the mistakes that are cheap to catch at commit time and expensive to find in production.

**Plan before code.** The agent must propose a design: the files to add or modify, the public API surface, the risks. Then wait for explicit approval before writing a single line. This sounds bureaucratic. In practice it prevents the most common agentic failure mode: a confident, fast implementation of the wrong thing. A two-minute plan review is cheaper than a two-hour refactor.

**Format and lint before every commit.** Not as a reminder. As a gate that halts the workflow on violation. The agent runs the formatter, runs the linter, and does not proceed if either fails. No more than three fix loops. After that, it surfaces the problem to the human rather than suppressing it. This keeps the diff readable and keeps style debt from accumulating silently.

**Test with coverage before every commit.** The agent runs the full test suite after every implementation cycle. An 80% line coverage threshold is enforced as a gate, not a warning. If tests fail or coverage falls short, the workflow stops. When coverage misses, the agent doesn't just report a number: it identifies the modified files, names the uncovered line ranges, and proposes specific test cases for each gap. Coverage failures surface as a concrete list of work rather than a threshold to quietly lower.

**Code review before commit to main.** The agent reviews its own staged changes looking for blocking issues, things that should be fixed, and nits before committing. This catches the class of bugs that are obvious in review and invisible during implementation: missing error handling, inconsistent naming, logic that works in the happy path but not at the edges. Automated review is not a replacement for human review; it is a filter that makes human review faster.

**Security review before any PR.** The agent diffs the branch against main and evaluates the delta for security findings, rated by severity. Critical and high findings halt the workflow. The human must address them before the PR opens. This is the gate most teams skip and most regret skipping.

**Explicit staging only.** The agent uses `git add <file>` with specific paths. `git add -A` and `git add .` are denied at the settings level. This sounds minor. It eliminates the entire class of accidental commits: credentials in environment files, build artefacts, unrelated changes picked up from the working directory.

---

## Skills, Not Prompts

The workflow units in a harness are skills: discrete, loadable instruction sets that the agent reads when a task matches their description and follows exactly. A skill is not a prompt appended to the conversation. It is a local file the agent opens, reads, and treats as authoritative for that task.

The difference in practice: a prompt is interpreted. A skill is followed. When the commit skill says "run lint, if violations fix them, maximum three loops then escalate," the agent does exactly that, in that order, every time. There is no interpretation drift, no optimistic skipping of steps that seem unnecessary in context.

Skills also compose. The implement skill calls the code review skill. The PR skill calls the security review skill. The result is a workflow that is both end-to-end and auditable. Every step is documented, every gate is visible, and a human can read the skill files to understand exactly what the agent did and why.

---

## This Generalises

The harness concept is not specific to one language or one agent. The same philosophy applies across stacks: operating manual, quality gates, skill-based workflow units, conventional commits, explicit staging. The implementation details vary by language toolchain: `swift-format` and `xcodegen` for Swift, `rustfmt` and `clippy` for Rust, `ruff` for Python. The agent format varies too: slash commands for Claude Code, skill files for Codex and OpenCode-compatible agents.

What does not vary is the structure of the loop: design, story, implement, format, test, review, commit, PR. Each step is defined. Each transition has a gate. The agent moves through the loop as a disciplined process, not as a sequence of best-effort attempts.

This matters for teams evaluating agentic tools. The question is not whether the model can write code. It can. The question is whether you can build a reliable, repeatable development process on top of it. A harness is how you answer yes to that question.

---

## What You Get

A codebase built with a harness looks different from one built without. The commit history is clean and conventional. Each commit has a type, a scope, and a subject. The diff is small and intentional, with no accidental files and no unrelated changes. The PR description is structured: summary, test plan, security notes. The code has been reviewed, the security surface has been checked, and the tests pass.

More importantly: a human engineer can take over. The process is documented in the agent files. The architecture is captured in ARCHITECTURE.md. The decisions are in the ADR log. The stories are in version-controlled markdown files with acceptance criteria and task lists. Nothing lives only in the agent's context.

This is what production-quality agentic output looks like. Not just correct code, but correct code delivered through a process that a team can trust, audit, and extend.

---

## Where to Start

The agentic-harness repository contains ready-to-install harnesses for Python, Rust, and Swift, targeting both Claude Code and Codex-compatible agents including OpenCode. Each harness installs with a single shell script and comes with the full skill set: design, story, kanban, implement, commit, review, security-review, PR.

The install script detects existing files and backs them up. The AGENTS.md and CLAUDE.md files have `CUSTOMIZE:` markers for the project-specific values you need to fill in. Everything else is ready to use.

If you are evaluating agentic coding tools for your team and finding that raw capability is not enough, that the tools produce good code but not a good process, the harness is the layer you are missing.

→ [github.com/0x1337c0d3/agentic-harness](https://github.com/0x1337c0d3/agentic-harness)

The agent doesn't change what good software is. It just makes the distance between good design and bad design visible immediately.

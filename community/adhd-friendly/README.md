# ADHD-Friendly Rule Pack

Helps you stay focused and reduce cognitive load when working with Claude Code.

These rules are not clinical advice. They are practical guardrails that keep AI output clean, scannable, and action-oriented -- reducing the mental overhead of context-switching, visual noise, and decision fatigue.

## Rules (7)

| Rule | What It Does |
|------|-------------|
| minimize-sprawl.md | Version files instead of overwriting. One file per concern. Single source of truth. |
| ascii-only.md | No emojis or special characters. Consistent, scannable output. |
| drive-velocity.md | Keep momentum. Present next action immediately after completing a task. |
| highest-value-first.md | Always recommend the highest-leverage work first. |
| single-line-commands.md | No multi-line shell commands. Each step on its own line. |
| context-switching.md | Verify paths before presenting. Include descriptions. Fewer references. |
| ship-over-perfect.md | Define a quality bar, enforce it, ship. Do not wait for perfection. |

## Who This Is For

Anyone who loses focus when AI output is noisy, sprawling, or indecisive. Works well for ADHD, but useful for anyone who values clean, direct AI behavior.

## How to Use

Copy individual files to `~/.claude/rules/` (global) or `<repo>/.claude/rules/` (per-project). Edit to taste.

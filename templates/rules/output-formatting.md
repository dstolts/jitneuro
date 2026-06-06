---
type: rule
purpose: Mandate ASCII-only output, prohibit long URLs in chat, ban line-wrapping in markdown, and require single-line shell commands so output renders correctly across all surfaces.
tags: [output-formatting, ascii, markdown, shell-commands, readability]
scope: public
departments: [all]
read_when: Before generating any chat response, markdown document, or content that flows through an automated pipeline.
last_evaluated: 2026-06-03
---
# Output Formatting

## No Long URLs in Chat

Never put long URLs (>80 chars) in chat responses. Chat formatting adds whitespace that
breaks links.

Put URLs in a markdown file and reference the file path instead. Or shorten the URL to a
path-only reference when the base domain is already established in context.

## ASCII Only

Use ASCII characters only in generated content that flows through automated pipelines
(CMS, APIs, emails, webhooks). Add ASCII sanitization at the output boundary of any
pipeline that publishes AI-generated content.

In chat responses: no emojis, no special Unicode characters unless explicitly requested.

## No Line Wrapping

Do not wrap long lines in markdown or code. Add new lines instead of wrapping mid-sentence
or mid-value. Wrapped lines break in some terminals and editors.

## Single-Line Commands

When providing shell commands to a user: present each step as a separate single-line command.
Never give multi-line commands. Wrapped lines break in interactive terminals.

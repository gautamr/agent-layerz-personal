# Token budget

Agentic work costs more than chat: Anthropic measured agents at about 4 times the tokens of a
chat, and multi-agent systems at about 15 times. Spend where it pays.

## Keep always-loaded context small
- Composed instructions stay within the layer budget (`instructions_max_lines`). Procedures
  move into skills, which load only when used; area conventions into path rules.
- Do not churn always-loaded files: stable text is cached, every edit makes the next sessions
  pay full price.

## Size each session
- One task per session. Start fresh rather than continuing a long session.
- Read files by path and line range. Search with grep before opening files.
- Pass file paths between agents, never pasted content.

## Use agents deliberately
- A subagent protects the main context (research, reviews) or isolates parallel writers.
  Otherwise work in the main session.
- Strongest model for decisions that are expensive to reverse; a mid-tier model for
  implementation checked by tests; a small model for scouting, summaries and formatting.
  Models come from the layer's role routing (`models.yaml`), not from agent files.
- Run only the review lenses a change needs: no design review for backend-only changes;
  security review for login, payments, personal data, webhooks or dependencies.
- Several sessions at once only for parallel research or multi-lens review, never by default.

## Keep tools lean
- Enable only the MCP servers a project needs (`mcp.enable`).
- Prefer a CLI the agent already knows (git, gh, backlog) over an MCP server that duplicates it.

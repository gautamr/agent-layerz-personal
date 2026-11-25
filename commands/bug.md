---
description: File a bug on the board in Triage, with steps, expected and actual result.
argument_hint: "\"<what is wrong>\""
---
File a bug for: $ARGUMENTS

Follow bug-triage §4. Ask for anything missing among steps, expected result (and the contract
it comes from) and actual result. Set type `bug`, status `Triage`, this repository's project and
the milestone it affects. Add `severity:S1` only if it is clearly critical, and then tell the
owner. Return the new task ID.

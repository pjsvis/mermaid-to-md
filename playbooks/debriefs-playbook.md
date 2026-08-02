# Playbook: debriefs/

## Purpose

Post-project reflections. Capture what was built, what worked, what didn't, and what we'd do differently. Debriefs are the institutional memory of the project.

## Format

Filename: `NNN-short-slug.md` — matches the brief filename.

```markdown
# Debrief: NNN — Project Title

**Date:** YYYY-MM-DD
**Status:** Complete
**TD Epic:** td-xxxxx (if applicable)

## What we built
One paragraph.

## Architecture decisions that worked
Bullet list with reasoning.

## Things we'd do differently
Honest assessment of mistakes and trade-offs.

## Design principles validated
Which principles held up under implementation.

## Files changed
Table: file, lines, purpose.

## Next steps
What's left undone.
```

## Conventions

- Write the debrief immediately after the project completes, while the details are fresh
- Be honest about mistakes — a debrief that says "everything went perfectly" is useless
- Link back to the brief and any TD issues
- Debriefs are **final** — append dated addenda if new information emerges, don't edit the original

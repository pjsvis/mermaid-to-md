ts # paint, discuss, persist

**Captured:** 2026-07-25
**Origin:** a conversation — distils the practice cycle that `decisions/001` and the discuss playbook each address in part
**Siblings:** `decisions/001` (the positioning call), `playbooks/diagrams-for-agent-human-discussion.md` (the discuss beat, in mechanics), `docs/the-case-for-baked-diagrams.md` (the substrate argument)

## The cycle

The practice has three beats:

1. **Paint.** Draw the first diagram with the agent. It does not need to be right; it needs to portray some part of the process.
2. **Discuss.** Let the diagram's formality surface the gaps — the missing state, the unjustified edge, the terminal that isn't there. Prose hedges; a state diagram commits.
3. **Persist.** Bake the diagram into the markdown next to the code, so the discussion's gains survive the turn boundary and the months.

The positioning decision names the middle beat ("state diagrams for agent–human discussion"). The playbook is the mechanics of the middle beat. Neither foregrounds the cycle, and neither names the third beat as the load-bearing one. This does.

## Why persist is the load-bearing beat

Painting and discussing are engaging — creation, then discovery. Persisting is bookkeeping. In the agent–human loop specifically, the turn boundary is where un-recorded things die (see `playbooks/elision-and-deferral.md`: *a deferred decision not written down dies at the boundary*). So the persist beat gets dropped not from laziness but from the loop's structure: it is the unglamorous step at exactly the point where the loop is built to shed load.

A diagram discussed and not persisted surfaces its gaps once, at design time, then evaporates. A diagram persisted — baked, diffable, re-readable, co-located — surfaces them repeatedly, over the life of the system. Persistence converts a one-time forcing function into a recurring one. (The state-diagram-specific case for that compounding is made in `docs/the-case-for-baked-diagrams.md`.) That conversion is the whole point.

## Why the fix is structural, not exhortational

"Persist the picture" is obvious — obvious enough to be George Costanza-endorsed. That is exactly why stating it will not make it happen. Obvious-but-unpracticed is the signature of an incentive problem, not an insight problem: everyone agrees you should persist; almost nobody does it at the moment it matters, because that moment is the one where you're tired of the diagram and want to move on.

The fix is not to remind people to persist. The fix is to make persistence the path of least resistance — the thing that happens when you do the natural thing, rather than an act of discipline layered on top. Bake the art into the substrate; keep the source as a handle; verify freshness in CI. Then "persist the picture" is not a slogan anyone has to remember; it is the default shape of the artifact. Exhortation is replaced by engineering. That is what the tool is for.

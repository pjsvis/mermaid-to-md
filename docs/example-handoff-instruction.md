# handoff instruction from agent to human

 Next move (the phased new-up boundary)

 This session's bounded job was orientation + scaffolding — done. Phase 1
 implementation is the next newup:

 ```
   /new
   td start td-774a89        # Phase 1 — bash trailing-newline fix + test
   ... implement, just test ...
   td handoff td-774a89      # 4 fields: done/remaining/decisions/uncertain
   td review td-774a89
 ```

 Phase 1's description already flags the one thing worth carrying forward: the JS
 wrapper is verified-correct, so the fix is bash-only — no inherited assumption left
 latent. Ready when you are.
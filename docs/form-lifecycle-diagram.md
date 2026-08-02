You’ve hit on the exact reason why state machines beat big-picture topology frameworks when you're down in the trenches actually building software.

A form isn't just a static layout of inputs—it's a multi-step workflow with edge cases, persistence boundaries, and dynamic validation. The moment you introduce **asynchronous boundaries** (like reading/writing to `localStorage`) and **resumable sessions** (leaving and returning), treating the UI as a state machine isn't just helpful—it’s mandatory to prevent edge-case hell.

---

## Why the State Diagram Approach Wins Here

Without a state machine, form logic usually devolves into a tangle of implicit flags (`isSubmitting`, `isDraftLoaded`, `hasValidationError`, `isDirty`).

Mapping this out as a explicit state machine gives both you and an LLM agent a deterministic blueprint:

1. **Explicit Edge Cases:** What happens if `localStorage` contains corrupted JSON on mount? What if the user submits while a background draft save is in flight? A state machine forces you to define transitions for `DRAFT_CORRUPTED` or `SAVE_IN_FLIGHT` before writing code.
2. **Deterministic Context:** The agent can look at the current state (`RestoringDraft`, `FormDirty`, `Submitting`, `Error`) and know *exactly* which inputs are enabled, which buttons are visible, and what side effects (I/O operations) are allowed.
3. **Zero Mental Overhead:** Converting this logic into a Mermaid state diagram embedded in Markdown gives both human and agent a 1:1 map of the execution path.

---

## Example: Form Lifecycle State Diagram

The original diagram used Mermaid composite states (`state X { ... }`) to
nest the internals of `Initializing` and `FormActive` inside a single
block. Our renderer doesn't support composite states — and per the split
lesson, a diagram the renderer can't handle is a diagram trying to be two
(or three) diagrams. The composite states are sub-systems; the right move
is to split by sub-system, not by routing.

The three diagrams below are the split: the top-level lifecycle, then the
internal states of `Initializing` and `FormActive` as detail views. Each
renders cleanly as Unicode box-drawing art, baked in at authoring time.

### Top-level lifecycle

<!-- mermaid-to-md:art -->
```text
                         ╭───╮
                         │ ● │
                         ╰─┬─╯
                           │
                           ▼
                   ╭──────────────╮
                   │ Initializing │
                   ╰───────┬──────╯
                           │
                           ▼DraftLoaded / FormReady
                    ╭────────────╮                    Retry / Fix Inputs
                    │ FormActive │◄──────────────────────────────────────┐
                    ╰──────┬┬────╯                                       │
                           ││   ▲  Validation Failed                     │
                           │╰───╯                                        │
                           │                                             │
                           ▼Validation Passed                            │
                    ╭────────────╮                                       │
                    │ Submitting │                                       │
                    ╰──────┬─────╯                                       │
                  ┌────────┴────────┐                                    │
                  ▼API 200 OK       ▼API Error / Network                 │
             ╭─────────╮   ╭─────────────────╮                           │
             │ Success │   │ SubmissionError ├───────────────────────────┘
             ╰────┬────╯   ╰─────────────────╯
                  │
                  ▼
         ╭─────────────────╮
         │ ClearingStorage │
         ╰────────┬────────╯
                  │
                  ▼Redirect / Reset
                ╭───╮
                │ ● │
                ╰───╯
```

```mmd
stateDiagram-v2
    [*] --> Initializing
    Initializing --> FormActive: DraftLoaded / FormReady
    FormActive --> Submitting: Validation Passed
    FormActive --> FormActive: Validation Failed
    Submitting --> Success: API 200 OK
    Submitting --> SubmissionError: API Error / Network
    SubmissionError --> FormActive: Retry / Fix Inputs
    Success --> ClearingStorage
    ClearingStorage --> [*]: Redirect / Reset
```

### Initializing — internal states

<!-- mermaid-to-md:art -->
```text
             ╭───╮
             │ ● │
             ╰─┬─╯
               │
               ▼
   ╭──────────────────────╮
   │ CheckingLocalStorage │
   ╰───────────┬──────────╯
       ┌───────┴────────┐
       ▼Valid JSON      ▼No data / corrupt
╭────────────╮    ╭───────────╮
│ DraftFound │    │ EmptyForm │
╰──────┬─────╯    ╰─────┬─────╯
       └───────┬────────┘
               ▼
             ╭───╮
             │ ● │
             ╰───╯
```

```mmd
stateDiagram-v2
    [*] --> CheckingLocalStorage
    CheckingLocalStorage --> DraftFound: Valid JSON
    CheckingLocalStorage --> EmptyForm: No data / corrupt
    DraftFound --> [*]
    EmptyForm --> [*]
```

### FormActive — internal states

<!-- mermaid-to-md:art -->
```text
                ╭───╮
                │ ● │
                ╰─┬─╯
                  │
                  ▼
              ╭──────╮              Persisted to localStorage
              │ Idle │◄───────────────────────────────────────┐
              ╰───┬──╯                                        │
                  │                                           │
                  ▼User Input                                 │
             ╭─────────╮                                      │
             │ Editing │                                      │
             ╰────┬────╯                                      │
         ┌────────┴─────────┐                                 │
         ▼Field Change      ▼User Clicks Submit               │
╭────────────────╮    ╭───────────╮                           │
│ DebouncingSave ├────│ Validated │───────────────────────────┘
╰────────────────╯    ╰─────┬─────╯
                            │
                            ▼Validation Passed
                          ╭───╮
                          │ ● │
                          ╰───╯
```

```mmd
stateDiagram-v2
    [*] --> Idle
    Idle --> Editing: User Input
    Editing --> DebouncingSave: Field Change
    DebouncingSave --> Idle: Persisted to localStorage
    Editing --> Validated: User Clicks Submit
    Validated --> [*]: Validation Passed
```

---

## Operational Assessment

If you pass a diagram like the one above to an AI agent via your Rust CLI markdown pipeline:

* **The Agent’s Role:** It doesn't have to guess how the form behaves. It can literally match system actions to state transitions (e.g., *"On entering `DebouncingSave`, invoke `localStorage.setItem` with current form schema"*).
* **Code Generation:** The agent can map this cleanly to a robust implementation—whether using `XState`, a lightweight custom `useReducer` in React, or a Rust-backed state handler—without leaking state or creating impossible UI combinations (like submitting while a draft is restoring).
* **Test Case Engine:** The Mermaid diagram double-hats as your test spec. Each transition arrow (`CheckingLocalStorage --> DraftFound`) represents an explicit test case to write.

For something like a multi-step, draft-persisting form, skipping the formal state machine is usually how bugs get introduced. Modeling it inline in text keeps the developer and the agent aligned on the exact same logic.

---

## A note on viewers: Zed and the live-render tradition

Zed has a neat Mermaid display system — its markdown preview renders
`​```mermaid` blocks live, in-editor, without a plugin. It's the best
live-render experience in a code editor today. VS Code needs an extension;
GitHub needs the web preview; Zed just does it.

This tool plays a different move. Zed renders at *view time* inside one
editor; `mermaid-to-md` renders at *authoring time* and ships the art as
static text visible in *any* viewer — Glow, `cat`, GitHub web, an email
client, a terminal pager. The baked art is a cache; the `​```mmd` source
is the regeneration handle. You don't need Zed to read a baked diagram,
the way you need Zed (or a browser, or a plugin) to read a live one.

The two approaches are complementary, not competitive. If you live in Zed
and never leave, live render is the better experience. If your diagram
needs to survive outside one editor — in a PR review, a terminal session,
an agent's context window, a plain-text email — bake it. The `​```mmd`
convention (not `​```mermaid`) means GitHub renders the source as plain
text, not a second live diagram, so the baked art is the single source of
truth for the visual.

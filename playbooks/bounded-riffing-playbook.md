# Playbook: Bounded Riffing with Live State Machines

## Purpose
A repeatable protocol for human-agent collaborative system design using live ASCII state machine visualization to bound exploratory discussion, eliminate phantom states, and produce deterministic specifications.

## Context & Prerequisites
* **Environment:** Split terminal layout (e.g., via `herdr` or multiplexer).
  * **Left Pane:** Interactive AI coding agent (e.g., Pi).
  * **Right Pane:** Live markdown viewer running in watch mode (`mdview --watch <artifact>.md`).
* **Tooling:** SpaceX Rust ASCII Mermaid CLI integrated into the live viewer.
* **Target Artifact:** A working markdown file (e.g., `specs/NNN-topic-spec.md` or a design brief) containing prose and Mermaid state diagrams.

## The Protocol (The "How-To")

1. **Seed the Scaffold:**
   * Direct the agent to initialize the target markdown file with an exploratory 3–5 state Mermaid diagram (`stateDiagram-v2`) and minimal narrative context.
   * *Rule:* Never start with code or deep prose. Anchor the control plane first.

2. **Visual Complexity Check (The Layout Heuristic):**
   * Inspect the live-rendered ASCII diagram in the right pane.
   * If the diagram is messy, contains crossing lines, or exceeds horizontal bounds, halt narrative design.
   * Direct the agent to refactor and decompose the macro-topology before continuing.

3. **Audit via Exhaustion:**
   * Systematically evaluate the diagram against three invariants:
     * **Dead Ends:** Every state must have an explicit exit transition or explicit terminal end state (`[*]`).
     * **Implicit Logic:** Ensure no complex computation is hidden across transitions; state work must belong to named states.
     * **Error Handling:** Every non-terminal state must handle failure or timeout events.

4. **Explode or Refactor:**
   * When edge cases or hidden complexity arise in a single state, instruct the agent to "explode" that node into an independent nested or child state machine.
   * Update the surrounding explanatory prose directly below the diagram.

5. **Freeze & Spec:**
   * When the ASCII diagram stabilizes and satisfies all exhaustion checks, commit the markdown artifact.
   * Transition the discussion to code generation, using the finalized state transitions as strict guardrails.

## Standards & Patterns
* **Diagram Simplicity:** Keep single diagrams under 8 distinct states. If more are needed, decompose into sub-machines.
* **Semantic Terminal Spacing:** Enforce loose lists and soft returns in notes accompanying diagrams to keep terminal text readable.
* **Live Invariant:** The right pane must reflect only the current state of the document. Do not discuss states in chat that are not reflected in the working artifact.

## Validation
* The target markdown artifact renders cleanly via ASCII without horizontal overflow.
* The state machine passes exhaustion (no unhandled transitions or orphan nodes).
* Implementation code directly implements the explicit states, events, and guards specified in the diagram.
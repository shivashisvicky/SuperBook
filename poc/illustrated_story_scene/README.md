# SuperBook Illustrated Story Scene POC

This POC moves the AI-directed puppet experiment toward the supplied 2D cartoon-story reference.

## Visual direction

- painted/illustrated room rather than geometric stage primitives
- outlined articulated characters
- semantic character groups for head, torso, arms and legs
- props and environment participate in the scene
- limited animation: enter, talk, gesture, eat, listen, idle
- deterministic local runtime; zero per-frame AI

## AI/runtime contract

The fixture `aiPlan` supplies:

- scene intent
- action timeline
- targets
- object references
- camera intent

The browser executes the timeline locally.

## Deliberate limitation

This is still a runtime/animation proof, not the final SuperBook art pipeline. The next quality jump should replace the hand-authored fixture artwork with reusable generated/commissioned character and environment assets that follow the same semantic layer contract.


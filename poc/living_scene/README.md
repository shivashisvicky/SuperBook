# SuperBook Living Scene POC

This is an isolated, browser-only proof of the animation architecture researched for SuperBook.

## What it proves

- A scene can be built from layered parts rather than a baked video.
- Characters have explicit pivots and independently animated head/arm layers.
- Breathing and blinking are local runtime effects.
- Gesture and reaction states are parameter-driven.
- A short narrative timeline can sequence multiple acting beats and camera motion.
- The runtime performs animation locally. There is **zero AI inference per frame**.
- There are no external assets, API calls, Cloudflare bindings, R2 objects, paid services, or changes to the reader.

The visual characters are intentionally simple vector stand-ins. They are a rig/runtime test fixture, not the intended SuperBook art style.

## Modes

- **Idle**: breathing + blinking.
- **Glance**: both characters shift attention independently.
- **Gesture**: the left character raises an arm with spring-like settling.
- **Reaction**: the right character reacts.
- **Play scene**: a deterministic six-second narrative sequence combines glance, gesture, reaction, settle, and a subtle camera move.

## Next integration gate

Do not wire this POC into the TEST reader yet.

The next step is to replace the vector fixture with one real generated literary scene asset and prove that the same runtime model can operate on real separated layers without visible tearing or identity drift. Only after that visual gate should this become a SuperBook reader feature.

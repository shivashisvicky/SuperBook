# SuperBook Puppet Runtime Foundation

This is the technical foundation for the next visual POC. It deliberately does **not** reuse the pixelated 709×890 scene as a character source.

## Contract

AI supplies an **asset manifest**, not animation frames:

- background plate
- character identity
- semantic parts: head, torso, upper/lower arms, hands, legs
- pivot points
- neutral pose
- supported actions
- optional expression layers

The browser owns the timeline and continuously interpolates those parts.

## Animation rule

No per-frame AI. No three-image slideshow. No camera movement presented as acting.

AI may create or edit the artwork when an asset is first prepared. Runtime motion is deterministic.

## Target story test

One illustrated room:

1. character enters
2. walks to the table
3. sits / settles
4. talks
5. reaches for food
6. eats
7. reacts/listens
8. idles

The quality gate is **continuous character motion over a detailed illustrated environment**.

The old scene plate is retained only as historical POC material and is not the target asset pipeline.

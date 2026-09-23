# SuperBook Cinematic Illustrated Scene POC

This POC uses the real illustrated scene asset supplied for SuperBook and focuses on cinematic presentation rather than vector character construction.

- embedded illustrated background plate
- independently animated extracted head/hand details
- local camera drift and restrained zoom
- warm lighting pulse, dust/atmosphere, vignette
- four local acting states: scene, conversation, reaction, idle
- zero per-frame AI

This is a visual/runtime gate, isolated from the application TEST branch. The next pipeline step is to replace the extracted details with a proper semantic character rig so larger actions such as walking, sitting and interacting with props can be authored without degrading the source artwork.

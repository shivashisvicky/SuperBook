# SuperBook AI Experience TEST Handoff

**Status date:** 2026-09-28 IST  
**Authoritative branch:** \`test/superbook-ai-scene-foundation\`  
**Repository:** \`shivashisvicky/SuperBook\`  
**Stable branch:** \`main\`  
**PR:** #2, AI Experience scene planning / generated visual foundation  
**TEST Pages:** https://shivashisvicky.github.io/SuperBook/test/?v=f6b1baa8  
**AI Worker:** \`superbook-ai-scene\`  
**Worker URL:** https://superbook-ai-scene.shivashisvicky112.workers.dev  
**Current HEAD:** \`d795b4db31693768c1e6b1b80593574d3bf38e01\`  
**Latest commit:** \`docs: align AI scene generation handoff with current reader architecture\`

This document supersedes older handoff sections that describe a different reader renderer, older T2V-first architecture, old demo-book/source state, or older commit hashes. Read this entire document before modifying the branch.

---

# 1. NON-NEGOTIABLE PROJECT RULES

1. **Work only on \`test/superbook-ai-scene-foundation\`.**
2. **Never touch \`main\` for this work.**
3. Do not make a change merely because it compiles. Inspect the actual reader path and the actual visual result.
4. Never claim something is implemented, deployed, working, or verified without evidence.
5. A green GitHub Actions run proves the workflow/build/test result. It does **not** prove the visual experience is good.
6. A successful Pages deployment proves the artifact was deployed. It does **not** prove the reader looks correct.
7. Visual claims require actual inspection of the deployed reader or a recording.
8. Do not blindly stack commits on top of a visually broken architecture.
9. Prefer small surgical commits.
10. After each meaningful push, inspect the corresponding Actions run.
11. Do not ask the user to retest a known-broken build.
12. Do not restore the old stick-figure/deterministic renderer as the product Experience.
13. Do not turn a static image into fake "animation" using only zoom/pan/Ken Burns.
14. Do not use a slideshow of unrelated stills as the definition of character animation.
15. The book passage remains canonical. AI is an interpretation layer, not a replacement for the literary source.
16. Do not silently substitute unrelated book editions.
17. Do not introduce paid infrastructure under the current user requirement.
18. **NO MONEY** means no AI Gateway credits, Unified Billing, Workers Paid, R2 subscription, paid third-party provider, or hidden paid fallback.
19. Never tell the user that \`alibaba/hh1.1-t2v\` is covered by the Workers AI free allocation. It is currently classified as third-party and the live account returned \`2021: Insufficient AI Gateway credits\`.
20. Do not revive a known-blocked path just to make a demo appear more animated.
21. Do not confuse the animation lab with the production reader. The reader is the product source of truth.
22. Do not delete useful experiments without understanding their purpose. The lab can remain a development/reference asset, but it must not become a disconnected second product.

---

# 2. PRODUCT GOAL

SuperBook is intended to make a real book feel alive.

The desired flow is:

\`\`\`
real book passage
      ↓
literary/context understanding
      ↓
structured AI ScenePlan
      ↓
coherent visual interpretation
      ↓
characters / props / environment staged correctly
      ↓
continuous story-driven animation
      ↓
reader Experience
\`\`\`

The Experience must communicate the literary moment, not merely decorate a page.

A successful scene should make a reader understand:

- who is present;
- where they are;
- what is happening;
- what changes during the moment;
- what the characters physically do;
- what important props are doing;
- why the movement belongs to this passage.

The user explicitly accepts simple animation. They do **not** accept:

- static AI picture + arbitrary vector people pasted on top;
- static picture + camera zoom/pan presented as character animation;
- three stills cross-faded and called animation;
- old stick figures;
- generic characters whose actions are unrelated to the generated scene;
- a carriage that appears in the wrong spatial context;
- characters floating in front of a photographic background without matching perspective;
- a procedural room that looks like a diagram when a cinematic literary scene is expected.

---

# 3. CURRENT VERIFIED REPOSITORY STATE

Current branch HEAD:

\`\`\`
d795b4db31693768c1e6b1b80593574d3bf38e01
docs: align AI scene generation handoff with current reader architecture
2026-09-28 06:45:07Z
\`\`\`

Parent:

\`\`\`
b9e04b67384b96ed11be9c68edce6eba54438338
Show local scene immediately while AI scene loads
\`\`\`

Previous important visual commit:

\`\`\`
b8552860c6f96dec1b3652757f2030596fdad66d
Restore AI scene with stronger beat-driven animation
\`\`\`

Earlier environment work:

\`\`\`
773303b7e078d433450eb74651fc8eaec4d22e82
Expand semantic environment library and chapter context resolver
\`\`\`

Earlier carriage staging:

\`\`\`
3528769ee4060969c69fd9a62b1d8a0fe3a38ff8
Improve carriage staging
\`\`\`

Earlier carriage clipping/scale fix:

\`\`\`
6d4c20887394e07b4ae1053511dd99fd2f0cbbb3
Fix carriage clipping and scale
\`\`\`

Earlier resolver separation:

\`\`\`
7d5f99c7ce40ad33db605480aebc21070cd87499
Fix environment resolver to separate setting from props
\`\`\`

---

# 4. CURRENT CI / DEPLOYMENT EVIDENCE

## Push CI

Workflow:

\`\`\`
SuperBook CI
\`\`\`

Run:

\`\`\`
36379944898
\`\`\`

Run number:

\`\`\`
749
\`\`\`

HEAD:

\`\`\`
f6b1baa8e031b6848b3e574d1bbfe74ae2c12fec
\`\`\`

Status:

\`\`\`
completed / success
\`\`\`

The workflow includes:

- Flutter stable setup
- \`flutter pub get\`
- \`flutter create . --platforms web\`
- removal of generated widget test
- \`flutter analyze\`
- \`flutter test\`
- \`flutter build web --release --pwa-strategy=none --base-href "/SuperBook/test/"\`

## Pull-request CI

Run:

\`\`\`
36379948137
\`\`\`

Status:

\`\`\`
completed / success
\`\`\`

Do not infer future CI status from this historical result.

## TEST Pages

Workflow:

\`\`\`
SuperBook Test Pages
\`\`\`

Run:

\`\`\`
36379944911
\`\`\`

Run number:

\`\`\`
455
\`\`\`

HEAD:

\`\`\`
f6b1baa8e031b6848b3e574d1bbfe74ae2c12fec
\`\`\`

Status:

\`\`\`
completed / success
\`\`\`

TEST URL:

https://shivashisvicky.github.io/SuperBook/test/?v=f6b1baa8

Important: this confirms Pages deployment for the commit. It does not certify the visual Experience.

---

# 5. LATEST VISUAL EVIDENCE: DO NOT IGNORE THIS

Latest user recording:

\`\`\`
/mnt/data/ScreenRecording_09-28-2026 11-42-21_1.mp4
\`\`\`

Recorded approximately 2026-09-28.

Technical properties observed from the file:

- 30 fps
- 795 frames
- 512 x 1108
- approximately 26.5 seconds
- file size approximately 6.94 MB

Representative frames were inspected.

## Frame around 72

Observed:

- Chapter 5.
- AI-generated photographic/realistic background.
- Realistic women/people appear inside the generated scene.
- Additional crude vector figures are visibly pasted in front of the AI-generated people.
- Story bubble appears at the top.
- Story Moment overlay appears at the bottom.
- The combination reads as two visual systems occupying the same scene rather than one coherent animated scene.

## Frame around 360

Observed:

- Chapter 7.
- Flat procedural room with a window/furniture.
- Two stylized vector figures.
- No AI image visible in that frame/state.
- Scene reads diagrammatically rather than as a cinematic literary moment.

## Frame around 794

Observed:

- Chapter 8.
- Flat procedural room.
- Two vector figures.
- Large narrative UI cloud/overlay.
- Again reads as a deterministic stage rather than a coherent generated cinematic scene.

## Visual conclusion

The current build is **not the finished animation experience**.

The deployment is technically successful, but the visual architecture is still wrong.

The most important architectural problem is:

> An arbitrary AI-generated image is being used as a background plate while generic deterministic vector actors/props are independently animated on top of it.

Those actors are not guaranteed to correspond spatially to the people, windows, furniture, carriage, depth, lighting, or perspective present in the generated image.

This is why the scene can look like a photograph with pasted cartoon figures.

Do not describe the current build as "fixed" or "cinematic" based on CI alone.

---

# 6. CURRENT PRODUCTION READER PATH

Primary file:

\`\`\`
lib/features/scenes/scene_player_screen.dart
\`\`\`

The current reader imports:

\`\`\`
superbook_local_animation_stage.dart
\`\`\`

Current behavior:

1. On entry, the cache is checked.
2. If no cached scene exists, \`_generate()\` is started.
3. While AI generation is running, the local animation stage is rendered immediately.
4. When AI generation completes, \`_generated\` is populated.
5. The generated plan is passed into the local stage through \`actionHint\`.
6. The generated still image is passed as \`backgroundImageBase64\` unless \`_useLocalAnimation\` is true.
7. A Story Moment overlay remains visible at the bottom.
8. Cached video can still be loaded by \`_loadVideo()\`, but the current \`_visual()\` path does not return the video widget. Therefore generated video is not currently the normal visual path.
9. If the endpoint is unavailable or generation fails, the local animation path is used.
10. Current failure handling intentionally does not surface infrastructure errors as a reader-facing red error in the normal fallback path.

Important current code shape:

\`\`\`dart
if (generated != null)
  _visual(generated)
else
  _visualLocal(),
\`\`\`

The latest commit removed the large centered loading overlay that previously blocked/obscured the local animation while AI generation was in progress.

That change improved the loading presentation, but it did not solve the underlying visual architecture.

---

# 7. CURRENT LOCAL ANIMATION STAGE

File:

\`\`\`
lib/features/scenes/superbook_local_animation_stage.dart
\`\`\`

This is currently a large Flutter CustomPaint-based renderer.

It contains:

- animation controller;
- narrative beat parsing;
- character rig;
- head;
- torso/dress;
- two-segment legs;
- feet;
- arms;
- shading;
- contact shadow;
- action selection;
- carriage/prop drawing;
- optional AI background image.

## AI image layering

When \`backgroundImageBase64\` is present:

\`\`\`
Image.memory(
  base64Decode(widget.backgroundImageBase64!),
  fit: BoxFit.cover,
  gaplessPlayback: true,
)
\`\`\`

is placed under the CustomPaint.

The painter then uses:

\`\`\`
drawBackground: false
\`\`\`

so the procedural environment is not drawn.

The actors/props are still drawn by the local painter.

This is the precise source of the visual mismatch seen in the recording.

## Character placement

Current actor positions are generic rather than scene-anchored.

The implementation uses positions derived from actor index, such as:

\`\`\`
final baseX = size.width * (i == 0 ? .30 : .70);
\`\`\`

with generic movement offsets.

This means the generated AI image may show people somewhere completely different from where the vector actors are placed.

## Scale

When an AI image exists, actor scale is reduced using a multiplier around \`.78\`.

This is a visual compensation, not a true perspective solution.

## Carriage

The carriage is drawn as a procedural vector prop at fixed screen coordinates.

It is not currently guaranteed to align with a window, road, doorway, or other environment feature in the AI-generated image.

## Action parsing

Current local animation derives beats from the chapter passage by splitting sentences/clauses and chunks of approximately 22 words.

The local action classifier searches the current beat for keywords.

This is useful as a fallback experiment, but it is not a sufficient semantic animation contract.

A phrase such as:

\`\`\`
reaches the window and looks outside
\`\`\`

can be classified incorrectly because the current action matching order can hit \`look\` before \`reach\`.

Walk/stand/reach/look ordering is also too generic for reliable literary choreography.

## Duration

Animation duration is derived from word count, roughly 15 seconds per 22 words and clamped to a broad range.

The controller does not repeat indefinitely. It eventually reaches the final state and stops.

That is acceptable for a one-shot scene if intentionally designed, but the current beat timing is not yet a high-quality cinematic timeline.

---

# 8. WHY THE CURRENT READER ARCHITECTURE IS NOT ENOUGH

The current system effectively does:

\`\`\`
literary passage
   ↓
AI still image
   ↓
generic vector actors on top
\`\`\`

The desired system needs to do something closer to:

\`\`\`
literary passage
   ↓
AI ScenePlan
   ↓
scene graph
   ├── environment
   ├── named actors
   ├── visible props
   ├── spatial anchors
   ├── actor positions
   ├── action timeline
   ├── camera intent
   └── depth relationships
   ↓
coherent visual scene
   ↓
local runtime animates those exact scene entities
\`\`\`

The generated still image and the animation runtime must share a common spatial contract.

The next implementation should therefore not simply make the current vector actors "prettier".

It should establish a scene representation in which:

- AI knows which person is where;
- the renderer knows which person is which;
- actions refer to named actors;
- props have meaningful locations;
- the environment has known anchors;
- the camera is defined relative to the scene;
- movement targets correspond to those anchors;
- the generated still can be used as a coherent visual plate only when the overlay entities actually match it.

---

# 9. RECOMMENDED NEXT ARCHITECTURE

Do not blindly implement every item below in one commit. Use this as the target architecture.

## SceneGraph

Introduce a compact normalized scene graph derived from \`AiScenePlan\`.

Example conceptual contract:

\`\`\`json
{
  "environment": {
    "kind": "house",
    "location": "Bennet family dining room",
    "anchors": {
      "window": {"x": 0.82, "y": 0.38},
      "table": {"x": 0.48, "y": 0.68},
      "door": {"x": 0.10, "y": 0.40}
    }
  },
  "actors": [
    {
      "id": "elizabeth",
      "role": "observer",
      "anchor": "table",
      "visible": true
    }
  ],
  "props": [
    {
      "id": "carriage",
      "anchor": "outside_window"
    }
  ],
  "timeline": [
    {
      "type": "narrative",
      "text": "...",
      "durationMs": 6000
    },
    {
      "type": "action",
      "actor": "elizabeth",
      "action": "turn",
      "target": "window",
      "durationMs": 1800
    },
    {
      "type": "action",
      "actor": "elizabeth",
      "action": "walk",
      "target": "window",
      "durationMs": 3200
    },
    {
      "type": "action",
      "actor": "elizabeth",
      "action": "look",
      "target": "outside_window",
      "durationMs": 1800
    }
  ]
}
\`\`\`

This is an architecture example, not a requirement to copy the exact JSON.

## Named actors

Do not position characters merely by list index.

Resolve book character identity where possible.

If the passage says Elizabeth, the visual actor should represent Elizabeth rather than "character 0".

## Environment anchors

Use normalized coordinates and semantic anchors.

Examples:

- window;
- door;
- table;
- chair;
- fireplace;
- road;
- garden;
- bed;
- desk;
- stage;
- ship rail;
- carriage exterior.

## Explicit timeline

Prefer AI-generated action beats over generic keyword classification.

Fallback keyword parsing can remain for robustness, but it should not be the primary choreography engine.

---

# 10. ENVIRONMENT RESOLVER

There is already environment-resolution work in the branch.

The earlier resolver library supports semantic environments including:

- house;
- garden;
- park;
- road;
- street;
- cafeteria;
- airplane;
- forest;
- beach;
- mountain;
- farm;
- school;
- office;
- library;
- train;
- ship;
- castle;
- church;
- market;
- city;
- snow;
- desert;
- dungeon;
- room.

The current lab has a semantic environment resolver based on passage keywords.

Important limitation:

> The resolver exists in the animation lab and related code, but the actual reader does not yet have a complete semantic scene graph / spatial anchoring integration.

Do not assume that because the lab can identify "house" or "garden", the reader is already correctly staging the AI image and actors.

---

# 11. ANIMATION LAB

File:

\`\`\`
web/animation_lab/index.html
\`\`\`

The lab is standalone and currently contains a more explicit authored sequence.

Current representative sequence:

1. READ: family seated together in dining room.
2. HEAR: carriage heard outside.
3. TURN: Elizabeth turns toward window.
4. STAND: she rises from her seat.
5. WALK: she walks toward window.
6. REACH + LOOK: she reaches window and looks outside.
7. CARRIAGE: carriage rolls into view.
8. READ: carriage has arrived and attention is drawn to window.

The lab uses:

- SVG scene graph;
- requestAnimationFrame;
- authored poses;
- two character rigs;
- legs with knees/shins/feet;
- arms with upper/lower segments;
- carriage prop;
- semantic environment resolver;
- timeline beats.

This lab demonstrated that a local runtime can perform actual continuous character motion.

However, the lab is **not the production reader**.

Known lab limitation:

- it uses authored sample actors and sample staging;
- it is not driven by arbitrary book-specific AI ScenePlans;
- it does not solve the production problem of aligning AI-generated photographic scenes with runtime actors;
- some environment/staging logic exists only here.

Do not simply port the whole lab into the reader without reconciling it with the AI ScenePlan contract.

---

# 12. AI SCENE DIRECTOR

Worker source:

\`\`\`
cloudflare/superbook-ai-worker/src/index.js
\`\`\`

Current models:

\`\`\`
TEXT_MODEL  = @cf/meta/llama-3.3-70b-instruct-fp8-fast
IMAGE_MODEL = @cf/black-forest-labs/flux-1-schnell
MOTION_MODEL = @cf/black-forest-labs/flux-2-klein-4b
VIDEO_MODEL = alibaba/hh1.1-t2v
\`\`\`

## Text planner

The Scene Director asks for one compact structured JSON object.

Current limits:

- max 2 characters;
- max 3 props;
- max 3 actions;
- concise strings;
- scene summary around 25-45 words;
- no invented named characters;
- no major contradictory objects/locations;
- one coherent cinematic frame;
- period-appropriate visual details where relevant;
- no text/logos/watermarks;
- restrained 3-6 second motion description.

The plan contains:

- schemaVersion;
- sceneSummary;
- visualStyle;
- characters;
- environment;
- props;
- actions;
- camera;
- lighting;
- motion;
- imagePrompt.

## Image

The image generator produces a single scene still from the scene plan.

## Motion

\`/motion\` exists and uses FLUX.2 Klein 4B.

It is a potential future free-tier motion asset mechanism, subject to current Cloudflare limits and actual verification.

Do not assume that "free allocation" means unlimited generation.

## T2V

\`/video\` exists but uses:

\`\`\`
alibaba/hh1.1-t2v
\`\`\`

It is not an acceptable automatic path under the current no-money constraint.

---

# 13. CLOUDFLARE BILLING TRUTH

This distinction is critical.

Workers AI free allocation:

\`\`\`
10,000 Neurons/day
\`\`\`

That does not make every model in the catalog free.

Current:

\`\`\`
@cf/meta/...
@cf/black-forest-labs/...
\`\`\`

are Workers AI model paths.

Current T2V:

\`\`\`
alibaba/hh1.1-t2v
\`\`\`

is classified by Cloudflare as third-party.

The live failure observed was:

\`\`\`
2021: Insufficient AI Gateway credits
\`\`\`

Therefore:

- do not buy credits;
- do not enable Unified Billing;
- do not upgrade Workers Paid;
- do not add R2;
- do not add paid third-party APIs;
- do not hide a paid fallback.

If a genuinely free model/provider is considered later, verify its current billing classification first.

---

# 14. WORKER DEPLOYMENT

Worker root:

\`\`\`
cloudflare/superbook-ai-worker
\`\`\`

Deploy command:

\`\`\`
npx wrangler deploy
\`\`\`

Worker:

\`\`\`
https://superbook-ai-scene.shivashisvicky112.workers.dev
\`\`\`

Expected health endpoint:

\`\`\`
/health
\`\`\`

The worker smoke workflow waits for:

\`\`\`
https://superbook-ai-scene.shivashisvicky112.workers.dev/health
\`\`\`

and expects:

- \`ok == true\`;
- service \`superbook-ai-scene\`;
- scene schema version \`2\`.

The smoke workflow then calls the live scene generation endpoint and validates:

- HTTP 200;
- schema version;
- scene plan object;
- character bounds;
- prop bounds;
- action bounds;
- environment;
- camera;
- lighting;
- motion;
- imagePrompt;
- generated image payload.

The smoke workflow also currently tests the \`/puppet-sheet\` endpoint.

Important: \`/puppet-sheet\` is not the production reader architecture and must not be mistaken for a solution to scene animation.

---

# 15. CURRENT WRANGLER CONFIGURATION

Current intended configuration:

\`\`\`toml
id="hahkwq"
name="superbook-ai-scene"
main="src/index.js"
compatibility_date="2026-09-21"

[ai]
binding="AI"

[observability]
enabled=true
\`\`\`

There is no R2 binding.

Do not reintroduce R2 under the current requirements.

---

# 16. FLUTTER PROVIDER

File:

\`\`\`
lib/services/scene_generation/cloudflare_scene_provider.dart
\`\`\`

The provider calls the Worker.

It supports:

- scene generation;
- video generation capability;
- motion-frame generation capability where implemented;
- diagnostic handling.

The Flutter application does not receive a Cloudflare provider secret.

The AI endpoint is injected using:

\`\`\`
SUPERBOOK_AI_SCENE_ENDPOINT
\`\`\`

TEST Pages currently supplies:

\`\`\`
https://superbook-ai-scene.shivashisvicky112.workers.dev
\`\`\`

---

# 17. CACHE

File:

\`\`\`
lib/services/scene_generation/scene_generation_cache.dart
\`\`\`

Scene identity is based on:

\`\`\`
bookId + chapterId + source passage
\`\`\`

with a passage-derived hash in the actual keying implementation.

The principle is:

> Source passage changes must produce a different scene identity.

Do not key only on a generated prompt.

Do not regenerate the same scene unnecessarily.

---

# 18. BOOK / GUTENBERG PIPELINE HISTORY

The branch previously had a serious reader-source problem.

The observed failure involved:

- Open Library discovery leading to Internet Archive edition text before Gutenberg;
- Pride and Prejudice resolving to a Finnish Gutenberg edition rather than canonical English #1342;
- Gutenberg license/front matter being exposed as chapters;
- replacement-character corruption;
- chapter markers being incorrectly globally numeric-sorted.

This was corrected in earlier branch work.

Important accepted Gutenberg canaries:

- Pride and Prejudice: #1342
- The Adventures of Sherlock Holmes: #1661
- Moby-Dick: #2701
- Frankenstein: #84
- Dracula: #345
- Great Expectations: #1400
- The Picture of Dorian Gray: #174

Canonical source example:

\`\`\`
https://www.gutenberg.org/ebooks/1342
https://www.gutenberg.org/cache/epub/1342/pg1342.txt
\`\`\`

The reader must not silently substitute an unrelated edition when a canonical Gutenberg ID is known.

Do not globally numeric-sort source chapter markers. Source-order invariants must be preserved.

The current AI Experience work assumes the reader/source layer is canonical and stable.

---

# 19. JARVIS-OS REFERENCE

Reference repo:

\`\`\`
https://github.com/shivashisvicky/Jarvis-OS
\`\`\`

Reference TEST branch:

\`\`\`
test/jarvis-intelligence-next
\`\`\`

Reference TEST:

\`\`\`
https://shivashisvicky.github.io/Jarvis-OS/test/
\`\`\`

Useful source acquisition references from Jarvis:

- \`jarvis-ebook-network-fast-v1.js\`
- \`jarvis-ebook-network-race-fix-v1.js\`
- \`jarvis-ebook-performance-fix-v1.js\`
- \`jarvis-ebook-content-normalizer-v1.js\`
- \`jarvis-ebook-stream-reader-v1.js\`

Relevant engineering lessons:

- canonical source;
- bounded/raced acquisition;
- raw text caching;
- in-flight request dedupe;
- normalization before parsing;
- progressive rendering where practical;
- small surgical changes;
- validate actual deployed TEST behavior;
- do not roll back working features casually.

Jarvis is a reference for engineering discipline and reader performance, not a reason to copy unrelated UI.

---

# 20. OLD RENDERER: DO NOT RESTORE

The old deterministic/stick renderer was explicitly rejected.

It can exist as:

- historical code;
- development fixture;
- fallback for diagnostics if clearly separated.

It must not become the real Experience again.

The current local renderer is more sophisticated than the old stick version, but it still has the same fundamental problem when used as a generic overlay on an unrelated AI image.

Therefore the next step is not "make the old renderer slightly nicer".

The next step is to connect the scene representation, environment, actors, props, and timeline coherently.

---

# 21. WHAT HAS ACTUALLY BEEN ACHIEVED

Verified through code and CI:

### Achieved

- canonical reader/source recovery work exists in the branch;
- AI Scene Director exists;
- structured ScenePlan exists;
- generated still scene exists;
- reader-facing story summary exists;
- scene cache exists;
- Cloudflare Worker gateway exists;
- live Worker smoke-test workflow exists;
- TEST Pages deployment exists;
- local animated stage exists;
- characters have real articulated limbs rather than only simple dots/sticks;
- authored animation lab proves continuous local motion is technically possible;
- latest CI is green;
- latest TEST Pages deployment is green;
- latest commit removes the centered loading overlay that obscured the local stage while AI generation runs.

### Not achieved

- coherent alignment between generated AI image and animated actors;
- arbitrary book passage -> robust semantic action timeline;
- named actor identity -> correctly staged actor;
- environment anchors in the production reader;
- true cinematic continuity between AI image and local animation;
- a production-quality free character animation engine;
- automatic free T2V;
- automatic use of Worker \`/motion\` in the reader;
- verified high-quality visual experience across arbitrary books.

---

# 22. CURRENT VISUAL FAILURE IN ONE SENTENCE

**The reader currently has two scene systems, AI-generated photographic background and deterministic vector animation, that do not share the same spatial scene model.**

That is the key thing the next agent must solve.

---

# 23. NEXT ENGINEERING MILESTONE

The next milestone should be:

> **Build one coherent AI-informed local scene graph and use it to drive the actual reader animation.**

Minimum acceptance:

1. The AI plan identifies the visible actors.
2. The reader maps those actors to named scene entities.
3. The environment is resolved.
4. Important props are resolved.
5. Actor positions are meaningful.
6. Action targets are meaningful.
7. The animation timeline is explicit.
8. The same scene graph controls both the generated visual interpretation and local animation staging.
9. No actor is arbitrarily pasted over unrelated people in the generated image.
10. A carriage must be outside the window if the narrative says it arrives outside.
11. Walking must move the correct actor from a plausible start anchor to a plausible target anchor.
12. Looking must orient the actor toward the actual target.
13. The scene must continue to read correctly even if the AI image generation is unavailable.
14. The local fallback must still be driven by the same semantic scene graph, not revert to the old stick renderer.
15. No paid service is introduced.

---

# 24. SUGGESTED FIRST IMPLEMENTATION

Do not attempt the entire universal engine first.

Use a single canonical canary scene:

\`\`\`
A family is inside a dining room.
A carriage is heard outside.
Elizabeth turns toward a window.
She stands.
She walks to the window.
She reaches/look outside.
The carriage appears outside.
\`\`\`

Implement:

- environment: dining room;
- anchors: table, chair, window, outside-window;
- actors: Elizabeth + one family member;
- prop: carriage;
- explicit timeline;
- actor identity;
- camera framing;
- outside-window depth layer.

Then run it through the real reader, not only the lab.

If this single scene cannot look coherent, do not generalize the engine yet.

---

# 25. ANIMATION QUALITY BAR

A valid implementation must visibly show:

### Turn
Head/upper body orientation changes toward the target.

### Stand
The actor transitions from seated to standing with feet/contact preserved.

### Walk
The actor changes position through a believable gait, not a teleport.

### Reach
The arm reaches toward the actual target.

### Look
Head/body orientation corresponds to the target.

### Carriage
The carriage moves through an outside/depth layer consistent with the window.

### Environment
The actor's scale and placement make sense relative to the room.

### Continuity
The same actor remains the same actor throughout the beat sequence.

### No visual collision
No character should appear to float in front of or through furniture/architecture without intentional staging.

### No fake animation
Camera drift alone is not enough.

---

# 26. PERFORMANCE RULES

The Experience must remain responsive.

Do not:

- regenerate AI every frame;
- call AI for every animation beat;
- wait for video before showing any visual;
- perform unbounded network retries;
- load multiple large images unnecessarily;
- create a general-purpose game engine.

Prefer:

\`\`\`
AI once per scene
     ↓
cache
     ↓
local playback
\`\`\`

The local runtime should be responsible for continuous animation.

---

# 27. TOKEN / AI USAGE DISCIPLINE

The current Scene Director is deliberately compact.

Do not increase output budgets merely to hide schema problems.

Current plan bounds:

- 2 characters;
- 3 props;
- 3 actions;
- concise descriptions.

If the scene contract is insufficient, redesign the contract deliberately.

Do not create a chain of multiple AI calls for every frame.

---

# 28. KNOWN HISTORICAL FAILURES

These should not be repeated.

## Paid T2V misunderstanding

\`\`\`
2021: Insufficient AI Gateway credits
\`\`\`

Root cause: third-party Alibaba T2V billing.

## R2

Previous path failed because an R2 bucket was missing and would introduce infrastructure/billing complexity.

Do not reintroduce.

## Old stick renderer

Rejected as not being the intended Experience.

## Ken Burns

Rejected as not being actual story animation.

## Static AI image + generic actors

Current visual failure. Do not continue this architecture unchanged.

## Animation lab disconnected from reader

Useful experiment, but not sufficient. The reader is the source of truth.

## Generic action keyword parsing

Too fragile for arbitrary literature.

## Fixed actor positions

Do not assume actor 0 is left and actor 1 is right.

## Fixed carriage coordinates

Do not assume the window is always at the same screen position.

## Visual claims based only on CI

CI cannot detect visual incoherence.

---

# 29. REQUIRED VERIFICATION SEQUENCE FOR FUTURE CHANGES

For every meaningful change:

1. Inspect the existing implementation.
2. Make the smallest coherent change.
3. Run/inspect local tests if available.
4. Push to \`test/superbook-ai-scene-foundation\`.
5. Verify SuperBook CI.
6. Verify TEST Pages deployment.
7. If Worker code changed, verify Worker smoke.
8. Open the actual TEST URL.
9. Exercise the exact scene.
10. Inspect a recording or screenshots if visual behavior changed.
11. Only then report the result.

Report these states separately:

- implemented in code;
- CI green;
- deployed;
- visually verified.

Never collapse them into one statement.

---

# 30. COPY/PASTE HANDOFF FOR NEXT AGENT

Read \`docs/SUPERBOOK-AI-SCENE-HANDOFF.md\` completely before doing anything.

Repository:
https://github.com/shivashisvicky/SuperBook

Branch:
\`test/superbook-ai-scene-foundation\`

Current HEAD:
\`f6b1baa8e031b6848b3e574d1bbfe74ae2c12fec\`

TEST:
https://shivashisvicky.github.io/SuperBook/test/?v=f6b1baa8

Worker:
https://superbook-ai-scene.shivashisvicky112.workers.dev

PR:
https://github.com/shivashisvicky/SuperBook/pull/2

Latest push CI:
https://github.com/shivashisvicky/SuperBook/actions/runs/36379944898

Latest Pages deployment:
https://github.com/shivashisvicky/SuperBook/actions/runs/36379944911

Latest PR CI:
https://github.com/shivashisvicky/SuperBook/actions/runs/36379948137

The parent code commit f6b1baa8 was CI-green and Pages-deployed. This handoff-only commit is now the branch head. New CI/Pages runs are queued for d795b4db and must be checked before calling this exact HEAD deployed or green.

I inspected the latest recording:
\`/mnt/data/ScreenRecording_09-28-2026 11-42-21_1.mp4\`

It shows the actual problem: AI-generated photographic backgrounds are combined with generic vector actors/props that are not spatially anchored to the generated scene. Some chapters show a flat procedural room instead. This looks like two rendering systems pasted together.

Do NOT claim this is fixed.

Do NOT restore the old stick/deterministic renderer.

Do NOT use Ken Burns movement as animation.

Do NOT use a three-image slideshow as the definition of character animation.

Do NOT add money.

Do NOT enable AI Gateway credits, Unified Billing, Workers Paid, R2, paid third-party APIs, or hidden paid fallbacks.

The Alibaba T2V model:
\`alibaba/hh1.1-t2v\`
is third-party and the live failure was:
\`2021: Insufficient AI Gateway credits\`

The actual reader is:
\`lib/features/scenes/scene_player_screen.dart\`

The actual current renderer is:
\`lib/features/scenes/superbook_local_animation_stage.dart\`

The current renderer:
- parses passage text into beats;
- uses generic keyword action detection;
- draws articulated vector characters;
- optionally places the AI image underneath;
- uses generic actor positions;
- uses fixed carriage staging;
- does not share a true spatial scene graph with the AI image.

The worker is:
\`cloudflare/superbook-ai-worker/src/index.js\`

Current models:
- Llama 3.3 70B for scene planning
- FLUX.1 Schnell for scene still
- FLUX.2 Klein 4B for optional motion capability
- Alibaba HappyHorse 1.1 T2V, blocked and not acceptable under no-money

The animation lab:
\`web/animation_lab/index.html\`
proves authored local motion can work, but it is a separate experiment and must not become a disconnected second product.

Next target:
Build a small semantic scene graph for the real reader:
- named actors;
- environment kind;
- semantic anchors;
- props;
- explicit action timeline;
- target anchors;
- depth layers;
- camera intent.

Use one canary sequence first:
dining room -> carriage heard -> turn -> stand -> walk -> reach/look -> carriage outside window.

Then make that exact sequence run through the actual reader.

Do not generalize until the canary is visually coherent.

CI/deployment success is not visual verification. Inspect the real deployed TEST surface after every visual change.

No main branch changes.

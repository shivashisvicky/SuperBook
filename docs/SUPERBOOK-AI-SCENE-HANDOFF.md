# SuperBook AI Experience TEST Handoff

**Purpose:** This is the authoritative continuation document for the current SuperBook AI Experience work. A new agent must be able to continue from this exact state without reconstructing the conversation, guessing which branch is current, repeating failed experiments, or reintroducing a known billing mistake.

**Last updated:** 2026-09-22 01:58 IST
**Repository:** `shivashisvicky/SuperBook`  
**Active branch:** `test/superbook-ai-scene-foundation`  
**Stable branch:** `main`  
**TEST Pages:** `https://shivashisvicky.github.io/SuperBook/test/`  
**AI Worker:** `superbook-ai-scene`  
**AI Worker URL:** `https://superbook-ai-scene.shivashisvicky112.workers.dev`  
**Draft PR:** `https://github.com/shivashisvicky/SuperBook/pull/2`  
**PR:** #2, `AI Experience: scene planning and generated visual foundation`

---

# 1. STOP. READ THIS FIRST.

The most important current fact is:

> **SuperBook's AI scene understanding and generated still image work. The story-animation T2V request reaches the Worker but fails because the selected Alibaba HappyHorse 1.1 T2V model requires AI Gateway/Unified Billing credits. The user explicitly does NOT want to spend money.**

The exact live Cloudflare error is:

```
2021: Insufficient AI Gateway credits
```

This is **not** a transient browser problem.

This is **not** R2.

This is **not** a Gutenberg CORS problem.

This is **not** a Flutter video-player problem.

This is **not** evidence that the current T2V request merely needs another retry.

The user explicitly said **no money**. Do not ask the user to purchase AI Gateway credits, enable Unified Billing, add a Workers Paid plan, subscribe to R2, or otherwise introduce paid infrastructure unless the user explicitly changes that requirement.

Cloudflare currently classifies `alibaba/hh1.1-t2v` as a **third-party** model. It is not part of the no-cost Workers AI `@cf/` model allocation. The public Cloudflare model page itself labels the model "Third-party". The current Workers AI free allocation of 10,000 Neurons/day therefore must NOT be described as making this video model free.

This billing distinction was the source of the previous misunderstanding and must remain explicit in future handoffs.

---

# 2. EXACT CURRENT PRODUCT STATE

## Working

### AI Scene Director
Real literary passage -> AI understanding -> constrained scene plan.

Working.

### Generated scene image
Real literary passage -> Llama scene plan -> FLUX generated still image.

Working and visibly tested by the user.

### Reader-facing story summary
The scene plan includes a 2-3 sentence summary of what is happening, immediate context, and why the moment matters.

Working.

### Visual scene presentation
The generated still image is displayed as the Experience visual.

Working.

### Narrative-driven animation architecture
The application has a real T2V pipeline that sends the narrative scene plan to a video model.

Architecturally implemented.

Operationally blocked by billing for the selected third-party model.

### Diagnostics
The Worker now returns detailed video-generation diagnostics and Flutter preserves/displays them.

Working.

The user has already seen:

```
Animation generation failed:
Bad state: Video generation failed.
2021: Insufficient AI Gateway credits
```

This is valuable because the real root cause is now known.

---

# 3. EXACT CURRENT FAILURE

The browser request is:

```
POST https://superbook-ai-scene.shivashisvicky112.workers.dev/video
```

Cloudflare invocation event:

```
method: POST
path: /video
response.status: 502
wallTimeMs: ~1333
cpuTimeMs: 2
```

The important paired Cloudflare console event is:

```
message: SuperBook scene animation failed
detail: 2021: Insufficient AI Gateway credits
scriptName: superbook-ai-scene
```

This proves the Worker itself is returning the 502 after the model invocation fails.

The current request is therefore:

```
Flutter
  -> POST /video
  -> Worker
  -> env.AI.run(alibaba/hh1.1-t2v, ...)
  -> Cloudflare billing boundary
  -> 2021 Insufficient AI Gateway credits
  -> Worker returns 502
  -> Flutter displays diagnostic
```

Do not spend time debugging video playback until a video URL can actually be produced.

---

# 4. CRITICAL BILLING CORRECTION

Earlier project notes incorrectly treated the T2V model as if it were covered by the Workers AI free allocation.

That was wrong.

Cloudflare currently documents:

- Workers AI free allocation: 10,000 Neurons/day.
- `@cf/` models are Workers AI models.
- `alibaba/hh1.1-t2v` is a third-party Alibaba model.
- Third-party model access uses Cloudflare AI Gateway / Unified Billing and requires credits or another supported billing arrangement.

Therefore:

```
Llama @cf model
    -> Workers AI
    -> free allocation can apply

FLUX @cf model
    -> Workers AI
    -> free allocation can apply

Alibaba HappyHorse 1.1 T2V
    -> third-party model
    -> AI Gateway / Unified Billing
    -> requires credits
    -> BLOCKED under current no-money constraint
```

Do not "fix" this by changing the model string to an imagined `@cf/alibaba/...` namespace. Cloudflare's current model page explicitly identifies `alibaba/hh1.1-t2v` as third-party.

Do not assume another Alibaba video model is free merely because it is available in the same Cloudflare catalog. Verify billing classification first.

---

# 5. USER'S BILLING REQUIREMENT

Non-negotiable unless user explicitly changes it:

> **NO MONEY.**

That means:

- no R2 subscription
- no Workers Paid upgrade
- no AI Gateway prepaid credits
- no Unified Billing purchase
- no third-party API key requiring payment
- no hidden paid fallback
- no "just add $5/$10/$20" suggestion
- no architecture that silently consumes paid credits

If a future free T2V provider/model is discovered, it can be evaluated.

If no free T2V option exists, the correct product behavior is to keep the generated still Experience functional and make animation an optional capability that remains unavailable.

---

# 6. CURRENT EXPERIENCE ARCHITECTURE

The intended architecture is:

```
BOOK PASSAGE
     |
     v
AI SCENE DIRECTOR
     |
     v
AiScenePlan
     |
     +--------------------+
     |                    |
     v                    v
IMAGE GENERATOR       STORY ANIMATOR
     |                    |
     v                    v
generated still       generated video
     |                    |
     +---------+----------+
               |
               v
        EXPERIENCE PLAYER
```

The book passage remains canonical.

The AI scene plan is the understanding layer.

Generated media is presentation/cache output.

The video model must receive the narrative context, not just a generic instruction such as "animate this image".

---

# 7. CURRENT AI MODELS

Worker source:

`cloudflare/superbook-ai-worker/src/index.js`

Current constants:

```js
const TEXT_MODEL = '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
const IMAGE_MODEL = '@cf/black-forest-labs/flux-1-schnell';
const VIDEO_MODEL = 'alibaba/hh1.1-t2v';
```

Current roles:

### Text

```
@cf/meta/llama-3.3-70b-instruct-fp8-fast
```

Produces the constrained scene plan.

### Image

```
@cf/black-forest-labs/flux-1-schnell
```

Produces the generated scene still.

### Video

```
alibaba/hh1.1-t2v
```

Produces the story animation.

**This third-party model is currently blocked by insufficient AI Gateway credits.**

---

# 8. CURRENT SCENE PLAN CONTRACT

File:

`lib/domain/experience/ai_scene_plan.dart`

The plan contains:

- schemaVersion
- sceneSummary
- visualStyle
- characters
- environment
- props
- actions
- camera
- lighting
- motion
- imagePrompt

The Worker validates the plan before image/video generation.

The scene summary is intentionally reader-facing and is supposed to explain:

1. what is happening;
2. immediate context;
3. why the moment matters.

The current prompt constrains the AI not to invent:

- named characters;
- major objects;
- contradictory locations;
- unrelated plot events.

The image prompt describes one coherent cinematic frame.

The motion field is intended for restrained, physically plausible 3-6 second motion.

---

# 9. CURRENT WORKER VIDEO IMPLEMENTATION

File:

`cloudflare/superbook-ai-worker/src/index.js`

`POST /video` expects:

```json
{
  "scenePlan": { ... }
}
```

It does NOT use R2.

It does NOT receive an image.

It calls:

```js
await env.AI.run(VIDEO_MODEL, {
  prompt: ...,
  duration: 4,
  resolution: '720P',
  ratio: '16:9',
  watermark: false,
});
```

The prompt contains:

- scene summary
- visual style
- environment
- characters
- meaningful motion
- actions
- camera
- lighting
- constraints against new plot events
- constraints against text/logos/watermarks/scene changes

The intended output is a short 4-second story animation.

If successful, the Worker returns:

```json
{
  "video": {
    "url": "https://superbook-ai-scene....../video?url=...",
    "durationSeconds": 4
  }
}
```

The Worker also has a GET `/video?url=...` proxy that forwards Range headers for browser playback.

**Do not debug that proxy until the T2V model actually returns a video.**

---

# 10. CURRENT FLUTTER PROVIDER

File:

`lib/services/scene_generation/cloudflare_scene_provider.dart`

Interface:

```dart
Future<GeneratedVideo> generateVideo({
  required AiScenePlan plan,
});
```

It POSTs only:

```json
{
  "scenePlan": { ... }
}
```

It preserves Worker diagnostics:

- error
- detail
- code
- upstreamStatus

This was deliberately added so model/billing failures are not hidden behind a generic message.

---

# 11. CURRENT SCENE PLAYER BEHAVIOR

File:

`lib/features/scenes/scene_player_screen.dart`

The previous lightweight choreography experiment was rejected by the user because it only animated UI/focus effects over one static image. That implementation is no longer the intended animation path.

The current direction is **AI-generated motion keyframes**.

Flow:

```
Enter Experience
    |
    v
AI ScenePlan + generated still
    |
    v
Resize still to a reference image below 512px
    |
    v
FLUX.2 [klein] 4B image-to-image keyframes
    |
    +--> narrative action 1
    +--> narrative action 2
    +--> narrative action 3
    |
    v
Cross-fade the generated keyframes as a continuous story sequence
```

The keyframes are generated from the same reference scene and ScenePlan so the model is instructed to preserve:

- the same room and period;
- the same characters and clothing;
- the same identities;
- the same composition and lighting;
- only the physical acting needed for the current narrative beat.

This is intentionally different from:

- the old deterministic stick renderer;
- generic Ken Burns movement;
- UI-only focus animation;
- the paid Alibaba HappyHorse T2V path.

The new Worker endpoint is:

`POST /motion`

It uses:

`@cf/black-forest-labs/flux-2-klein-4b`

The model supports reference-image editing and is a Cloudflare-hosted Workers AI model. Cloudflare currently lists it at 26.05 Neurons per 512x512 output tile, while the Workers AI free allocation is 10,000 Neurons/day. The current restricted-model list does not include FLUX.2 [klein] 4B.

The reader receives the original still immediately. Motion generation happens asynchronously. If motion generation fails for any reason, the still remains the fallback and the infrastructure error is not surfaced as a reader-facing red error.

Latest relevant commits:

```
411198d9bb969c5812cdead2dad494d5e09cea91
feat: add free AI motion keyframes

da00154efa6f165de069d4fd02b122dd9827ea1d
feat: add motion frame provider contract

be27b8878a402d9d5803375771a20ebff44278fd
feat: connect AI motion frame generation

83923feff40b690dcf835bffb9736c1add3a10a1
fix: build motion endpoint path correctly

4b62ba0f9ad27708537be6cb5d7f351656592119
fix: normalize motion frame index

e17d18e5f0ed51334209348702b8dde93c8be260
fix: silence reader scene infrastructure errors
```

The final Flutter commit is CI green:

- Workflow: **SuperBook CI**
- Run: **249**
- Run ID: `35649688397`
- Analyze succeeded
- Tests succeeded
- Release web build succeeded

Do not call the Cloudflare Worker deployment or TEST Pages deployment green until their deployment systems report the current branch head.

# 12. CURRENT USER-VISIBLE ERROR

The user tested the deployed app and saw:

```
Animation generation failed:
Bad state: Video generation failed.
2021: Insufficient AI Gateway credits
```

That error is real and correctly identifies the current T2V billing boundary, but it came from the explicit animation action.

Commit `2d53533a6a5326fc1189d0db54a7e490b9419c8c` removes that reader-facing action from the TEST Experience and makes the still scene self-starting. The known paid T2V path is therefore no longer part of the normal reader flow.

Do not replace this with a fake animation, the old stick renderer, or generic Ken Burns motion. The next animation milestone must be a genuine story-driven capability that can operate without violating the user's no-money constraint.

# 13. R2 HISTORY

R2 was previously introduced as an I2V asset handoff mechanism.

That path was abandoned.

The Cloudflare build failed because:

```
R2 bucket 'superbook-ai-scene-assets' not found
```

The user explicitly rejected subscribing/adding R2 because of the no-money requirement.

The current `wrangler.toml` contains only:

```toml
[ai]
binding = "AI"

[observability]
enabled = true
```

There is no R2 binding.

Do not reintroduce R2.

---

# 14. CURRENT CLOUDFLARE DEPLOYMENT

Worker:

```
superbook-ai-scene
```

Root directory:

```
/cloudflare/superbook-ai-worker
```

Deploy command:

```
npx wrangler deploy
```

Production branch configured in Cloudflare Workers Builds:

```
test/superbook-ai-scene-foundation
```

Worker URL:

```
https://superbook-ai-scene.shivashisvicky112.workers.dev
```

Workers Builds is connected directly to the GitHub repository.

Pushes to the configured branch trigger deployment.

Cloudflare Workers Builds documentation confirms that connected repositories can automatically build/deploy on push and that the configured root directory and deploy command control the build.

Do not replace this with a new deployment architecture unless necessary.

---

# 15. GITHUB TEST DEPLOYMENT

SuperBook CI:

`.github/workflows/ci.yml`

Current validation sequence:

1. checkout
2. Flutter stable
3. `flutter pub get`
4. `flutter create . --platforms web`
5. remove generated widget test
6. `flutter analyze`
7. `flutter test`
8. `flutter build web --release --pwa-strategy=none --base-href "/SuperBook/test/"`

Test Pages workflow:

`.github/workflows/deploy-test-pages.yml`

It deploys:

```
/SuperBook/test/
```

and injects:

```
SUPERBOOK_AI_SCENE_ENDPOINT=https://superbook-ai-scene.shivashisvicky112.workers.dev
```

Do not modify deployment logic casually.

---

# 16. EXACT RECENT COMMITS

The AI branch has accumulated many incremental commits. The important recent sequence is:

```
b3b5a6842f7923608d668e3e8660bc0d6ea916d3
fix: stop automatic paid video attempts
```

Then:

```
2d22e3e61fa477d10fa575d09f488d3d8dc2bf41
fix: make story animation explicitly opt-in
```

Then:

```
802f07b18ea95f411a3d8be16da58d97e7d01011
feat: add explicit story animation action
```

The action-row syntax was repaired in:

```
ab8e82dd63bf364e3f617cbd1c524726beadfb9a
fix: repair scene action row syntax
```

The AI video billing boundary was documented in:

```
9a03de2fb6b41cc5dd0f9371111224a559e37210
docs: correct AI video billing boundary
```

Then the Worker scene-plan normalizer was added in:

```
dc39b5351527968e41320de1bd0563d2d97dcb05
fix: normalize AI scene plan responses
```

This tolerates Cloudflare JSON Mode responses arriving as an object, stringified JSON, fenced JSON, or a wrapped `response` object.

The latest TEST UX change is:

```
2d53533a6a5326fc1189d0db54a7e490b9419c8c
fix: make story experience self-starting
```

This commit:
- automatically starts free still-scene generation when entering an uncached Experience;
- adds a reader-facing loading state;
- removes the known-doomed paid T2V action from the reader UI;
- removes generic Ken Burns motion from the still fallback;
- preserves cached video playback if a valid video already exists.

CI for `2d53533a6a5326fc1189d0db54a7e490b9419c8c` is green:

- Workflow: **SuperBook CI**
- Run: **226**
- Run ID: `35647322394`
- Analyze, tests, and release web build all succeeded.

Do not call the TEST Pages deployment or Cloudflare Worker deployment green until those deployment systems report the new commit.

# 17. RECENT CI FAILURES AND WHAT THEY MEAN

### Run 202

Commit:

```
b3b5a684...
```

Run:

```
35637239419
```

Result:

```
SUCCESS
```

### Run 204

Commit:

```
2d22e3e61...
```

Run:

```
35637275927
```

Result:

```
FAILURE
```

Cause:

```
unused_element
_startVideoGeneration
```

This happened because automatic invocation was removed before the explicit UI action was added.

### Run 206

Commit:

```
802f07b18...
```

Run:

```
35637365488
```

Result:

```
FAILURE
```

Cause:

Malformed duplicated action-row syntax in `scene_player_screen.dart`.

That syntax was repaired by `ab8e82dd...`.

The next agent must verify the current branch with Actions rather than assuming the repair is green.

---

# 18. CURRENT TEST APP STATE

The user has visually confirmed that the generated still scene works.

Example scene:

- *Pride and Prejudice*
- Bennet family home
- Mrs. Bennet discussing Mr. Bingley
- Mr. Bennet responding sarcastically
- late 18th-century visual treatment
- generated image is visible
- narrative summary is visible

The image quality is materially different from the old deterministic renderer.

This is important:

> **Do not replace the generated-image path with the old 2D/stick-figure renderer.**

The user explicitly rejected that old experience.

The old deterministic renderer may remain as a development fixture or historical reference, but it is not the desired real Experience implementation.

---

# 19. ORIGINAL PRODUCT DIRECTION

SuperBook is not intended to be:

```
Book -> random moving picture
```

It is intended to be:

```
Book passage
    ->
AI understands literary moment
    ->
Narrative ScenePlan
    ->
coherent visual interpretation
    ->
cinematic story experience
```

The book is canonical.

AI is the interpretation layer.

Generated media is presentation.

The Experience must preserve the meaning of the literary moment.

---

# 20. SCENE PIPELINE

The intended long-term pipeline is:

```
source passage
      |
      v
entity/event understanding
      |
      v
narrative graph resolution
      |
      v
narrative beat
      |
      v
ScenePlan
      |
      +--------------------+
      |                    |
      v                    v
visual asset generation   animation generation
      |                    |
      +---------+----------+
                |
                v
          Scene Player
                |
                v
             cache
```

Current implementation has not yet completed the full narrative graph.

The current AI scene plan is the first real implementation of the interpretation layer.

---

# 21. CACHE RULE

Scene cache file:

`lib/services/scene_generation/scene_generation_cache.dart`

Cache identity:

```
bookId + chapterId + source passage hash
```

Do not key only on a generated prompt.

The source passage is canonical.

If the source passage changes, the scene must be considered a new scene.

---

# 22. JARVIS-OS LESSONS THAT MUST BE APPLIED

The user specifically asked for SuperBook continuation to follow the engineering discipline learned from JARVIS-OS.

Reference repository:

`shivashisvicky/Jarvis-OS`

Reference handoff:

`JARVIS-OS-TEST-HANDOFF.md`

Reference TEST branch:

```
test/jarvis-intelligence-next
```

Reference TEST URL:

```
https://shivashisvicky.github.io/Jarvis-OS/test/
```

Important JARVIS rules that apply directly to SuperBook:

1. Never modify `main` for TEST work.
2. Work on isolated TEST branches.
3. Do not alter deployment infrastructure to solve application behavior.
4. Prefer small surgical commits.
5. Preserve working capabilities.
6. Inspect history before changing mature code.
7. After every push, inspect the corresponding Actions run.
8. Never call a deployment green without actual CI success.
9. Do not ask the user to proceed when the engineering next step is obvious.
10. If a regression appears, identify the responsible layer before changing unrelated code.
11. Keep a detailed handoff updated.
12. Treat the user-visible TEST deployment as the validation surface.
13. Do not make a broad rollback when a localized fix is possible.
14. Separate surface-specific authority from generic shared state.
15. Measure asynchronous latency before changing timeouts or adding artificial delays.

JARVIS also demonstrated that small deployment-only trigger commits can be useful when a deployment system needs a new push event. Do not copy that pattern blindly into SuperBook. Use it only when the deployment system genuinely requires a trigger.

---

# 23. JARVIS DEPLOYMENT DISCIPLINE

JARVIS uses a TEST-first workflow:

```
change
  ->
commit
  ->
CI
  ->
TEST deployment
  ->
user validates
  ->
PR to main
  ->
production
```

SuperBook should follow the same discipline.

For SuperBook AI:

```
Flutter change
  ->
SuperBook CI
  ->
SuperBook TEST Pages

Worker change
  ->
Cloudflare Workers Builds
  ->
Worker deployment
  ->
live Worker URL
```

Do not assume a GitHub Actions green check means the Cloudflare Worker is deployed.

Do not assume a Cloudflare deployment means Flutter Pages is deployed.

Both surfaces need independent verification.

---

# 24. CURRENT PR STATUS

PR #2:

```
https://github.com/shivashisvicky/SuperBook/pull/2
```

Title:

```
AI Experience: scene planning and generated visual foundation
```

It is still a **draft**.

Do not merge it yet.

Reason:

- current T2V capability is billing-blocked;
- latest Flutter CI must be verified;
- the complete Experience needs user validation;
- production architecture is not yet finalized.

---

# 25. WHAT NOT TO DO NEXT

Do NOT:

- add R2;
- buy AI Gateway credits;
- enable Unified Billing;
- upgrade Workers Paid;
- silently substitute a paid video model;
- retry the same failed T2V call repeatedly;
- reintroduce automatic video generation;
- revert the generated-image architecture;
- restore stick-figure rendering as the real Experience;
- rewrite the entire scene player;
- rewrite the Gutenberg parser;
- touch the old camera architecture just because it still exists in the repository;
- modify main;
- merge PR #2;
- call the T2V feature working;
- claim the current animation failure is a quota reset issue.

The exact error is billing classification/credit requirement.

---

# 26. IMMEDIATE NEXT ENGINEERING STEP

The next agent should first:

### Step 1
Inspect current branch HEAD and confirm:

```
test/superbook-ai-scene-foundation
```

### Step 2
Inspect the latest SuperBook CI run after:

```
ab8e82dd...
9a03de2f...
```

If CI is red, fix only that concrete failure.

### Step 3
Inspect the current TEST Pages deployment corresponding to the latest green commit.

### Step 4
Do not trigger T2V again unless the user explicitly wants to demonstrate the known billing failure.

### Step 5
Decide the no-money animation strategy.

There are only two legitimate directions:

#### Option A: Find a genuinely free-compatible animation model/service

Requirements:

- verify current billing classification;
- verify actual free availability;
- no payment method/credits;
- no hidden paid fallback;
- acceptable API/runtime behavior;
- preferably provider-neutral interface remains unchanged.

#### Option B: Keep animation capability dormant and make the still Experience the current complete free-tier milestone

This is acceptable if no free T2V option exists.

The architecture should remain provider-neutral so a future free or user-funded provider can be added without rewriting the Experience.

---

# 27. IMPORTANT PRODUCT DECISION FOR FUTURE ANIMATION

The desired animation is:

```
paragraph
  ->
AI understands paragraph
  ->
2-3 sentence narrative summary
  ->
story animation based on that summary
```

Not:

```
paragraph
  ->
generic image
  ->
Ken Burns zoom
```

Not:

```
paragraph
  ->
stick figures moving around
```

Not:

```
generated still
  ->
generic image-to-video effect
```

The user explicitly rejected those weaker approaches.

If a free provider is found, preserve the narrative-driven prompt architecture.

---

# 28. CURRENT FILE MAP

### Product/domain

```
lib/domain/book.dart
lib/domain/experience/scene_plan.dart
lib/domain/experience/ai_scene_plan.dart
lib/domain/narrative/narrative_models.dart
lib/domain/narrative/narrative_services.dart
```

### Library

```
lib/features/library/library_screen.dart
lib/services/gutenberg_service.dart
```

### Reader

```
lib/features/reader/reader_screen.dart
```

### Experience

```
lib/features/scenes/scenes_screen.dart
lib/features/scenes/scene_player_screen.dart
```

### AI provider

```
lib/services/scene_generation/scene_generation_provider.dart
lib/services/scene_generation/cloudflare_scene_provider.dart
lib/services/scene_generation/scene_generation_cache.dart
```

### AI worker

```
cloudflare/superbook-ai-worker/src/index.js
cloudflare/superbook-ai-worker/wrangler.toml
```

### AI docs

```
docs/AI-SCENE-GENERATION.md
```

### Tests

```
test/domain/ai_scene_plan_test.dart
test/domain/narrative_foundation_test.dart
```

### CI/deployment

```
.github/workflows/ci.yml
.github/workflows/deploy-test-pages.yml
```

---

# 29. OLD PROTOTYPE WARNING

The original repository was a camera/page-recognition prototype.

It contains older code involving:

- camera
- permission_handler
- Android Kotlin OpenCV
- ORB page recognition
- old reader controller
- old audio scene controller

The clean v2 runtime was deliberately built from the original `main` while leaving some old files in the repository temporarily so the analyzer could continue to validate them.

The current SuperBook runtime does not depend on the old camera experience.

Do not reintroduce camera startup or permission requests into the clean web runtime.

A future cleanup milestone may delete the obsolete prototype tree and remove unused dependencies.

That cleanup is separate from the current AI animation investigation.

---

# 30. GUTENBERG / READER STABILITY

The real Gutenberg reader path is working and must not be casually disturbed while solving AI animation.

Known parser history includes serious accidental regressions from malformed edits.

A known good parser repair is:

```
d7ec0868a68f48ff793af7c6146f4754abc2debb
fix: restore complete Gutenberg parser after heading repair
```

That repair fixed a punctuation-only chapter heading that appeared as `]` in the Scene Player AppBar.

Current user-visible Chapter 2 title is correct.

Do not touch Gutenberg parser code for an AI Worker problem.

---

# 31. CURRENT SCENE PLAYER SAFETY RULE

The scene player should always degrade in this order:

```
video available
    -> play video

video unavailable but generated image available
    -> show generated image

scene generation unavailable
    -> show deterministic/empty development state
       without pretending it is cinematic AI output
```

Do not present a deterministic placeholder as if it were generated cinematic content.

---

# 32. FUTURE AI PROVIDER ABSTRACTION

The provider abstraction already exists so Cloudflare does not become permanently embedded into the product model.

Current interface:

```dart
abstract interface class SceneGenerationProvider {
  Future<GeneratedScene> generate({
    required String bookId,
    required String chapterId,
    required String passage,
    String? author,
    String? title,
  });

  Future<GeneratedVideo> generateVideo({
    required AiScenePlan plan,
  });
}
```

This is intentional.

If a free animation provider becomes available, implement another provider rather than rewriting:

- ScenePlayer
- Book model
- ScenePlan
- cache
- narrative architecture

---

# 33. QUALITY BAR

A future AI Experience must satisfy all of these:

### Narrative fidelity

The visual event must correspond to the passage.

### Character fidelity

Characters must not randomly mutate between frames/shots.

### Environmental fidelity

The setting must correspond to the book moment.

### Temporal fidelity

The scene must depict the correct moment, not a later event.

### Motion quality

Movement should be physically plausible.

### Cinematic quality

Camera, lighting, composition, and pacing should feel intentional.

### No hallucinated plot

The animation must not invent a major new event.

### No generic motion loops

The animation must be tied to the literary moment.

### Progressive UX

The generated still should appear without waiting for the video.

### Offline/caching compatibility

Expensive generated output should be cacheable.

---

# 34. LONG-TERM EXPERIENCE ROADMAP

### Phase 1
Current:

```
real book
  ->
AI scene plan
  ->
generated still
```

### Phase 2
Free/viable story animation:

```
scene plan
  ->
narrative-driven video
```

### Phase 3
Multi-shot scenes:

```
passage
  ->
beats
  ->
shot list
  ->
multiple coherent shots
```

### Phase 4
Narration synchronization:

```
text
  ->
narration
  ->
scene timing
  ->
visual pacing
```

### Phase 5
Chapter continuity:

Characters, clothing, locations, and visual language persist across scenes.

### Phase 6
Offline intelligence:

Downloaded books retain:

- source text
- narrative graph
- reader position
- cached scene plans
- cached generated media

---

# 35. HANDOFF CHECKLIST

Before declaring this work complete, the next agent must verify:

- [ ] current branch is `test/superbook-ai-scene-foundation`
- [ ] no work is being done on `main`
- [ ] latest CI is green
- [ ] latest TEST Pages deployment is green
- [ ] current Worker deployment is current
- [ ] generated scene image still works
- [ ] narrative summary still works
- [ ] automatic T2V generation remains disabled
- [ ] animation is explicit opt-in
- [ ] no R2 binding exists
- [ ] no paid credentials were added
- [ ] no AI Gateway credits were purchased
- [ ] no Workers Paid upgrade was introduced
- [ ] T2V failure is understood as third-party billing requirement
- [ ] no repeated pointless T2V retries are being triggered
- [ ] reader still opens
- [ ] Gutenberg parser still works
- [ ] Chapter 2 no longer displays `]`
- [ ] old camera runtime is not reactivated
- [ ] PR #2 remains draft
- [ ] production is untouched

---

# 36. EXACT NEXT-AGENT MESSAGE

Paste the following into the next agent as the continuation instruction:

> **SuperBook continuation. Read `docs/SUPERBOOK-AI-SCENE-HANDOFF.md` completely before changing anything.**
>
> Work only on `test/superbook-ai-scene-foundation`. Do not touch `main`.
>
> The current product state is: real Gutenberg books work, the AI Scene Director works, the AI-generated still image works, the narrative scene summary works, and the Experience player works. The old stick-figure renderer is NOT the desired real Experience and must not be restored.
>
> The current T2V animation path is architecturally implemented but **blocked by billing**. The exact live Cloudflare Worker error is:
>
> ```
> 2021: Insufficient AI Gateway credits
> ```
>
> The selected model is:
>
> ```
> alibaba/hh1.1-t2v
> ```
>
> Cloudflare currently classifies that model as a **third-party** model. The Workers AI 10,000-Neuron free allocation does NOT make this model free. The user explicitly said **NO MONEY**. Do not ask for AI Gateway credits, Unified Billing, Workers Paid, R2, prepaid credits, or another paid service.
>
> Automatic video generation was deliberately disabled because it was repeatedly making a doomed paid-capable request. Animation is now explicit opt-in.
>
> Recent relevant commits:
>
> ```
> b3b5a6842f7923608d668e3e8660bc0d6ea916d3
> fix: stop automatic paid video attempts
>
> 2d22e3e61fa477d10fa575d09f488d3d8dc2bf41
> fix: make story animation explicitly opt-in
>
> 802f07b18ea95f411a3d8be16da58d97e7d01011
> feat: add explicit story animation action
>
> ab8e82dd63bf364e3f617cbd1c524726beadfb9a
> fix: repair scene action row syntax
>
> 9a03de2fb6b41cc5dd0f9371111224a559e37210
> docs: correct AI video billing boundary
> ```
>
> The action-row commit `802f07b...` failed CI because of duplicated syntax. `ab8e82dd...` repaired it. Verify current CI instead of assuming it is green.
>
> Current Worker:
>
> ```
> https://superbook-ai-scene.shivashisvicky112.workers.dev
> ```
>
> Current TEST:
>
> ```
> https://shivashisvicky.github.io/SuperBook/test/
> ```
>
> PR #2 is still draft:
>
> ```
> https://github.com/shivashisvicky/SuperBook/pull/2
> ```
>
> First inspect the current branch, latest GitHub Actions run, latest Pages deployment, and current Worker deployment. Do not make a speculative code change.
>
> Then determine whether there is a genuinely free T2V option. If there is, verify its current Cloudflare billing classification before implementing it. If there is not, keep the generated still Experience as the current free-tier milestone and leave the provider abstraction ready for a future animation provider.
>
> Follow JARVIS-OS discipline: small surgical commits, inspect CI after every push, never call a deployment green without actual Actions success, do not broad-rollback, do not modify unrelated working functionality, and update this handoff after significant changes.


---

# 37. 2026-09-22 VERIFICATION: FREE T2V INVESTIGATION

A fresh billing/model-catalog investigation was performed before considering any animation-provider change.

## Cloudflare result

Cloudflare's current AI model catalog lists `alibaba/hh1.1-t2v` as **Third-party**, with pricing listed. The dedicated model page documents the same classification and the `alibaba/hh1.1-t2v` API contract.

Cloudflare's current Workers AI pricing still provides 10,000 Neurons/day on the Free plan, but that allocation applies to Workers AI usage. Third-party models are handled through AI Gateway / Unified Billing and are not made free by the Workers AI allocation.

Result:

```
alibaba/hh1.1-t2v
    -> Third-party
    -> AI Gateway / Unified Billing
    -> not a no-money T2V option
```

## Other free candidates checked

### Hugging Face Inference Providers

Hugging Face currently gives Free users a small monthly Inference Providers credit allocation, currently documented as **$0.10/month**, with pay-as-you-go after the included credits. This is not a guaranteed free T2V service and does not satisfy SuperBook's no-money production requirement.

Hugging Face does expose open T2V models such as Wan 2.1 and LTX through inference providers, but the provider infrastructure is billed through the Hugging Face account/provider path. The free credit is an introductory allowance, not an unlimited or durable free backend.

### Hugging Face ZeroGPU Spaces

Hugging Face ZeroGPU Spaces are genuinely free to use within daily quota. Free accounts currently receive 5 minutes/day of GPU quota, while unauthenticated usage receives 2 minutes/day. However, ZeroGPU is a shared Gradio Space runtime with queue/quota behavior, not a stable provider contract for SuperBook's production Worker path. It also consumes the caller's ZeroGPU quota and is therefore unsuitable as the application's dependable animation backend.

A public ZeroGPU Space can remain a future experimental test avenue, but it must not be promoted to the production SceneGenerationProvider without a concrete reliability, quota, API, and ownership decision.

## Decision

**No genuinely free, production-compatible T2V provider has been identified in this verification pass.**

Therefore:

- do not replace the current Cloudflare T2V model;
- do not add a paid provider;
- do not add Hugging Face as a hidden billing dependency;
- do not add R2;
- do not alter the narrative-driven T2V contract;
- keep the existing still-image Experience as the no-money milestone;
- keep `SceneGenerationProvider.generateVideo()` provider-neutral for a future viable provider.

The current architecture is therefore intentionally split:

```
book passage
   -> ScenePlan
   -> generated still
   -> current free Experience milestone

ScenePlan
   -> generateVideo()
   -> dormant/explicit opt-in until a genuinely viable provider exists
```

## Important source verification

During this continuation pass, the actual PR source was inspected rather than relying only on the previous handoff description. The scene player contained three automatic video-generation paths that contradicted the documented opt-in behavior:

1. cached scenes attempted T2V during `initState()`;
2. cached scenes attempted T2V inside `_generate()`;
3. newly generated scenes automatically attempted T2V after image generation.

These were removed surgically. The explicit **Animate story** action remains the only path that calls `_startVideoGeneration()`.

The repair commit is:

```
d28a68e87b38b35bf09bbd1fe0bd5efc4f35a982
fix: repair opt-in animation syntax
```

The preceding surgical removal commit was:

```
2a8cb57a11ce67d56ba31f25d778710699211f43
fix: keep story animation explicitly opt-in
```

The first attempt was intentionally not retained because it introduced a syntax error; CI caught it. The final repair was re-run through CI.

CI run:

```
35644898070
SuperBook CI
SUCCESS
```

All validation stages completed successfully, including:

- `flutter analyze`
- `flutter test`
- `flutter build web --release --pwa-strategy=none --base-href "/SuperBook/test/"`

This section is authoritative over any older statement in this handoff that automatic video generation had already been removed from the source tree.

---

# 38. 2026-09-22 MOTION PRESENTATION REFINEMENT

The motion-keyframe Experience was visually validated on TEST with two distinct AI-generated story states for the same literary scene. The generated frames preserve the room, characters, clothing, and composition while changing character acting between narrative beats.

A surgical presentation fix was then applied in:

```
e45513fb8cea950778804a20303ce31f5e6e9510
fix: fill scene stage and smooth motion transitions
```

This change:
- makes the generated still and motion-frame visual fill the complete Scene Player stage instead of leaving intrinsic image sizing to the Stack;
- keeps the cinematic crop controlled by BoxFit.cover;
- changes motion-frame transitions from a shorter 650ms switch to a 900ms ease-in-out cross-fade;
- stacks previous/current frames during the transition so the generated story states blend rather than resize/jump;
- does not add camera movement, Ken Burns effects, deterministic animation, T2V, R2, or paid infrastructure.

CI for this commit is green:
- Workflow: SuperBook CI
- Run: 253
- Run ID: 35650669864
- flutter analyze: success
- flutter test: success
- flutter build web --release: success

The free AI motion-keyframe architecture remains unchanged. The current animation is still a generated-frame cinematic sequence, not fluid T2V animation.

# 39. 2026-09-22 READER-FIRST GUTENBERG STRUCTURE REFINEMENT

The current product direction has been corrected based on TEST validation of real Gutenberg books.

## Problem observed

Some books, including Sherlock Holmes material, do not use literal `CHAPTER ...` headings. The previous parser could collapse an entire book or collection into one giant reading unit.

Project Gutenberg / Arthur Conan Doyle material commonly uses structures such as `ADVENTURE I. A SCANDAL IN BOHEMIA` and Roman-numeral sections. The parser must preserve the source's logical structure rather than assuming every work is a conventional chaptered novel.

## Implemented

Branch:

`test/superbook-ai-scene-foundation`

Parser commit:

`dfff8f12e827aa68346231c35d9b70c793f40ea0`

The Gutenberg parser now recognizes:

- conventional `CHAPTER I` / `CHAPTER 1`;
- `ADVENTURE I`, `STORY I`, `PART I`, and `BOOK I` style headings;
- standalone Roman-numeral section headings when followed by substantive prose;
- substantive all-caps structural headings, while excluding common front-matter headings and Roman-numeral table-of-contents lines.

The existing table-of-contents filtering remains in place so a contents listing is not treated as story prose.

Reader UX commit:

`9612a01758ecaddc523b9d1cba2fd0e36289c4f3`

Reader navigation now uses "Section" terminology for non-Chapter structures while retaining "Chapter" for conventional chapter titles.

Tests cover:

- existing Moby-Dick-style CHAPTER parsing;
- Sherlock-style ADVENTURE headings;
- standalone Roman-numeral sections.

## Product direction

The Experience layer remains optional and cached. The canonical product flow is now:

`real book structure -> reader -> meaningful story section -> optional AI Experience`

Do not generate AI scenes for every section by default. Reading must remain useful and responsive without waiting for AI media generation.

## Validation

Latest head:

`dfff8f12e827aa68346231c35d9b70c793f40ea0`

SuperBook CI runs 278 and 279: success.

TEST Pages run 171: success.

No paid infrastructure, R2, AI Gateway credits, or T2V changes were introduced by this reader-structure refinement.


# 40. 2026-09-22 RESILIENT BOOK CATALOG PROVIDER

The TEST Library no longer depends on Gutendex for catalog discovery.

## Problem observed

The Library was showing only its loading state because the live catalog request through Gutendex was unavailable. This made the real-book Library appear empty even though the parser and reader were healthy.

## Implemented

The branch now uses:

```
Open Library
   -> public/readable catalog discovery
   -> Internet Archive public text when an IA edition is available
   -> Project Gutenberg direct text for curated fallback classics
```

Open Library is the discovery/catalog layer. The book reader still consumes canonical plain text and the existing Gutenberg parser remains the structure parser.

New service:

`lib/services/open_library_service.dart`

It provides:

- public-domain catalog search;
- author/title search;
- Open Library covers;
- Internet Archive plain-text resolution from public IA identifiers;
- direct Gutenberg text fallback for curated classics;
- local classic-book catalog fallback when the discovery service is unavailable.

The curated fallback prevents the Library from becoming an empty loading screen during a catalog outage.

The existing Gutenberg parser was deliberately reused through:

`GutenbergService.parseText(...)`

This avoids duplicating the already-tested chapter/section parsing logic.

Library UI now uses the provider-neutral `LibraryBookSummary` and no longer labels the catalog itself as Gutenberg-only.

## Validation

Final branch head:

`668b4abba41cb830356598a61271b38f92023554`

SuperBook CI:

- Run 297
- Run ID `35682341311`
- success
- analyze: success
- tests: success
- release web build: success

TEST Pages:

- Run 180
- Run ID `35682336630`
- success

The failed intermediate CI runs were fixed incrementally and are not the final state.

No changes were made to:

- AI Worker;
- scene generation;
- motion keyframes;
- T2V billing path;
- R2;
- paid infrastructure.

## Product direction

The Library is now:

`provider discovery -> trusted public text -> existing reader/parser -> optional AI Experience`

The catalog provider is no longer a single point of failure for the entire Library.
\n---\n\n# 41. 2026-09-22 Worker + Gutenberg parser repair\n\n- The Cloudflare Workers Build for commit `b0f0be45` failed because `cloudflare/superbook-ai-worker/src/index.js` was truncated at the image response (`src/index.js:442:33`).\n- The Worker source was repaired without changing the model architecture. Cloudflare subsequently reported a successful production deployment for commit `647c63fb`.\n- The latest Flutter CI run for commit `cbfc6207` is green, including analyze, all tests, and web release build.\n- The Art of War catalog entry exposed OCR/page-reference debris as reader-visible sections, including `* X 2JBJI ff IH S 1` and `Cf. III. § 13 (i)`. These are not real chapters. The parser now treats explicit numbered chapter/adventure/roman sections as authoritative and rejects OCR/reference noise as structural headings.\n- Regression coverage was added for this exact OCR pattern. Do not restore generic all-caps structural headings as chapter boundaries when explicit numbered sections are present.\n

# 42. 2026-09-22 Art of War chapter-boundary repair

The TEST screenshot exposed a concrete regression: The Art of War was presenting only six reader sections (Chapter C, Chapter V, Chapter VI, Chapter VII, Chapter X, Chapter XIII) instead of the source's 13 titled chapters. The apparent Roman markers were OCR/page artifacts, not valid chapter boundaries.

The parser was repaired surgically on test/superbook-ai-scene-foundation.

## Implemented

- Restored lib/services/gutenberg_service.dart to the last known-good parser implementation after the intermediate Roman-heading edit had duplicated/corrupted the file.
- Added recognition for titled Roman sections such as I. LAYING PLANS, while retaining conventional CHAPTER I, ADVENTURE I, and standalone Roman support.
- Supports optional Markdown-style heading prefixes without changing the source line position used for chapter slicing.
- When a Gutenberg edition repeats numbered headings in its table of contents and in the actual text, duplicate numbered markers now resolve to the later, substantive occurrence rather than the contents entry.
- Titled Roman sections take precedence over standalone Roman numerals, preventing OCR/reference markers from becoming chapters.
- Titled Roman validation rejects numeric/reference debris and supports source titles containing characters such as OE.
- Added regression coverage for the exact three-chapter OCR pattern and a full 13-chapter Art of War fixture.

Key commits:

127542953946055fc5d508e908ed5dbd31ac2e1e
5c0afc722c104784a3fa4d67fd8ea416bae5a495
43e25426f9d108b242f50ba7f3f54dab84f37bb7
8acc97c249728f2cf79b84ec979a64d3c56d0476
409e18813158f83a749bdf5cd79ae66670e2b122
876e27265e6119ae8f6e42486dc8dece5cc8b626

## Validation

Final parser/test head:

876e27265e6119ae8f6e42486dc8dece5cc8b626

SuperBook CI run 366: SUCCESS
- flutter analyze: success
- flutter test: success
- flutter build web --release: success

TEST Pages run 215: SUCCESS
- Build test web app: success
- Deploy test Pages: success

The deployed TEST app is therefore ready for validation. Do not treat the older six-section screenshot as the current parser state.

No AI model, T2V, R2, billing, or paid infrastructure changes were introduced by this parser repair.

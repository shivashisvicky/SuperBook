# SuperBook AI Puppet / Living Illustration Handoff

**Date:** 2026-09-24  
**Repository:** `shivashisvicky/SuperBook`  
**Current handoff branch:** `test/superbook-puppet-assets`  
**Primary existing AI branch:** `test/superbook-ai-scene-foundation`  
**Do not merge this branch into `main` or the existing AI PR without completing the gates below.**

---

## 1. What the project is trying to achieve

SuperBook is intended to turn a literary passage into a **living illustrated story moment**.

The target is NOT:

- a static AI image;
- a slideshow of 2-3 AI-generated images;
- camera pan/zoom presented as character animation;
- primitive vector/stick characters;
- a paid text-to-video service;
- per-frame AI inference.

The target is:

**literary passage → AI scene direction → beautiful illustrated scene → animation-ready character assets → local articulated puppet → continuous acting**

The browser/Flutter runtime should own the animation timeline. AI should decide the scene and prepare artwork/assets, but should not be called for every animation frame.

### Desired example scene

A detailed illustrated room containing two characters, where one can:

1. enter;
2. walk;
3. settle/sit;
4. talk;
5. gesture;
6. reach toward food;
7. eat;
8. listen/react;
9. return to idle.

The environment should feel like a proper illustrated storybook/cartoon scene, while the characters have real articulated motion.

---

## 2. Important discovery from the previous POCs

The old supplied `SuperBook_Real_Scene_MIN(1).html` is **not a suitable visual foundation**.

Its embedded background is only approximately 709×890 and is already visibly pixelated. Attempts to crop/mask its head/hands and rotate those pieces produced the exact “moving stones” effect the user rejected.

Therefore:

**Do not spend more time polishing that asset.**

Historical branches/POCs include:

- `poc/superbook-living-scene`
- `poc/superbook-living-scene-v2`
- `poc/ai-directed-puppet`
- `poc/illustrated-story-scene`
- `poc/cinematic-illustrated-scene`
- `poc/ai-illustrated-keyframe`

They are useful for history/research, not as the final visual implementation.

---

## 3. What was tested successfully

### AI-directed primitive puppet

Branch:
`poc/ai-directed-puppet`

This proved that the browser can execute an AI-supplied action timeline locally.

It had actions such as idle/look/gesture/nod/reaction.

It was technically alive, but visually primitive.

### Illustrated room

Branch:
`poc/illustrated-story-scene`

This added a richer room, bed, cabinet, window, lamp, side table, food tray and two characters.

The user explicitly rejected it as still looking like assembled primitive/vector shapes.

### AI-generated keyframe

Branch:
`poc/ai-illustrated-keyframe`

This was a major visual improvement.

The Worker generated a proper illustrated literary scene using FLUX.

Hosted historical POC:

https://raw.githack.com/shivashisvicky/SuperBook/8d90a82f61dbffeddaaa85957c5a6e5d30bb3414/poc/ai_illustrated_keyframe/index.html

The user accepted that the artwork looked substantially better, but correctly rejected the subsequent implementation because it generated three separate images.

### AI motion experiment

Commit:

`8d90a82f61dbffeddaaa85957c5a6e5d30bb3414`

The `/motion` endpoint used FLUX.2 Klein image editing to create three acting states from one image.

This was **not real animation**.

The browser merely displayed those still images sequentially/crossfaded them.

The user identified this immediately:

> “This time 3 photos and the third one was animated while other 2 were different. Again pics?”

That experiment is therefore explicitly **not the desired solution**.

---

## 4. Current branch

### `test/superbook-puppet-assets`

Current relevant commits:

- `1a92a9310990153e7faff20c2c59397dc828799a`
  - adds Worker `POST /puppet-sheet`
- `dadb941e7f8cb74859f0514b0a0a11d97908b58a`
  - adds puppet-sheet live smoke-test contract
- `81fb1a4cd9adf8ddbe069250ac990d0f6af8aed2`
  - adds `poc/puppet_asset_lab/index.html`

There is also an earlier isolated runtime foundation:

### `poc/puppet-runtime-foundation`

Commits:

- `5b6703400b610f2cd90b6f6b8b07b1a09b2674bc`
  - runtime/asset architecture README
- `682ddd08569619f5f4aeaf56131c49d3b7645fdc`
  - local `PuppetRuntime` foundation and asset schema

The runtime foundation is deliberately small and dependency-free.

---

## 5. CURRENT BLOCKER: puppet lab endpoint is not deployed

The user tested:

https://raw.githack.com/shivashisvicky/SuperBook/81fb1a4cd9adf8ddbe069250ac990d0f6af8aed2/poc/puppet_asset_lab/index.html

The page returned:

**ASSET ERROR · passage is required.**

This is important.

The lab calls:

`POST https://superbook-ai-scene.shivashisvicky112.workers.dev/puppet-sheet`

but the live Worker currently does not contain the new `/puppet-sheet` route.

The live Worker therefore falls through to the existing root POST handler, which expects a literary `passage`, producing:

`passage is required.`

### Do NOT misdiagnose this as an image-model failure.

The failure occurs before the intended puppet-sheet model path is reached.

### Required next step

Deploy the Worker code from:

`test/superbook-puppet-assets`

using the project's existing Cloudflare deployment mechanism, then run:

`/.github/workflows/superbook-worker-smoke.yml`

The smoke workflow now tests BOTH:

1. existing `/` scene-generation contract;
2. new `/puppet-sheet` contract.

The puppet smoke test expects:

- HTTP 200;
- `schemaVersion == "1"`;
- `assetType == "animation-ready-character-sheet"`;
- non-empty base64 image payload.

Only after that should the user retest the Puppet Asset Lab.

---

## 6. Worker architecture that must be preserved

Current Worker:

`cloudflare/superbook-ai-worker/src/index.js`

Existing models:

- text: `@cf/meta/llama-3.3-70b-instruct-fp8-fast`
- scene image: `@cf/black-forest-labs/flux-1-schnell`
- image editing/motion experiment: `@cf/black-forest-labs/flux-2-klein-4b`
- explicit video path: `alibaba/hh1.1-t2v`

The T2V route is **not** the default solution and should not be enabled merely to make the POC look better.

### No-money boundary

This project has an explicit no-money constraint.

Do not add:

- Cloudflare AI Gateway credits;
- Workers Paid;
- Unified Billing;
- R2;
- paid third-party image/video APIs;
- Runway;
- PixVerse;
- other paid T2V providers.

Workers AI free allocation is the intended boundary for controlled experiments.

---

## 7. New `/puppet-sheet` endpoint

The current branch adds:

`POST /puppet-sheet`

Input:

```json
{
  "character": "description of one character"
}
```

The current implementation asks the image model for:

- one character;
- solid chroma-blue background;
- separated head;
- torso;
- upper/lower arms;
- hands;
- upper/lower legs;
- feet;
- neutral full-body reference;
- consistent identity/clothing/proportions;
- literary storybook illustration;
- no labels/watermarks/UI.

Response contract:

```json
{
  "schemaVersion": "1",
  "mimeType": "image/png",
  "base64": "...",
  "assetType": "animation-ready-character-sheet",
  "sourceModel": "..."
}
```

### Important engineering warning

The endpoint currently uses:

`@cf/bytedance/stable-diffusion-xl-lightning`

This was introduced as a free controlled asset-generation experiment.

The next agent MUST verify that this exact model is currently available on the project's Workers AI account before treating the endpoint as valid.

If unavailable, replace it with a currently available **free Workers AI image model**, while preserving the endpoint contract.

Do not silently switch to a paid provider.

---

## 8. The runtime architecture

File:

`poc/puppet_runtime_foundation/puppet_runtime.js`

The intended asset schema has semantic parts:

- `head`
- `torso`
- `armR`
- `handR`
- `armL`
- `handL`
- `legR`
- `legL`

with pivots such as:

- neck
- spine
- shoulderR
- elbowR
- shoulderL
- elbowL
- hipR
- hipL

Supported actions:

- idle
- walk
- talk
- gesture
- eat
- listen

The runtime uses deterministic continuous motion:

- breathing;
- head movement;
- arm rotation;
- hand rotation;
- action timing.

This is only the foundation. It is **not yet connected to real generated character parts**.

---

## 9. What the next agent should build

### Phase A: prove the asset sheet

1. Deploy `test/superbook-puppet-assets` Worker.
2. Run the smoke test.
3. Open Puppet Asset Lab.
4. Inspect the actual generated character sheet.

Do not proceed if the sheet itself looks like disconnected blobs, primitive vectors, bad anatomy, or inconsistent character identity.

### Phase B: extract parts

Build a small deterministic browser-side asset preparation layer.

The first POC can use fixed regions/chroma segmentation if the generated sheet follows the expected blue-background layout.

Output should become:

- transparent head;
- transparent torso;
- transparent upper/lower arms;
- transparent hands;
- transparent legs;
- full-body fallback.

Store pivot metadata separately.

Do not attempt sophisticated AI segmentation in the Worker unless there is a clear free/runtime-safe implementation.

### Phase C: real puppet

Render the extracted parts in a canvas.

Implement actual hierarchy:

`torso → shoulder → upper arm → elbow → lower arm → hand`

and:

`torso → neck → head`

Add:

- breathing;
- head turns;
- shoulder response;
- elbow motion;
- wrist/hand gesture;
- reach-to-food;
- hand-to-mouth eating;
- listening tilt;
- walk cycle.

The animation should be continuous, not frame swapping.

### Phase D: two-character room

Only after one character works:

- generate the detailed room/background separately;
- add character 2;
- add deterministic interaction targets;
- make character 1 talk while character 2 listens;
- make character 1 reach/eat;
- make character 2 react.

### Phase E: AI scene director

Connect the existing ScenePlan to the puppet runtime.

AI decides:

- who acts;
- action order;
- emotion;
- target;
- duration;
- interaction;
- camera/lighting intent.

Runtime translates those instructions into local animation.

AI does NOT generate every frame.

---

## 10. Existing SuperBook production path

The current main AI work is on:

`test/superbook-ai-scene-foundation`

PR #2:

https://github.com/shivashisvicky/SuperBook/pull/2

Head at the documented checkpoint:

`4ace91435bc75193411926b9b1afae8c2a26e0bb`

That branch already has:

- canonical scene-generation path;
- structured ScenePlan;
- Llama 3.3 70B JSON mode;
- FLUX scene keyframe;
- local cinematic Flutter stage;
- explicit motion/video providers;
- Worker health endpoint;
- live Worker smoke test.

Do not replace that architecture with the puppet POC wholesale.

The puppet work is an **extension experiment**.

---

## 11. Existing Worker smoke gate

Workflow:

`.github/workflows/superbook-worker-smoke.yml`

It checks:

- Worker health;
- service name;
- schema version;
- live scene generation;
- ScenePlan structure;
- generated image payload;
- now also puppet-sheet output.

A green smoke test proves the API contract and deployment path.

It does **not** prove visual quality.

---

## 12. TEST Pages deployment

TEST Pages workflow:

`.github/workflows/deploy-test-pages.yml`

It triggers on:

`test/**`

and deploys:

`https://shivashisvicky.github.io/SuperBook/test/`

Worker endpoint:

`https://superbook-ai-scene.shivashisvicky112.workers.dev`

The workflow passes the Worker endpoint through:

`SUPERBOOK_AI_SCENE_ENDPOINT`

Do not assume that pushing a Worker-only branch automatically deploys the Worker unless the actual Cloudflare deployment mechanism is present and verified.

The current repository workflow directory contains:

- `.github/workflows/ci.yml`
- `.github/workflows/deploy-test-pages.yml`
- `.github/workflows/superbook-worker-smoke.yml`

There is no obvious Wrangler deployment workflow in the repository from the current inspection.

Therefore the next agent must verify the actual Cloudflare deployment mechanism rather than claiming a Worker deployment occurred.

---

## 13. User feedback that must not be lost

The user has repeatedly rejected:

### Static AI artwork
They want something happening inside the scene.

### Camera pan/zoom
They explicitly clarified that they do **not** want pan/zoom used as the animation.

### Three AI images
They explicitly noticed that the motion experiment was just different pictures.

### Primitive vector characters
The user described the earlier result as “moving sticks/stones” and rejected that visual quality.

### Fake animation
Do not label crossfades, camera drift, or image swaps as character animation.

The quality bar is:

**beautiful illustrated characters + continuous articulated motion.**

---

## 14. What NOT to do next

Do not:

- ask the user to test the current broken Puppet Asset Lab again before deploying the Worker;
- merge this experiment into `main`;
- overwrite the existing working scene-generation path;
- introduce a paid video API;
- use T2V as a shortcut;
- create another slideshow;
- add more debug buttons instead of improving the actual animation;
- use the old pixelated scene as the final character source;
- claim success without seeing/verifying the generated asset;
- call a green API smoke test a visual-quality pass.

---

## 15. Immediate next-agent checklist

**First:**

- [ ] Deploy `test/superbook-puppet-assets` Worker.
- [ ] Confirm `GET /health`.
- [ ] Run Worker smoke workflow.
- [ ] Confirm `POST /puppet-sheet` returns HTTP 200.
- [ ] Open Puppet Asset Lab.
- [ ] Inspect generated character sheet.

**Then:**

- [ ] Decide whether the generated sheet is actually usable.
- [ ] If not usable, improve the prompt/model before building a runtime around it.
- [ ] If usable, implement semantic crop/chroma extraction.
- [ ] Connect extracted parts to `PuppetRuntime`.
- [ ] Demonstrate continuous talk/gesture/eat motion.
- [ ] Only then introduce the second character and room interaction.
- [ ] Keep all work isolated until the visual/animation gate passes.

---

## 16. Current user-facing test URL

Current Puppet Asset Lab:

https://raw.githack.com/shivashisvicky/SuperBook/81fb1a4cd9adf8ddbe069250ac990d0f6af8aed2/poc/puppet_asset_lab/index.html

**Current status:** expected to show `passage is required.` until the new Worker route is deployed.

That error is understood and documented. It is not a mysterious frontend failure.

---

## 17. Bottom line

The project is at an important architectural fork.

The previous approach proved:

**AI can produce the beautiful scene.**

The failed motion experiments proved:

**AI-generated still-to-still frames are not enough.**

The next objective is therefore not “make another prettier picture.”

It is:

> **Turn AI-generated illustrated characters into reusable local puppets and make those puppets actually act inside the scene.**

Keep the AI as the **director/asset creator** and the browser as the **actor/timeline engine**.

That is the path that preserves the no-money boundary, avoids per-frame AI, and can eventually become a real SuperBook reading experience rather than a gallery of generated pictures.

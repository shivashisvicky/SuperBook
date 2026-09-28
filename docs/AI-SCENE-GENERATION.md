# SuperBook AI Scene Generation

Last updated: 2026-09-28 IST
Branch: test/superbook-ai-scene-foundation
Current branch head when this document was refreshed: 4953f11625fa122ef7fc005e31a1ea8f87e6dfef
Repository: https://github.com/shivashisvicky/SuperBook
Worker: superbook-ai-scene
Worker URL: https://superbook-ai-scene.shivashisvicky112.workers.dev
TEST: https://shivashisvicky.github.io/SuperBook/test/

This is the AI-specific companion to docs/SUPERBOOK-AI-SCENE-HANDOFF.md. The main handoff is authoritative for the whole project. This file records the AI contracts, billing boundary, endpoints, current reader integration, known failures, and future direction.

## 1. PRODUCT CONTRACT

SuperBook is not an AI image gallery. The intended experience is:

literary passage -> AI understands the moment -> structured ScenePlan -> coherent visual scene -> local story runtime animates the scene.

The AI layer must preserve the literary moment. It must not invent unrelated plot, introduce arbitrary characters, replace the canonical book source, create a generic cinematic clip disconnected from the passage, become a per-frame dependency, or silently introduce paid services.

The local runtime must make the scene playable continuously without requiring another AI request for every frame.

## 2. CURRENT AI MODEL STACK

Worker source: cloudflare/superbook-ai-worker/src/index.js

TEXT_MODEL: @cf/meta/llama-3.3-70b-instruct-fp8-fast
IMAGE_MODEL: @cf/black-forest-labs/flux-1-schnell
MOTION_MODEL: @cf/black-forest-labs/flux-2-klein-4b
VIDEO_MODEL: alibaba/hh1.1-t2v

Text planner: literary interpretation, structured ScenePlan, reader-facing scene summary, characters, environment, props, actions, camera, lighting, motion and image prompt.

Image generator: one coherent visual keyframe for the literary moment.

Motion model: optional future image-to-image motion/keyframe experiments. This is a Workers AI @cf model path and is the current candidate for free-tier motion experiments, subject to current Cloudflare limits and actual verification.

Video model: narrative text-to-video experiment. Current status is BLOCKED and not acceptable as an automatic production dependency under the no-money requirement.

## 3. BILLING BOUNDARY

Workers AI has a documented free allocation of 10,000 Neurons/day. That does not make every model available through Cloudflare free.

alibaba/hh1.1-t2v is currently classified by Cloudflare as a third-party model. The live SuperBook /video path returned:

2021: Insufficient AI Gateway credits

Therefore do not purchase AI Gateway credits, enable Unified Billing, upgrade Workers Paid, add R2, use paid third-party APIs, or hide a paid fallback. Do not tell the user that the Alibaba T2V model is covered by the Workers AI free allocation.

If another video model is considered, verify its current billing classification first.

## 4. CURRENT SCENE PLAN CONTRACT

The Worker validates a structured ScenePlan with these top-level fields:

schemaVersion, sceneSummary, visualStyle, characters, environment, props, actions, camera, lighting, motion, imagePrompt.

Character limit: 2. Each character has id, description, action, emotion and position.
Prop limit: 3.
Action limit: 3.
Environment contains location, time and description.
Camera contains shot, angle and movement.

The model is instructed to represent principal visible people, preserve facts from the passage, avoid invented named characters and contradictory objects/locations, produce one coherent cinematic frame, describe physically plausible short motion, use subtle scene-specific camera movement, and avoid text, logos, watermarks, modern objects when not appropriate, duplicate people, extra limbs and distorted anatomy.

## 5. WORKER ENDPOINTS

GET /health
Expected service: superbook-ai-scene.
Expected scene schema version: 2.

POST / at the Worker root performs scene generation. The live smoke test expects HTTP 200, schemaVersion 2, a valid ScenePlan and a non-empty generated image payload.

POST /motion uses FLUX.2 Klein 4B. It is an optional capability, not the automatic production animation path.

POST /video uses alibaba/hh1.1-t2v. It is blocked by the billing boundary and must not become the reader's default dependency.

POST /puppet-sheet exists and is currently smoke-tested, but it is not the production reader architecture. A generated character sheet is not a complete animated story scene.

## 6. CURRENT FLUTTER FLOW

Primary reader: lib/features/scenes/scene_player_screen.dart
Provider: lib/services/scene_generation/cloudflare_scene_provider.dart
Cache: lib/services/scene_generation/scene_generation_cache.dart
Local renderer: lib/features/scenes/superbook_local_animation_stage.dart

Current flow: ScenePlayerScreen checks cache, starts Worker scene generation when needed, receives ScenePlan plus generated still, then passes the result to SuperBookLocalAnimationStage.

The local stage appears immediately while AI generation runs. The latest UX commit removed the large centered loading overlay. The Story Moment overlay remains.

## 7. CURRENT READER VIDEO STATUS

The reader still contains VideoPlayerController support and can initialize a cached video. However, the current _visual() path returns the local animation stage rather than a video widget. Therefore generated T2V video is not currently the normal reader visual path.

Do not assume that the presence of video loading code means the reader is currently using T2V video.

## 8. CURRENT READER AI IMAGE STATUS

When AI generation succeeds, generated.imageBase64 is passed into SuperBookLocalAnimationStage as backgroundImageBase64.

The local stage displays the generated image underneath its own CustomPaint actors and props.

This is the current source of the visual mismatch: the AI image is a cinematic/photographic visual interpretation while the overlay actors are deterministic Flutter vector figures. They do not currently share a true scene coordinate or anchor contract.

## 9. EXACT CURRENT VISUAL FAILURE

Latest inspected recording: /mnt/data/ScreenRecording_09-28-2026 11-42-21_1.mp4

Observed Chapter 5: an AI-generated realistic background contains realistic people while additional vector people are visibly pasted in front. The Story Moment overlay remains at the bottom.

Observed Chapter 7: a flat procedural room with a window/furniture and two stylized vector figures. No AI image is visible in that state.

Observed Chapter 8: another flat procedural room with two vector figures and a large narrative overlay.

Conclusion: the current visual architecture is not finished. Do not call it coherent cinematic animation. The central problem is that the AI visual layer and deterministic vector layer represent two different spatial worlds.

## 10. WHY IMPROVING THE VECTOR RIG ALONE IS NOT ENOUGH

The local rig already contains a head, torso/dress, articulated legs, knees, shins, feet, upper/lower arms, hands, shadows and pose interpolation.

The problem is spatial truth. AI may place a window, person and carriage anywhere in the generated image, while the local renderer currently places actors by generic index-based coordinates and the carriage at fixed screen coordinates.

Example of the current conceptual mismatch: AI image may put a window at one normalized location and a person near a table, while the renderer still puts actor zero around 30 percent of screen width and actor one around 70 percent, with a carriage at fixed coordinates.

The next architecture must make both systems operate in one scene model.

## 11. REQUIRED FUTURE AI CONTRACT

The existing ScenePlan is a strong literary foundation but is not detailed enough for reliable choreography.

The next evolution should add or derive:

1. Actor identity, such as Elizabeth, rather than relying on array position.
2. Semantic spatial anchors such as window, table, chair, door, fireplace, road and outside_window.
3. Actor staging with anchor, depth, facing, scale and pose.
4. Prop staging with identity, anchor, depth and motion state.
5. An explicit action timeline.

Conceptual timeline:

narrative: carriage is heard outside
action: Elizabeth turns toward window
action: Elizabeth stands
action: Elizabeth walks to window
action: Elizabeth reaches window
action: Elizabeth looks outside
action: carriage moves through outside-window layer

Do not use one giant natural-language actionHint as the permanent choreography contract.

## 12. AI IMAGE AND LOCAL ACTOR ALIGNMENT

Three practical no-money-compatible directions are available:

A. Generate a background designed for the local stage, with deliberate staging regions and known anchors.

B. Generate or derive character assets that visually belong to the generated scene and animate those assets locally.

C. Use FLUX.2 Klein selectively to produce a small number of motion/keyframe assets, then cache and play them locally.

Full T2V using Alibaba is currently not acceptable because of the billing boundary.

## 13. NO-MONEY RUNTIME

Preferred architecture:

AI scene planning -> AI still generation -> cache -> local semantic scene graph -> local continuous animation.

Optional motion path:

AI still -> FLUX.2 Klein motion frames -> cache -> local playback.

The reader must remain functional if AI is unavailable, image generation fails, motion generation fails, or the network disappears after a scene is cached.

The fallback may use a generated still, but it must not falsely present the still as character animation.

## 14. TOKEN DISCIPLINE

Current ScenePlan limits are intentionally compact: 2 characters, 3 props, 3 actions.

Do not increase model output budgets merely to hide an inadequate schema. Prefer compact AI understanding followed by deterministic local expansion.

Example: AI can state that Elizabeth walks to the window. The local runtime can expand this into turn, weight shift, walk cycle, stop and face target without another AI call.

## 15. ACTION SEMANTICS

Current local animation derives actions from natural-language keywords. This is fragile.

Known example: 'reaches the window and looks outside' can be classified incorrectly because the current action matching order can hit look before reach.

Future action resolution should be explicit: action=reach target=window, followed by action=look target=outside_window.

## 16. ENVIRONMENT SEMANTICS

Existing resolver work supports semantic environment families including house, room, garden, park, road, street, cafeteria, airplane, forest, beach, mountain, farm, school, office, library, train, ship, castle, church, market, city, snow, desert and dungeon.

Important: environment classification alone does not solve spatial staging. The runtime still needs environment kind -> layout -> anchors -> actor staging -> prop staging -> camera.

## 17. CACHE

Scene cache identity is based on bookId + chapterId + source passage hash.

The literary source is canonical. Do not make generated prompts the cache identity.

## 18. AI FAILURE HANDLING

Current reader behavior avoids exposing infrastructure failures as the primary reader experience. If generation fails, the local scene remains available and _useLocalAnimation becomes true.

This resilience principle is correct, but the local fallback still needs to become semantically driven rather than a generic procedural room/actor scene.

## 19. WORKER SMOKE TEST

Workflow: .github/workflows/superbook-worker-smoke.yml

It waits for Worker health, calls live scene generation, validates the ScenePlan contract, validates the generated image payload, calls puppet-sheet, and validates the puppet-sheet response.

This is an API contract gate, not a visual quality test. It cannot prove character identity, cinematic quality, correct spatial staging, action choreography or reader visual coherence.

## 20. WHAT NOT TO DO

Do not switch back to Alibaba T2V.
Do not ask for billing.
Do not add R2.
Do not make the reader wait for video.
Do not use a static image plus camera zoom and call it animation.
Do not overlay arbitrary vector people on arbitrary AI photos.
Do not make actor positions depend on array index.
Do not hard-code carriage coordinates as the final architecture.
Do not build a huge general-purpose game engine.
Do not create AI calls per frame.
Do not build another isolated animation lab without integrating its useful abstractions into the reader.
Do not replace the AI ScenePlan with a hard-coded Pride and Prejudice demo.
Do not claim visual success because CI is green.

## 21. TARGET SCENE MODEL

Recommended compact layering:

AiScenePlan
  -> ResolvedStoryScene
      -> EnvironmentSpec: kind, anchors, depth planes
      -> ActorSpec[]: identity, description, anchor, facing, depth
      -> PropSpec[]: identity, anchor, depth
      -> TimelineBeat[]: narrative or actor/action/target/duration

This is deliberately small. Do not build a general game engine.

## 22. CANARY SCENE

Use the already-authored dining-room/carriage moment:

READ -> HEAR -> TURN -> STAND -> WALK -> REACH/LOOK -> CARRIAGE -> READ.

The actual reader should demonstrate:

- the actor who hears the carriage is the actor who turns;
- the same actor stands;
- the same actor walks;
- the same actor reaches the window;
- the actor looks through the window;
- the carriage appears outside, not inside the room;
- environment and depth remain coherent;
- camera framing supports the action;
- no duplicate generic vector people appear over unrelated AI people.

## 23. CURRENT STATUS

AI Scene Director: implemented.
Structured ScenePlan: implemented.
AI generated still: implemented.
Reader-facing scene summary: implemented.
Local continuous animation: implemented as a procedural renderer, but not yet semantically coherent enough for production.
AI image + local actor alignment: not solved.
Explicit AI action timeline in reader: not solved.
Named character staging: not solved robustly.
Semantic spatial anchors in production reader: not solved.
Free automatic T2V through the selected Alibaba model: unavailable under current constraints.
FLUX.2 Klein optional motion capability: Worker capability exists; production reader integration is not the current verified visual path.

## 24. NEXT AGENT INSTRUCTIONS

Read docs/SUPERBOOK-AI-SCENE-HANDOFF.md completely before changing anything.

Then inspect:
lib/features/scenes/scene_player_screen.dart
lib/features/scenes/superbook_local_animation_stage.dart
cloudflare/superbook-ai-worker/src/index.js
web/animation_lab/index.html

Do not start by rewriting the AI prompt. The biggest remaining problem is the missing shared spatial scene model between AI visual interpretation and local animation.

Build the smallest semantic scene graph and prove it on the dining-room/carriage canary in the actual reader. Only after the reader is coherent should the solution be generalized.

No paid services. No main branch. No fake animation. No blind deployment claims.
# SuperBook AI Scene Generation

SuperBook cinematic Experience is built around the story itself:

1. **Scene Director:** a text model reads a real book passage and produces a constrained `AiScenePlan`, including the reader-facing story summary, characters, setting, actions, camera, lighting, motion, and visual prompt.
2. **Visual Generator:** an image model creates an immediate visual interpretation of the moment.
3. **Local Story Stage:** Flutter turns the generated keyframe and scene plan into a continuously playable 2.5D cinematic moment using local camera motion, atmosphere, depth movement, and timing. No second AI inference is required to play the scene.
4. **Optional AI motion:** the Worker still exposes motion-frame generation for future explicit opt-in experiments. It is not called automatically when a scene opens.

The Flutter app never receives a provider secret. It calls a small Cloudflare Worker gateway.

## Prototype provider

The reference gateway uses Cloudflare Workers AI:

- Text planning: `@cf/meta/llama-3.3-70b-instruct-fp8-fast` (Workers AI JSON Mode compatible)
- Image generation: `@cf/black-forest-labs/flux-1-schnell`
- Optional story animation: `alibaba/hh1.1-t2v` (disabled by default)

The animation prompt is derived from the generated `sceneSummary` plus the scene's concrete characters, environment, actions, camera, lighting, and motion. The video model therefore receives the story context rather than merely being told to move an image.

## Deploying the gateway

From `cloudflare/superbook-ai-worker`:

    npx wrangler login
    npx wrangler deploy

The deployed Worker URL becomes the SuperBook AI scene endpoint.

Do not put a Cloudflare API token in Flutter, GitHub Pages, or source control.

## Billing boundary: important correction

The text planner and image generator currently use Workers AI models under the `@cf/` namespace and can use the Workers AI free allocation. The text planner requests structured JSON directly from the model, with a deliberately bounded 448-token completion budget. The app caches generated scenes by book/chapter/passage identity, and the local stage does not consume additional model tokens during playback. The current story-animation model is different: `alibaba/hh1.1-t2v` is classified by Cloudflare as a **third-party** model. It therefore does **not** belong to the no-cost Workers AI allocation. Cloudflare routes third-party models through AI Gateway / Unified Billing, and the account must have AI Gateway credits or another supported billing arrangement before this model can generate video.

The live test account returned this exact error on the SuperBook `/video` request:

    2021: Insufficient AI Gateway credits

Therefore SuperBook's current T2V animation path is intentionally **blocked by the user's no-money constraint**. Do not tell the user that `alibaba/hh1.1-t2v` is free. Do not ask the user to add AI Gateway credits, enable Unified Billing, add a Workers Paid plan, or subscribe to R2 unless the user explicitly changes the billing requirement.

Workers AI's separate free allocation remains 10,000 Neurons/day, but that statement does not make the Alibaba HappyHorse T2V model free. The distinction is critical.

Generated scenes should be cached and repeated generation should be avoided. The cache identity is:

    bookId + chapterId + source passage hash

## Product rule

A missing AI provider must never fall back to the old stick-figure scene as if it were the real Experience.

The generated still image is useful as an immediate visual response while the story animation is being prepared. If animation generation fails, the generated image remains available and the UI explicitly reports that animation is unavailable.

## Narrative animation rule

The book passage is canonical.

The generated `sceneSummary` is the bridge between the book and the animation. It must preserve the immediate context and significance of the passage, while the animation prompt may add only concrete visual/cinematic direction needed to depict that same moment.

The video model must not invent a new plot event, introduce unrelated characters, or turn the Experience into a generic motion effect.

## Performance and token strategy

Scene creation is deliberately staged:

    passage
      -> AI scene plan + image
      -> show scene
      -> local SuperBook cinematic stage

The expensive part happens once per scene identity. Playback itself is local Flutter animation, so replaying or watching a scene does not spend another AI inference. Cloud motion/T2V remains explicit future work rather than an automatic runtime dependency.

## Future rendering

## Local rendering architecture

The current Experience foundation is intentionally a small purpose-built stage rather than a general-purpose game engine. The AI owns **what the scene means**: characters, environment, actions, camera intent, lighting, and visual style. Flutter owns **how it plays**: camera drift, gentle scale/parallax, atmospheric particles, lighting bloom, timing, and lifecycle.

This keeps the runtime deterministic, fast, and free of per-frame inference. It also leaves room for future reusable character rigs, props, layered backgrounds, narration synchronization, and explicit AI-assisted acting without throwing away the current scene-plan contract.
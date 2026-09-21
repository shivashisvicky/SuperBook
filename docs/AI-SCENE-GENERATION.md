# SuperBook AI Scene Generation

SuperBook cinematic Experience is built around the story itself:

1. **Scene Director:** a text model reads a real book passage and produces a constrained `AiScenePlan`, including the reader-facing story summary, characters, setting, actions, camera, lighting, motion, and visual prompt.
2. **Visual Generator:** an image model creates an immediate visual interpretation of the moment.
3. **Story Animator:** a text-to-video model turns the same narrative plan and summary into a short cinematic sequence. The animation is not generated from a generic motion loop and does not require an R2 image handoff.

The Flutter app never receives a provider secret. It calls a small Cloudflare Worker gateway.

## Prototype provider

The reference gateway uses Cloudflare Workers AI:

- Text planning: `@cf/meta/llama-3.3-70b-instruct-fp8-fast`
- Image generation: `@cf/black-forest-labs/flux-1-schnell`
- Story animation: `alibaba/hh1.1-t2v`

The animation prompt is derived from the generated `sceneSummary` plus the scene's concrete characters, environment, actions, camera, lighting, and motion. The video model therefore receives the story context rather than merely being told to move an image.

## Deploying the gateway

From `cloudflare/superbook-ai-worker`:

    npx wrangler login
    npx wrangler deploy

The deployed Worker URL becomes the SuperBook AI scene endpoint.

Do not put a Cloudflare API token in Flutter, GitHub Pages, or source control.

## Billing boundary: important correction

The text planner and image generator currently use Workers AI models under the `@cf/` namespace and can use the Workers AI free allocation. The current story-animation model is different: `alibaba/hh1.1-t2v` is classified by Cloudflare as a **third-party** model. It therefore does **not** belong to the no-cost Workers AI allocation. Cloudflare routes third-party models through AI Gateway / Unified Billing, and the account must have AI Gateway credits or another supported billing arrangement before this model can generate video.

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

## Performance strategy

Scene creation and animation are deliberately staged:

    passage
      -> AI scene plan + image
      -> show scene
      -> independently generate story animation
      -> attach video when ready

This lets the reader see the generated scene without waiting for the full video generation request to complete.

## Future rendering

The generated video is the first cinematic animation layer. Later work can add multi-shot sequences, narration synchronization, ambient audio, chapter-level scene continuity, and offline caching while continuing to use the same narrative plan and source passage as the canonical story context.
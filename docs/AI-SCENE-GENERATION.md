# SuperBook AI Scene Generation

SuperBook cinematic Experience is split into two layers:

1. Scene Director: a text model reads a real book passage and produces a constrained AiScenePlan.
2. Visual Generator: an image model turns the validated visual prompt into the scene image.

The Flutter app never receives a provider secret. It calls a small Cloudflare Worker gateway.

## Prototype provider

The reference gateway uses Cloudflare Workers AI:

- Text planning: @cf/meta/llama-3.3-70b-instruct-fp8-fast
- Image generation: @cf/black-forest-labs/flux-1-schnell

Workers AI exposes an AI binding to a Worker, so the provider credential stays server-side.

## Deploying the gateway

From cloudflare/superbook-ai-worker:

    npx wrangler login
    npx wrangler deploy

The deployed Worker URL becomes the SuperBook AI scene endpoint.

Do not put a Cloudflare API token in Flutter, GitHub Pages, or source control.

## Free-tier development

Workers AI is available on Free and Paid plans. The free allocation is quota-based, so generated scenes must be cached and repeated generation should be avoided.

The first milestone should generate one scene on demand, cache it by:

    bookId + chapterId + source passage hash

and regenerate only when the source passage changes.

## Product rule

A missing AI provider must never fall back to the old stick-figure scene as if it were the real Experience.

The deterministic renderer can remain a development fixture for tests. Real-book Experience should either use a generated asset or explicitly report that Experience is not configured yet.

## Planned rendering

The generated image is the first visual asset, not the final animation.

Later layers can add depth/parallax, camera push/pan, controlled character/object motion, ambient effects, narration synchronization, and multi-shot sequences. Those layers consume the same AiScenePlan and generated asset rather than inventing a new interpretation of the book.

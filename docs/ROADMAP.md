# SuperBook Build Roadmap

## Milestone 1: Narrative-first foundation

- Domain contracts for book, chapter, passage, scene, entities, events and beats.
- ReaderState with spoiler boundary.
- ScenePlan and presentation intensity.
- Provider-neutral narrative service interfaces.
- Deterministic fixture book and story graph.
- Serialization/domain tests.

Acceptance: a fixture book opens offline; its current passage resolves to a scene; the scene resolves narrative entities; a ScenePlan can be produced without a generative provider.

## Milestone 2: Real books

EPUB first, PDF later.

source -> parser -> normalized passages -> chapter index -> local store -> reader.

No cinematic generation yet.

## Milestone 3: Narrative analysis

Add one provider implementation behind the interfaces. Process incrementally and cache results.

## Milestone 4: Living page

Add narration, ambience, subtle visual effects and illustrated beats using ScenePlan.

## Milestone 5: Cinematic engine

Turn ScenePlan into a render timeline. Reuse assets and procedural motion before expensive video generation.

## Milestone 6: Explore

Context-aware Q&A, character/location/object views, maps, recaps and Enter Scene.

## Development rule

Every milestone must leave the app usable. Prefer additive, testable changes over large rewrites. Keep deterministic fixtures so regressions do not depend on an AI service.

# SuperBook Architecture

SuperBook is a narrative-first reading platform. The book remains the source of truth; AI-generated visuals, audio, animation, and interactive exploration are projections of the narrative model rather than replacements for the text.

## Product principle

**Read the story. See what the book sees.**

Three experiences share the same story state:

- **Read**: online/offline book reading with optional narration and restrained living-page effects.
- **Experience**: cinematic scene playback only where narrative importance justifies it.
- **Explore**: context-aware questions, characters, locations, objects, relationships, maps, recaps, and scene entry without losing reader position.

## Core architecture

Book sources -> Book Ingestion -> Narrative Engine -> Story Graph -> Reader / Audio Director / Scene Planner -> Visual & Animation Renderer.

Cross-cutting services: offline cache, asset store, reader progress, AI provider abstraction, deterministic fallbacks, diagnostics.

## Canonical model

- Book
- Chapter
- Passage
- Scene
- Character
- Location
- Object
- Event
- Relationship
- Emotion
- NarrativeBeat
- ScenePlan
- ExperienceAsset
- ReaderState

The narrative graph is authoritative. Generated media is disposable and regenerable.

## Cinematic intensity

Do not animate every sentence.

- 0: text only
- 1: subtle living-page effect
- 2: illustrated moment
- 3: animated scene
- 4: cinematic sequence

Start with deterministic rules. AI may later propose intensity, but the result must be validated.

## Scene planning

Never send raw book text directly to a video generator.

1. Extract source passages.
2. Identify entities and events.
3. Resolve them against the story graph.
4. Detect narrative beats.
5. Select cinematic intensity.
6. Produce a provider-neutral ScenePlan.
7. Validate it against story state.
8. Reuse cached assets.
9. Generate only missing assets.
10. Render and cache.

A ScenePlan describes shots, entities, camera intent, duration, narration/dialogue, ambience, transitions and source passage IDs.

## Offline-first

Downloaded books should retain source text, normalized book data, narrative graph, reader progress and cached experience assets. Online services can enrich the experience but must never be required to open the book.

## AI boundaries

Keep providers behind interfaces:

- NarrativeAnalyzer
- EntityResolver
- ScenePlanner
- NarrationGenerator
- VisualAssetGenerator
- AnimationRenderer
- QuestionAnswerer

AI results should retain source passage IDs, provider/model identity, generation timestamp, confidence where applicable, and cache identity.

## Reader continuity

Every AI interaction carries:

- book ID
- chapter ID
- scene ID
- passage ID/range
- narrative timeline position
- spoiler boundary

Exploration defaults to information already encountered by the reader. Future-book knowledge requires explicit user action.

## Flutter target structure

```text
lib/
  app/
  core/        audio, camera, storage, networking, permissions
  domain/      book, narrative, reader, experience
  data/        books, narrative, assets, cache
  services/    ingestion, narrative, audio, visual, animation, ai
  features/    library, reader, experience, explore, scene, settings
```

The existing camera/page-recognition code remains useful as an input adapter. It should not remain the center of the product.

## Delivery phases

1. Foundation: domain contracts, stable reader shell, storage boundaries, deterministic fixture.
2. Real books: EPUB ingestion, persistence, pagination/progress, chapter navigation, bookmarks, offline switching.
3. Narrative graph: passages, entities, events, scenes, character/location resolution and provenance.
4. Living pages: narration, ambience, subtle animation and illustrated beats.
5. Cinematic experience: ScenePlan, shot timeline, asset cache and renderer abstraction.
6. Explore: context-aware Q&A, character/location/object views, maps, recaps and Enter Scene.
7. Offline intelligence: downloadable narrative packs and local retrieval/model options.

## Non-goals for the first build

- Full AI video generation
- Unrestricted generative characters
- Cloud-only architecture
- Automatic animation on every page
- Provider-specific domain models
- Replacing book text with generated prose

## Architectural rule

**The book is canonical. The narrative graph is the understanding layer. Scene plans are presentation intent. Generated media is a cache.**

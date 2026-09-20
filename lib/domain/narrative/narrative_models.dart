/// Provider-neutral narrative domain contracts.
///
/// These models deliberately contain no Flutter, AI-provider, or renderer
/// dependencies. They are the stable language between the reader and all
/// future narrative/experience implementations.

enum PresentationIntensity {
  textOnly,
  livingPage,
  illustrated,
  animated,
  cinematic,
}

class BookRef {
  final String id;
  final String title;
  final String? author;

  const BookRef({required this.id, required this.title, this.author});
}

class Chapter {
  final String id;
  final String bookId;
  final int index;
  final String title;

  const Chapter({
    required this.id,
    required this.bookId,
    required this.index,
    required this.title,
  });
}

class Passage {
  final String id;
  final String chapterId;
  final int order;
  final String text;

  const Passage({
    required this.id,
    required this.chapterId,
    required this.order,
    required this.text,
  });
}

class StoryEntity {
  final String id;
  final String name;
  final List<String> aliases;

  const StoryEntity({
    required this.id,
    required this.name,
    this.aliases = const [],
  });
}

class StoryEvent {
  final String id;
  final String sceneId;
  final String description;
  final List<String> participantIds;
  final String? locationId;
  final List<String> sourcePassageIds;

  const StoryEvent({
    required this.id,
    required this.sceneId,
    required this.description,
    this.participantIds = const [],
    this.locationId,
    this.sourcePassageIds = const [],
  });
}

class NarrativeBeat {
  final String id;
  final String sceneId;
  final String type;
  final List<String> sourcePassageIds;
  final PresentationIntensity intensity;

  const NarrativeBeat({
    required this.id,
    required this.sceneId,
    required this.type,
    this.sourcePassageIds = const [],
    this.intensity = PresentationIntensity.textOnly,
  });
}

class Scene {
  final String id;
  final String chapterId;
  final List<String> passageIds;
  final List<String> eventIds;
  final List<String> beatIds;

  const Scene({
    required this.id,
    required this.chapterId,
    this.passageIds = const [],
    this.eventIds = const [],
    this.beatIds = const [],
  });
}

class ReaderState {
  final String bookId;
  final String? chapterId;
  final String? passageId;
  final double progress;
  final int spoilerBoundary;

  const ReaderState({
    required this.bookId,
    this.chapterId,
    this.passageId,
    this.progress = 0,
    this.spoilerBoundary = 0,
  });
}

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.chapters,
    required this.characters,
    required this.locations,
    required this.objects,
    required this.beats,
  });

  final String id;
  final String title;
  final String author;
  final String description;
  final List<Chapter> chapters;
  final List<BookCharacter> characters;
  final List<BookLocation> locations;
  final List<BookObject> objects;
  final List<NarrativeBeat> beats;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.passage,
    required this.scene,
  });

  final String id;
  final String title;
  final List<String> passage;
  final Scene scene;
}

class BookCharacter {
  const BookCharacter({
    required this.name,
    required this.role,
    required this.description,
  });

  final String name;
  final String role;
  final String description;
}

class BookLocation {
  const BookLocation({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}

class BookObject {
  const BookObject({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}

class NarrativeBeat {
  const NarrativeBeat({
    required this.title,
    required this.summary,
    required this.chapterId,
    required this.intensity,
  });

  final String title;
  final String summary;
  final String chapterId;
  final int intensity;
}

class Scene {
  const Scene({
    required this.title,
    required this.moment,
    required this.atmosphere,
    required this.caption,
  });

  final String title;
  final String moment;
  final String atmosphere;
  final String caption;
}

const demoBook = Book(
  id: 'the-little-house',
  title: 'The Little House',
  author: 'SuperBook Demo',
  description:
      'A deterministic story fixture used to exercise SuperBook’s reading, narrative, scene, and exploration surfaces.',
  chapters: [
    Chapter(
      id: 'chapter-1',
      title: 'The Old House',
      passage: [
        'The wind moved through the trees as the traveler approached the old house.',
        'A single lamp burned behind the window. The path was quiet, but the door stood open.',
        'He paused at the gate, listening to the leaves and the distant sound of rain.',
      ],
      scene: Scene(
        title: 'The Old House',
        moment: 'The traveler reaches the open gate.',
        atmosphere: 'Rain, wind, wet leaves, one warm lamp.',
        caption: 'A quiet house waits at the edge of the storm.',
      ),
    ),
    Chapter(
      id: 'chapter-2',
      title: 'The Open Door',
      passage: [
        'He crossed the garden and stepped beneath the porch.',
        'The lamp threw a narrow path of gold across the floorboards.',
        'Inside, an old map rested on a wooden table beside a brass key.',
      ],
      scene: Scene(
        title: 'The Open Door',
        moment: 'The traveler crosses the threshold.',
        atmosphere: 'Warm lamplight against a dark, rain-soaked porch.',
        caption: 'The story moves from the storm into the unknown.',
      ),
    ),
    Chapter(
      id: 'chapter-3',
      title: 'The Map',
      passage: [
        'The map showed a road winding north toward a place marked only by a small black star.',
        'The traveler lifted the brass key and found the same star engraved into its bow.',
        'For the first time that night, he smiled.',
      ],
      scene: Scene(
        title: 'The Map',
        moment: 'The key and the map reveal the same mark.',
        atmosphere: 'Quiet room, brass glint, rain fading outside.',
        caption: 'A small mark turns a strange house into a direction.',
      ),
    ),
  ],
  characters: [
    BookCharacter(
      name: 'The Traveler',
      role: 'Protagonist',
      description: 'A solitary traveler following an unexplained road.',
    ),
  ],
  locations: [
    BookLocation(
      name: 'The Old House',
      description: 'A quiet house at the end of a rain-darkened garden.',
    ),
    BookLocation(
      name: 'The Garden Gate',
      description: 'The point where the traveler first stops to listen.',
    ),
  ],
  objects: [
    BookObject(
      name: 'The Brass Key',
      description: 'A small brass key carrying the same star mark as the map.',
    ),
    BookObject(
      name: 'The Old Map',
      description: 'A map showing a northern road and an unexplained black star.',
    ),
  ],
  beats: [
    NarrativeBeat(
      title: 'Arrival',
      summary: 'The traveler discovers the old house and its open door.',
      chapterId: 'chapter-1',
      intensity: 2,
    ),
    NarrativeBeat(
      title: 'Threshold',
      summary: 'The traveler enters and discovers the map and brass key.',
      chapterId: 'chapter-2',
      intensity: 3,
    ),
    NarrativeBeat(
      title: 'Recognition',
      summary: 'The key and map reveal a shared symbol.',
      chapterId: 'chapter-3',
      intensity: 3,
    ),
  ],
);

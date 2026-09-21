import 'package:flutter/material.dart';
import '../../domain/book.dart';
import '../explore/explore_screen.dart';
import '../scenes/scene_player_screen.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final Book book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int chapterIndex = 0;
  bool experienceVisible = false;
  bool bookmarked = false;
  bool narrationVisible = false;
  double fontSize = 20;

  Chapter get chapter => widget.book.chapters[chapterIndex];

  void _showContents() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          children: [
            const ListTile(
              title: Text('Contents'),
              subtitle: Text('Choose a section'),
            ),
            for (var i = 0; i < widget.book.chapters.length; i++)
              ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(widget.book.chapters[i].title),
                trailing: i == chapterIndex ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => chapterIndex = i);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showReaderOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reader settings', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Text('Text size', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                min: 16,
                max: 28,
                divisions: 6,
                value: fontSize,
                label: fontSize.round().toString(),
                onChanged: (value) {
                  setState(() => fontSize = value);
                  setSheetState(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: narrationVisible,
                onChanged: (value) {
                  setState(() => narrationVisible = value);
                  setSheetState(() {});
                },
                title: const Text('Narration controls'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (chapterIndex + 1) / widget.book.chapters.length;
    final beat = widget.book.beats.firstWhere(
      (item) => item.chapterId == chapter.id,
      orElse: () => NarrativeBeat(
        title: chapter.title,
        summary: chapter.passage.first,
        chapterId: chapter.id,
        intensity: 1,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(chapter.title),
        actions: [
          IconButton(
            tooltip: 'Contents',
            onPressed: _showContents,
            icon: const Icon(Icons.list),
          ),
          IconButton(
            tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
            onPressed: () => setState(() => bookmarked = !bookmarked),
            icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
          ),
          IconButton(
            tooltip: 'Reader settings',
            onPressed: _showReaderOptions,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Explore',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExploreScreen(book: widget.book)),
            ),
            icon: const Icon(Icons.travel_explore),
          ),
          IconButton(
            tooltip: 'Experience',
            onPressed: () => setState(() => experienceVisible = !experienceVisible),
            icon: Icon(
              experienceVisible ? Icons.auto_awesome : Icons.auto_awesome_outlined,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress, minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              children: [
                Text(widget.book.title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(chapter.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 28),
                for (final paragraph in chapter.passage) ...[
                  Text(
                    paragraph,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: fontSize,
                          height: 1.65,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (narrationVisible) const _NarrationBar(),
                if (experienceVisible) ...[
                  const SizedBox(height: 8),
                  _ExperienceCard(
                    book: widget.book,
                    scene: chapter.scene,
                    beat: beat,
                  ),
                ],
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: chapterIndex == 0
                          ? null
                          : () => setState(() => chapterIndex--),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),
                    Text(
                      '${_sectionLabel(chapter)} ${chapterIndex + 1} of ${widget.book.chapters.length}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    OutlinedButton.icon(
                      onPressed: chapterIndex + 1 >= widget.book.chapters.length
                          ? null
                          : () => setState(() => chapterIndex++),
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrationBar extends StatelessWidget {
  const _NarrationBar();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.volume_up_outlined),
        title: const Text('Narration'),
        subtitle: const Text('Ready for the current passage'),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.play_arrow_rounded),
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.book,
    required this.scene,
    required this.beat,
  });

  final Book book;
  final Scene scene;
  final NarrativeBeat beat;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('experience-scene-entry'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScenePlayerScreen(
              book: book,
              scene: scene,
              beat: beat,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: const Icon(Icons.auto_awesome, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EXPERIENCE', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 5),
                    Text(scene.caption),
                    const SizedBox(height: 8),
                    const Text('Tap to enter the scene'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


String _sectionLabel(Chapter chapter) {
  return chapter.title.trim().toLowerCase().startsWith('chapter')
      ? 'Chapter'
      : 'Section';
}

import 'package:flutter/material.dart';
import '../../domain/book.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});
  final Book book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int chapterIndex = 0;
  bool experienceVisible = false;

  Chapter get chapter => widget.book.chapters[chapterIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chapter.title),
        actions: [
          IconButton(
            tooltip: 'Experience',
            onPressed: () => setState(() => experienceVisible = !experienceVisible),
            icon: Icon(experienceVisible ? Icons.auto_awesome : Icons.auto_awesome_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(widget.book.title),
          const SizedBox(height: 12),
          Text(chapter.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 28),
          for (final paragraph in chapter.passage) ...[
            Text(paragraph, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 22),
          ],
          if (experienceVisible) const _ExperienceCard(),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: chapterIndex == 0 ? null : () => setState(() => chapterIndex--),
                child: const Text('Previous'),
              ),
              Text('Chapter ${chapterIndex + 1} of ${widget.book.chapters.length}'),
              OutlinedButton(
                onPressed: chapterIndex + 1 >= widget.book.chapters.length
                    ? null
                    : () => setState(() => chapterIndex++),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EXPERIENCE'),
            SizedBox(height: 12),
            Text('The old house waits in the rain.'),
            SizedBox(height: 10),
            Text('This deterministic scene is the first presentation layer.'),
          ],
        ),
      ),
    );
  }
}

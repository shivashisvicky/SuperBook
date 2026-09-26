import 'package:flutter/material.dart';
import '../../domain/book.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.book});

  final Book book;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String? selectedQuery;

  String get answer {
    switch (selectedQuery) {
      case 'Who is the traveler?':
        return widget.book.characters.first.description;
      case 'Where is the story?':
        return widget.book.locations.first.description;
      case 'What matters here?':
        final objectNames = widget.book.objects.map((e) => e.name).join(' and ');
        return '$objectNames connect the house to the road ahead.';
      default:
        return 'Choose a question to explore the story without leaving the book.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('EXPLORE', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(widget.book.title, style: theme.textTheme.headlineMedium),
        Text(widget.book.author, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        Text('Ask the book', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Who is the traveler?',
            'Where is the story?',
            'What matters here?',
          ].map((query) {
            return ChoiceChip(
              label: Text(query),
              selected: selectedQuery == query,
              onSelected: (_) => setState(() => selectedQuery = query),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(answer, style: theme.textTheme.bodyLarge),
          ),
        ),
        const SizedBox(height: 28),
        _Section(
          title: 'Characters',
          children: widget.book.characters
              .map((character) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(character.name),
                    subtitle: Text('${character.role} · ${character.description}'),
                  ))
              .toList(),
        ),
        _Section(
          title: 'Places',
          children: widget.book.locations
              .map((location) => ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(location.name),
                    subtitle: Text(location.description),
                  ))
              .toList(),
        ),
        _Section(
          title: 'Objects',
          children: widget.book.objects
              .map((object) => ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(object.name),
                    subtitle: Text(object.description),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(child: Column(children: children)),
        const SizedBox(height: 20),
      ],
    );
  }
}

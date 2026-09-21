import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool livingPage = true;
  bool narration = false;
  bool spoilerSafe = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('SETTINGS', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text('Reading experience', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: livingPage,
                onChanged: (value) => setState(() => livingPage = value),
                title: const Text('Living page'),
                subtitle: const Text('Allow restrained page-level atmosphere effects.'),
              ),
              SwitchListTile(
                value: narration,
                onChanged: (value) => setState(() => narration = value),
                title: const Text('Narration'),
                subtitle: const Text('Keep narration controls available in the reader.'),
              ),
              SwitchListTile(
                value: spoilerSafe,
                onChanged: (value) => setState(() => spoilerSafe = value),
                title: const Text('Spoiler-safe explore'),
                subtitle: const Text('Keep exploration anchored to the current reading boundary.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.offline_bolt_outlined),
            title: const Text('Offline-first'),
            subtitle: const Text('Book content and narrative data are designed to remain usable without network access.'),
            trailing: const Icon(Icons.check_circle_outline),
          ),
        ),
        const SizedBox(height: 20),
        const AboutListTile(
          applicationName: 'SuperBook',
          applicationVersion: 'v2 foundation',
          applicationLegalese: 'Read the story. See what the book sees.',
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUPERBOOK',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 4,
                          color: Colors.white54,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Read the story.\nSee what the book sees.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Narrative-first foundation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('READ',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 14),
                          Text(
                            'The wind moved through the trees as the traveler approached the old house.',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(height: 1.35),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Web reader foundation. Native camera and vision code is intentionally excluded from the web build.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white60,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          title: 'EXPERIENCE',
                          detail: 'Scene pipeline ready for cinematic moments',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ModeCard(
                          title: 'EXPLORE',
                          detail: 'Narrative graph and contextual Q&A foundation',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

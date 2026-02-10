/// Subject list for filters
const List<String> subjects = [
  'Medicine',
  'Surgery',
  'OBG',
  'Pediatrics',
  'Anesthesia',
  'Pharmacology',
  'Psychiatry',
  'ENT',
  'Anatomy',
  'Physiology',
];

/// Timer modes for tests
enum TimerMode {
  blaze(30, 'Blaze', '30s per question'),
  rapid(60, 'Rapid', '1 min per question'),
  calm(120, 'Calm', '2 min per question');

  final int seconds;
  final String label;
  final String description;

  const TimerMode(this.seconds, this.label, this.description);
}

/// Question count options
const List<int> questionCounts = [10, 20, 30, 50];

/// MCQ card modes
enum MCQCardMode { learn, test, review }

enum Direction {
  up,
  down,
  left,
  right;

  Direction get opposite => switch (this) {
        Direction.up => Direction.down,
        Direction.down => Direction.up,
        Direction.left => Direction.right,
        Direction.right => Direction.left,
      };

  (int dr, int dc) get delta => switch (this) {
        Direction.up => (-1, 0),
        Direction.down => (1, 0),
        Direction.left => (0, -1),
        Direction.right => (0, 1),
      };

  double get rotation => switch (this) {
        Direction.up => -1.5708,
        Direction.down => 1.5708,
        Direction.left => 3.14159,
        Direction.right => 0,
      };

  String get label => switch (this) {
        Direction.up => '↑',
        Direction.down => '↓',
        Direction.left => '←',
        Direction.right => '→',
      };
}

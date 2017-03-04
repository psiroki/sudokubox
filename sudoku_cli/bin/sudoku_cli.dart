import "package:sudoku_core/sudoku_core.dart";
import "package:args/args.dart";
import "console_environment.dart";
import "dart:io";

class GenerationResult {
  GenerationResult(this.board, this.generationTime);

  String toString() => board.toString();

  final SudokuBoard board;
  final Duration generationTime;
}

Duration percentileDuration(Iterable<Duration> durations, double percentile) {
  double position = durations.length * percentile;
  double positionFraction = position % 1;
  if (positionFraction == 0) return durations.skip(position.floor()).first;
  Iterator<Duration> it = durations.skip(position.floor()).iterator;
  it.moveNext();
  Duration first = it.current;
  it.moveNext();
  Duration second = it.current;
  return new Duration(
      microseconds: (first.inMicroseconds * (1 - positionFraction) +
              second.inMicroseconds * positionFraction)
          .floor());
}

void generateProblems(int problemCount) {
  Duration overallDuration = new Duration();
  Duration max = null;
  Duration min = null;
  int count = 0;
  List<GenerationResult> boards = [];
  const int percentageStep = 10;
  int percentage = percentageStep;
  int nextStep = problemCount ~/ percentageStep;
  int next = nextStep;
  int nextFrac = 0;
  int nextFracStep = problemCount % percentageStep;
  for (int i = 0; i < problemCount; ++i) {
    if (i == next - 1) {
      stderr.write("..${percentage}%");
      percentage += percentageStep;
      next += nextStep;
      nextFrac += nextFracStep;
      if (nextFrac >= percentageStep) {
        nextFrac -= percentageStep;
        ++next;
      }
    }
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.start();
    SudokuBoard problem = generateProblem();
    stopwatch.stop();
    Duration time = stopwatch.elapsed;
    boards.add(new GenerationResult(problem, time));
    overallDuration += time;
    ++count;
    if (min == null || min > time) min = time;
    if (max == null || max < time) max = time;
  }
  stderr.writeln();

  boards.sort((a, b) => a.generationTime.compareTo(b.generationTime));

  stderr.writeln(
      "The boards in generation time order (the last one took the longest):");
  print(boards.join("\n"));

  Iterable<Duration> generationTimes = boards.map((e) => e.generationTime);
  Duration median = percentileDuration(generationTimes, 0.5);
  Duration percentile90 = percentileDuration(generationTimes, 0.9);
  Duration avg =
      new Duration(microseconds: overallDuration.inMicroseconds ~/ count);

  stderr.writeln("min: $min");
  stderr.writeln("max: $max");
  stderr.writeln("avg: ${avg}");
  stderr.writeln("med: ${median}");
  stderr.writeln("90%: ${percentile90}");
  stderr.writeln("Overall: ${overallDuration}");
  stderr.writeln("\nThe board that took the longest to generate:");
  writeBoard(boards.last.board, stderr);
}

typedef void CommandParser(ArgResults result);

final Map<String, CommandParser> commandParsers = new Map.unmodifiable({
  "generate": (ArgResults result) {
    int count = int.parse(result["count"]);
    generateProblems(count);
  },
  "solve": (ArgResults result) {
    bool showSteps = result["steps"];
    String problem = result.rest[0];
    if (problem == "-") problem = stdin.readLineSync();
    SudokuBoard problemBoard = new SudokuBoard.fromString(problem);

    SolveEnvironment env = null;
    if (showSteps) {
      env = new ConsoleEnvironment(stderr);
      env.dump(loupe: problemBoard.loupe);
    }

    searchSolution(problemBoard, env: env).forEach(print);
  },
});

void main(List<String> args) {
  ArgParser parser = new ArgParser();
  parser.addCommand("generate")
    ..addOption("count",
        abbr: "c",
        defaultsTo: "100",
        help: "Number of problems to generate (default is 100)");
  parser.addCommand("solve")
    ..addFlag("steps", abbr: "s", help: "Show solve steps");
  ArgResults result = parser.parse(args);
  if (result.command == null) {
    generateProblems(1);
  } else {
    CommandParser commandParser = commandParsers[result.command.name];
    commandParser(result.command);
  }
}

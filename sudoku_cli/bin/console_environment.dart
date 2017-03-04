import "package:sudoku_core/sudoku_core.dart";

void _nativePrint(obj) => print(obj);

void writeBoard(SudokuBoard board, StringSink sink) =>
    writeLoupe(board.loupe, sink);

void writeLoupe(SudokuLoupe loupe, StringSink sink) {
  int offset = 0;
  for (int row = 0; row < 9; ++row) {
    for (int col = 0; col < 9; ++col) {
      loupe.index = offset;
      int val = loupe.solvedValue;
      if (val == 0)
        sink.write(".");
      else
        sink.write(val.toString());
      if (col % 3 == 2) {
        if (col < 8) sink.write("|");
      } else {
        sink.write(" ");
      }
      ++offset;
    }
    sink.writeln();
    if (row % 3 == 2 && row < 8) {
      sink.write("-" * 5);
      sink.write("+");
      sink.write("-" * 5);
      sink.write("+");
      sink.writeln("-" * 5);
    }
  }
}

String loupeToAscii(SudokuLoupe loupe) {
  StringBuffer buffer = new StringBuffer();
  writeLoupe(loupe, buffer);
  return buffer.toString();
}

void printBoard(SudokuBoard board) => printBoardWithLoupe(board.loupe);

void printBoardWithLoupe(SudokuLoupe loupe) => print(loupeToAscii(loupe));

class ConsoleEnvironment implements SolveEnvironment {
  ConsoleEnvironment(this._sink);

  @override
  void dump({
    SudokuLoupe loupe,
    Iterable<int> highlights,
    String tableClass,
  }) {
    if (_sink != null)
      writeLoupe(loupe, _sink);
    else
      printBoardWithLoupe(loupe);
  }

  @override
  void print(dynamic obj) {
    if (_sink != null)
      _sink.writeln(obj);
    else
      _nativePrint(obj);
  }

  final StringSink _sink;
}

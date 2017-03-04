import "dart:typed_data";
import "dart:html";
import "dart:math";
import "dart:convert" show JSON;

import "package:sudoku_core/sudoku_core.dart";

void nativePrint(obj) => print(obj);

typedef void MouseEventHandler(MouseEvent event);

ButtonElement appendButton(
    HtmlElement parent, String caption, MouseEventHandler clickHandler) {
  ButtonElement button = new ButtonElement();
  button.type = "button";
  button.text = caption;
  button.onClick.listen((event) => clickHandler(event));
  parent.append(button);
  return button;
}

HtmlElement appendSpacer(HtmlElement parent) =>
    appendSpan(parent)..classes.add("spacer");

HtmlElement appendSpan(HtmlElement parent) {
  SpanElement span = new SpanElement();
  parent.append(span);
  return span;
}

HtmlElement createBoard(SudokuBoard board) {
  HtmlElement result = new DivElement();
  TableElement table = appendTable(result, board.loupe);
  table.classes.add("interactive");
  TableElement selection = new TableElement();
  selection.classes.add("selectionPanel");
  result.append(selection);
  HtmlElement tbody = document.createElement("tbody");
  selection.append(tbody);
  TableRowElement selectionRow = new TableRowElement();
  tbody.append(selectionRow);
  int selectedIndex = -1;
  List<TableCellElement> boardCells = new List();

  Function syncSelection = () {
    window.sessionStorage["sudokuBoard"] = JSON.encode(board.backing);
    for (int i = 0; i < 9; ++i) {
      CssClassSet classes = selectionRow.cells[i].classes;
      SudokuLoupeMixin loupe;
      if (selectedIndex >= 0)
        loupe = board.loupe[selectedIndex];
      else
        loupe = new SingleValueSudokuLoupe()..rawValue = 0;
      bool has;
      if (!loupe.isSet)
        has = loupe.hasCandidate(i + 1);
      else
        has = loupe.value == i + 1;
      classes.toggle("selected", has);
      classes.toggle("unselected", !has);

      Set<int> values;
      if (loupe.isSet)
        values = new Set.from([loupe.value]);
      else
        values = loupe.candidates.toSet();
      for (SudokuLoupe loupe in board.loupe.cells) {
        int index = loupe.index;
        bool highlight = false;
        if (loupe.isSet) {
          highlight = values.contains(loupe.value);
        } else {
          for (int value in loupe.candidates) {
            if (values.contains(value)) {
              highlight = true;
              break;
            }
          }
        }
        boardCells[index].classes.toggle("highlight", highlight);
        boardCells[index]
            .classes
            .toggle("selectedCell", index == selectedIndex);
      }
    }
  };

  for (int i = 0; i < 9; ++i) {
    int n = i + 1;
    HtmlElement cell = document.createElement("td");
    selectionRow.append(cell);
    cell.text = n.toString();
    int x = i % 3;
    cell.className = "cell0${x} cell1${x} cell2${x}";
    cell.onClick.listen((clickElement) {
      if (selectedIndex >= 0) {
        SudokuLoupe loupe = board.loupe;
        loupe.index = selectedIndex;
        if (!loupe.isSet) loupe.toggleCandidate(n);
        setupCell(boardCells[loupe.index], loupe);
        syncSelection();
      }
    });
  }

  for (SudokuLoupe loupe in board.loupe.cells) {
    int index = loupe.index;
    int row = index ~/ 9;
    int col = index % 9;
    TableCellElement cell = table.tBodies[0].rows[row].cells[col];
    boardCells.add(cell);
    cell.onClick.listen((clickEvent) {
      if (selectedIndex >= 0)
        boardCells[selectedIndex].classes.remove("selectedCell");
      selectedIndex = index;
      boardCells[selectedIndex].classes.add("selectedCell");
      syncSelection();
    });
  }

  appendButton(result, "Eliminate", (clickEvent) {
    while (board.eliminateResolved().isNotEmpty);
    for (SudokuLoupe loupe in board.loupe.cells)
      setupCell(boardCells[loupe.index], loupe);
    syncSelection();
  });

  appendSpacer(result);

  appendButton(result, "New puzzle", (clickEvent) {
    board = generateProblem();
    for (SudokuLoupe loupe in board.loupe.cells)
      setupCell(boardCells[loupe.index], loupe);
    syncSelection();
  });

  appendSpacer(result);

  List<SudokuBoard> stack = [];
  if (window.sessionStorage.containsKey("sudokuBoardStack")) {
    List encoded = JSON.decode(window.sessionStorage["sudokuBoardStack"]);
    stack.addAll(encoded
        .map((e) => new SudokuBoard.withBacking(new Uint32List.fromList(e))));
  }
  HtmlElement counter;
  Function syncStack = () {
    window.sessionStorage["sudokuBoardStack"] =
        JSON.encode(stack.map((e) => e.backing).toList());
    if (stack.isNotEmpty)
      counter.text = "Depth: ${stack.length}";
    else
      counter.text = "";
  };

  appendButton(result, "Push", (clickEvent) {
    stack.add(board.clone());
    syncStack();
  })..classes.add("left");

  appendButton(result, "Pop", (clickEvent) {
    board = stack.removeLast();
    syncStack();
    for (SudokuLoupe loupe in board.loupe.cells)
      setupCell(boardCells[loupe.index], loupe);
    syncSelection();
  })..classes.add("right");

  appendSpacer(result);
  counter = appendSpan(result)..classes.add("counter");

  syncStack();

  return result;
}

void setupCell(TableCellElement td, SudokuLoupe loupe, [Set<int> hl]) {
  final int row = loupe.index ~/ 9;
  final int col = loupe.index % 9;
  td.className = "";
  td.classes.toggle("highlight", hl != null && hl.contains(loupe.index));
  td.classes.add("cell${row%3}${col%3}");
  if (loupe.isSet) {
    td.text = loupe.value.toString();
    td.classes.add("set");
  } else {
    td.text = "";
    List<int> candidates = new List.from(loupe.candidates, growable: false);
    int cl = candidates.length;
    for (int i = 0; i < cl; i += 3) {
      int end = min(i + 3, cl);
      String s = candidates.sublist(i, end).join("\u00a0");
      td.appendText(s);
      if (end < cl) td.append(document.createElement("br"));
    }
    if (candidates.length > 1)
      td.classes.add("multipleCandidate");
    else
      td.classes.add("singleCandidate");
  }
}

TableElement appendTable(
  HtmlElement parent,
  SudokuLoupe loupe, {
  Iterable<int> highlights,
  String tableClass,
}) {
  TableElement table = document.createElement("table");
  if (tableClass != null) table.className = tableClass;
  HtmlElement tbody = document.createElement("tbody");
  table.append(tbody);
  Set<int> hl = highlights != null ? highlights.toSet() : new Set();
  for (int row = 0; row < 9; ++row) {
    HtmlElement tr = document.createElement("tr");
    tbody.append(tr);
    for (int col = 0; col < 9; ++col) {
      loupe.index = row * 9 + col;
      HtmlElement td = document.createElement("td");
      setupCell(td, loupe, hl);
      tr.append(td);
    }
  }
  parent.append(table);
  return table;
}

class StandardEnvironment extends SolveEnvironment {
  factory StandardEnvironment([Element parent]) =>
      new StandardEnvironment._(parent ?? document.body);

  StandardEnvironment._(this.parent);

  @override
  void dump({
    SudokuLoupe loupe,
    Iterable<int> highlights,
    String tableClass,
  }) {
    appendTable(parent, loupe, highlights: highlights, tableClass: tableClass);
  }

  @override
  void print(dynamic obj) {
    nativePrint(obj);
  }

  final Element parent;
}

void main() {
  List<Element> problemInputs = document.querySelectorAll(".problemInput");
  for (InputElement problemInput in problemInputs) {
    problemInput.onKeyDown.listen((KeyboardEvent event) {
      if (event.which == 13) {
        event.preventDefault();
        String source = (event.target as InputElement).value;
        SudokuBoard sudoku = new SudokuBoard.fromString(source);
        Element parent = document.querySelector("#result");
        StandardEnvironment env = new StandardEnvironment(parent);
        env.dump(loupe: sudoku.loupe);
        sudoku.eliminateResolved();
        env.dump(loupe: sudoku.loupe);
        parent.text = "";
        bool solved = searchSolution(sudoku, env: env).isNotEmpty;
        print("Solved: $solved");
      }
    });
  }
  Element parent = document.querySelector("#result");
  SudokuBoard problem = null;
  if (window.sessionStorage.containsKey("sudokuBoard")) {
    List<int> backing = JSON.decode(window.sessionStorage["sudokuBoard"]);
    problem = new SudokuBoard();
    problem.backing.setAll(0, backing);
  }
  if (problem == null) problem = generateProblem();
  parent.append(createBoard(problem));
}

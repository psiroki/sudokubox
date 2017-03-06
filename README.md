# sudokubox
CLI+web applications using the sudoku_core library

# sudoku_web

A sudoku web application. See it in action at: https://psiroki.github.io/sudokubox/

# sudoku_cli

A command line utility to generate or solve sudoku puzzles. Usage:

- sudoku_cli

Equivalent to `sudoku_cli generate -c 1`

- sudoku_cli generate [-c <**count**>]

Generates **count** number of puzzles (the default for **count** is 100) to stdout. Some info is written on stderr. Most of the puzzles are generated in sub-second time, but maybe one in a hundred of them may take up to a minute or two on your average system.

- sudoku_cli solve [-s] [-t] <**problem**>

Solves the puzzle provided in the **problem** parameter. The **problem** is provided in a string with the cells in order, with the empty cells marked with the `.` (period) character. The solution is written to stdout in the same format. Add **-s** to print the steps to stderr, **-t** to measure how much time it took to solve the puzzle.

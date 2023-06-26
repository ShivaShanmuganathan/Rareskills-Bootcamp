
from random import sample, shuffle

def generate_random_sudoku():
        sudoku = [[0] * 9 for _ in range(9)]
        solve_sudoku(sudoku)
        return sudoku

def solve_sudoku(sudoku):
    empty_cells = find_empty_cells(sudoku)
    if not empty_cells:
        return True

    row, col = empty_cells[0]
    numbers = sample(range(1, 10), 9)
    for num in numbers:
        if is_valid_number(sudoku, row, col, num):
            sudoku[row][col] = num
            if solve_sudoku(sudoku):
                return True
            sudoku[row][col] = 0

    return False

def find_empty_cells(sudoku):
    empty_cells = []
    for i in range(9):
        for j in range(9):
            if sudoku[i][j] == 0:
                empty_cells.append((i, j))
    return empty_cells

def is_valid_number(sudoku, row, col, num):
    for i in range(9):
        if sudoku[row][i] == num or sudoku[i][col] == num:
            return False

    start_row = (row // 3) * 3
    start_col = (col // 3) * 3
    for i in range(start_row, start_row + 3):
        for j in range(start_col, start_col + 3):
            if sudoku[i][j] == num:
                return False

    return True

def generate_wrong_sudoku():
    sudoku = [[0] * 9 for _ in range(9)]

    # Fill the diagonal 3x3 boxes with random values
    for i in range(0, 9, 3):
        digits = list(range(1, 10))
        shuffle(digits)
        for j in range(3):
            sudoku[i+j][i+j] = digits[j]

    # Shuffle the rows randomly within each box
    for i in range(0, 9, 3):
        rows = list(range(i, i+3))
        shuffle(rows)
        for j in range(3):
            sudoku[rows[j]] = sudoku[i+j]

    # Shuffle the columns randomly within each box
    for i in range(0, 9, 3):
        cols = list(range(i, i+3))
        shuffle(cols)
        for j in range(3):
            for k in range(9):
                sudoku[k][cols[j]] = sudoku[k][i+j]

    return sudoku

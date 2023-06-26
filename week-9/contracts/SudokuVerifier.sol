// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SudokuVerifier {
    uint8 public constant GRID_SIZE = 9;
    uint8 public constant SUBGRID_SIZE = 3;

    function checkSudoku(uint8[GRID_SIZE][GRID_SIZE] memory sudoku) public pure returns (bool) {
        // Check rows
        for (uint8 row = 0; row < GRID_SIZE; row++) {
            if (!isDistinctValues(sudoku[row])) {
                return false;
            }
        }

        // Check columns
        for (uint8 col = 0; col < GRID_SIZE; col++) {
            uint8[GRID_SIZE] memory column;
            for (uint8 row = 0; row < GRID_SIZE; row++) {
                column[row] = sudoku[row][col];
            }
            if (!isDistinctValues(column)) {
                return false;
            }
        }

        // Check subgrids
        for (uint8 startRow = 0; startRow < GRID_SIZE; startRow += SUBGRID_SIZE) {
            for (uint8 startCol = 0; startCol < GRID_SIZE; startCol += SUBGRID_SIZE) {
                uint8[GRID_SIZE] memory subgrid;
                uint8 index = 0;
                for (uint8 row = 0; row < SUBGRID_SIZE; row++) {
                    for (uint8 col = 0; col < SUBGRID_SIZE; col++) {
                        subgrid[index++] = sudoku[startRow + row][startCol + col];
                    }
                }
                if (!isDistinctValues(subgrid)) {
                    return false;
                }
            }
        }

        return true;
    }

    function isDistinctValues(uint8[GRID_SIZE] memory values) private pure returns (bool) {
        bool[GRID_SIZE + 1] memory used;
        for (uint8 i = 0; i < GRID_SIZE; i++) {
            uint8 value = values[i];
            if (value > GRID_SIZE || used[value]) {
                return false;
            }
            used[value] = true;
        }
        return true;
    }
}

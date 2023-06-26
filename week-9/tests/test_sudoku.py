from woke.testing import *
from woke.testing.fuzzing import *
from pytypes.contracts.SudokuVerifier import SudokuVerifier
from scripts import sudoku_generator
import copy


class SudokuVerifierTest(FuzzTest):
    def pre_sequence(self) -> None:
        self.sudoku_verifier = SudokuVerifier.deploy()
        self.sudoku = sudoku_generator.generate_random_sudoku()

    @flow()
    def random_increment(self) -> None:
        new_sudoku = copy.deepcopy(self.sudoku)
        loop_count = random_int(1, 10)
        for i in range(loop_count):
            row = random_int(0, 8)
            col = random_int(0, 8)
            new_val = random_int(1, 9)
            if (self.sudoku[row][col] != new_val):
                new_sudoku[row][col] = new_val
            else:
                new_sudoku[row][col] += 1
        assert self.sudoku_verifier.checkSudoku(new_sudoku) == False

    @invariant(period=1)
    def verifySudoku(self) -> None:
        assert self.sudoku_verifier.checkSudoku(self.sudoku) == True

    def post_sequence(self) -> None:
        wrong_sudoku = sudoku_generator.generate_wrong_sudoku()
        wrong_sudoku = sudoku_generator.generate_wrong_sudoku_2(self.sudoku)
        # print("Wrong Sudoku:", wrong_sudoku)
        assert self.sudoku_verifier.checkSudoku(wrong_sudoku) == False


@default_chain.connect()
def test_counter():
    default_chain.set_default_accounts(default_chain.accounts[0])
    SudokuVerifierTest().run(sequences_count=30, flows_count=60)

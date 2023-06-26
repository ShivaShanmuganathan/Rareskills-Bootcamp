
import woke.development.core
from woke.utils import get_package_version

if get_package_version("woke") != "3.4.2":
    raise RuntimeError("Pytypes generated for a different version of woke. Please regenerate.")

woke.development.core.errors = {b'\x08\xc3y\xa0': {'': ('woke.development.transactions', ('Error',))}, b'NH{q': {'': ('woke.development.transactions', ('Panic',))}}
woke.development.core.events = {}
woke.development.core.contracts_by_fqn = {'contracts/SudokuVerifier.sol:SudokuVerifier': ('pytypes.contracts.SudokuVerifier', ('SudokuVerifier',))}
woke.development.core.contracts_by_metadata = {b'\xa2dipfsX"\x12 \x80\xc1+\x9b\xa7\x18\x0ej4Q\xfeG\xf3]\x88\x9e4\x15\x86\x16\xee\xd5\x16\xa87?\xfe\x04\xd8\\\x9aNdsolcC\x00\x08\x14\x003': 'contracts/SudokuVerifier.sol:SudokuVerifier'}
woke.development.core.contracts_inheritance = {'contracts/SudokuVerifier.sol:SudokuVerifier': ('contracts/SudokuVerifier.sol:SudokuVerifier',)}
woke.development.core.contracts_revert_index = {}
woke.development.core.creation_code_index = [(((2303, b'\xc0\xd9\xed\xfe-\x82.\xbc\\\xd4/_\xe3Ez6&Z\x16\x02\xbe\xff\x01\xbdP9\xea,\xeer\xe1\xd8'),), 'contracts/SudokuVerifier.sol:SudokuVerifier')]

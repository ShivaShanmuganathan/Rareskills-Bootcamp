from woke.testing import *
from woke.testing.fuzzing import *
from pytypes.contracts.AMM import AMM
from pytypes.contracts.Pair import Pair
from pytypes.contracts.Pool import Pool
from pytypes.contracts.Token import Token
import copy

# class AMMTest(FuzzTest):
#     def pre_sequence(self) -> None:
#         self.TokenA = Token.deploy()
#         self.TokenB = Token.deploy()
#         print("Checking Token Address")
#         print(self.TokenA.address)
#         print(self.TokenB.address)
# self.AMM = AMM.deploy()

# @flow()
# def random_increment(self) -> None:
# new_sudoku = copy.deepcopy(self.sudoku)
# loop_count = random_int(1, 10)
# for i in range(loop_count):
#     row = random_int(0, 8)
#     col = random_int(0, 8)
#     new_val = random_int(1, 9)
#     if (self.sudoku[row][col] != new_val):
#         new_sudoku[row][col] = new_val
#     else:
#         new_sudoku[row][col] += 1
# assert self.sudoku_verifier.checkSudoku(new_sudoku) == False

# @invariant(period=1)
# def verifySudoku(self) -> None:
#     assert self.sudoku_verifier.checkSudoku(self.sudoku) == True

# def post_sequence(self) -> None:
#     wrong_sudoku = sudoku_generator.generate_wrong_sudoku()
#     wrong_sudoku = sudoku_generator.generate_wrong_sudoku_2(self.sudoku)
#     # print("Wrong Sudoku:", wrong_sudoku)
#     assert self.sudoku_verifier.checkSudoku(wrong_sudoku) == False


@default_chain.connect()
def test_counter():
    owner = default_chain.accounts[0]
    user1 = default_chain.accounts[1]
    user2 = default_chain.accounts[2]

    tokenA = Token.deploy(from_=owner)
    tokenB = Token.deploy(from_=owner)
    tokenC = Token.deploy(from_=owner)

    tokenA.mint(user1, 10 * 10**18, from_=owner)
    tokenB.mint(user1, 10 * 10**18, from_=owner)
    tokenC.mint(user1, 10 * 10**18, from_=owner)

    tokenA.mint(owner, 10010 * 10**18, from_=owner)
    tokenB.mint(owner, 10010 * 10**18, from_=owner)
    tokenC.mint(owner, 10010 * 10**18, from_=owner)

    poolA = Pool.deploy(tokenA.address, from_=owner)
    poolB = Pool.deploy(tokenB.address, from_=owner)
    poolC = Pool.deploy(tokenC.address, from_=owner)

    tokenA.approve(poolA.address, 10001 * 10**18, from_=owner)
    tokenB.approve(poolB.address, 10001 * 10**18, from_=owner)
    tokenC.approve(poolC.address, 10001 * 10**18, from_=owner)

    poolA.deposit(10000 * 10**18, from_=owner)
    poolB.deposit(10000 * 10**18, from_=owner)
    poolC.deposit(10000 * 10**18, from_=owner)

    # tokenA.mint(poolA, 10000 * 10**18, from_=owner)
    # tokenB.mint(poolB, 10000 * 10**18, from_=owner)
    # tokenC.mint(poolC, 10000 * 10**18, from_=owner)

    print("Checking Token Balance")
    print(tokenA.balanceOf(user1))
    print(tokenB.balanceOf(user1))
    print(tokenC.balanceOf(user1))
    print(tokenA.balanceOf(poolA))
    print(tokenB.balanceOf(poolB))
    print(tokenC.balanceOf(poolC))

    amm = AMM.deploy(from_=owner)

    pair1 = Pair.deploy(poolA.address, poolB.address, amm.address, from_=owner)
    pair2 = Pair.deploy(poolB.address, poolC.address, amm.address, from_=owner)

    # print("Checking Pair Address")
    # print(pair1.address)

    poolA.approveAndAddPairContract(pair1.address, from_=owner)
    poolB.approveAndAddPairContract(pair1.address, from_=owner)
    poolB.approveAndAddPairContract(pair2.address, from_=owner)
    poolC.approveAndAddPairContract(pair2.address, from_=owner)

    amm.setMaxApproval(pair1.address, tokenA.address, from_=owner)
    amm.setMaxApproval(pair1.address, tokenB.address, from_=owner)
    amm.setMaxApproval(pair2.address, tokenB.address, from_=owner)
    amm.setMaxApproval(pair2.address, tokenC.address, from_=owner)

    pair1.setMaxApproval(poolA.address, tokenA.address, from_=owner)
    pair1.setMaxApproval(poolB.address, tokenB.address, from_=owner)
    pair2.setMaxApproval(poolB.address, tokenB.address, from_=owner)
    pair2.setMaxApproval(poolC.address, tokenC.address, from_=owner)

    print("Checking Contract Addresses")
    print("amm address: ", amm.address)
    print("pair1 address: ", pair1.address)
    print("pair2 address: ", pair2.address)
    print("poolA address: ", poolA.address)
    print("poolB address: ", poolB.address)
    print("poolC address: ", poolC.address)

    print("Checking Token and Pool Token Address")
    print(tokenA.address, ":", poolA.token())
    print(tokenB.address, ":", poolB.token())
    print(tokenC.address, ":", poolC.token())

    print("Set token to pool in AMM")
    pair1.setTokenToPool(tokenA.address, poolA.address, from_=owner)
    pair1.setTokenToPool(tokenB.address, poolB.address, from_=owner)
    pair2.setTokenToPool(tokenB.address, poolB.address, from_=owner)
    pair2.setTokenToPool(tokenC.address, poolC.address, from_=owner)
    # amm.setTokenToPool(tokenB.address, poolB.address, from_=owner)
    # amm.setTokenToPool(tokenC.address, poolC.address, from_=owner)

    # pair1.set

    print("Checking Token to Pool in AMM")
    print(poolA.address, ":", pair1.tokenToPool(tokenA.address))
    print(poolB.address, ":", pair1.tokenToPool(tokenB.address))
    print(poolB.address, ":", pair2.tokenToPool(tokenB.address))
    print(poolC.address, ":", pair2.tokenToPool(tokenC.address))
    # print(tokenC.address, ":", amm.tokenToPool(tokenC.address))

    print("Adding Pairs to AMM")
    amm.addPair(pair1.address, from_=owner)
    amm.addPair(pair2.address, from_=owner)

    print("Checking Pairs in AMM")
    print(amm.pairs(0))
    print(amm.pairs(1))

    print("Checking Pools in Pairs")
    print(pair1.poolA())
    print(pair1.poolB())
    print(pair2.poolA())
    print(pair2.poolB())

    print("Checking AMM Swaps")
    print("Swapping 10 TokenA for TokenB")
    tokenA.approve(amm.address, 10 * 10**18, from_=user1)
    print("User 1 tokenA balance: ", tokenA.balanceOf(user1))
    print("User 1 tokenB balance: ", tokenB.balanceOf(user1))
    print("PoolA tokenA balance: ", tokenA.balanceOf(poolA))
    print("PoolB tokenB balance: ", tokenB.balanceOf(poolB))
    print("Checking Pair Balance: " + str(tokenA.balanceOf(pair1.address)))
    print("Checking Pair Balance TokenB: " + str(tokenB.balanceOf(pair1.address)))

    tx = amm.swapExactIn(tokenA.address, 10 * 10**18, tokenB.address, 0, from_=user1)
    print(tx.console_logs)

    print("Checking AMM After Swap")
    print("User 1 tokenA balance: ", tokenA.balanceOf(user1))
    print("User 1 tokenB balance: ", tokenB.balanceOf(user1))
    print("poolA tokenA balance: ", tokenA.balanceOf(poolA))
    print("poolB tokenB balance: ", tokenB.balanceOf(poolB))
    print("Checking Pair Balance: " + str(tokenA.balanceOf(pair1.address)))
    print("Checking Pair Balance TokenB: " + str(tokenB.balanceOf(pair1.address)))
    print("Checking Pool Balance: " + str(tokenA.balanceOf(poolA.address)))
    print("Checking Reserve Balance: " + str(poolA.getReserve()))
    print()

    print("Checking another swap")
    print("User 1 tokenB balance: ", tokenB.balanceOf(user1))
    print("User 1 tokenC balance: ", tokenC.balanceOf(user1))
    print("poolB tokenB balance: ", tokenB.balanceOf(poolB))
    print("poolC tokenB balance: ", tokenB.balanceOf(poolC))

    tokenB.approve(amm.address, 10 * 10**18, from_=user1)

    tx2 = amm.swapExactOut(tokenB.address, tokenC.address, 5 * 10**18, 1, from_=user1)
    print(tx2.console_logs)

    print("After Swap")
    print("User 1 tokenB balance: ", tokenB.balanceOf(user1))
    print("User 1 tokenC balance: ", tokenC.balanceOf(user1))
    print("poolB tokenB balance: ", tokenB.balanceOf(poolB))
    print("poolC tokenB balance: ", tokenC.balanceOf(poolC))

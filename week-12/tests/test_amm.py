from woke.testing import *
from woke.testing.fuzzing import *
from pytypes.contracts.AMM import AMM
from pytypes.contracts.Pair import Pair
from pytypes.contracts.Pool import Pool
from pytypes.contracts.Token import Token
from pytypes.contracts.AttackerContract import AttackerContract


@default_chain.connect()
def test_amm():
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

    amm = AMM.deploy(from_=owner)

    pair1 = Pair.deploy(poolA.address, poolB.address, amm.address, from_=owner)
    pair2 = Pair.deploy(poolB.address, poolC.address, amm.address, from_=owner)

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

    pair1.setTokenToPool(tokenA.address, poolA.address, from_=owner)
    pair1.setTokenToPool(tokenB.address, poolB.address, from_=owner)
    pair2.setTokenToPool(tokenB.address, poolB.address, from_=owner)
    pair2.setTokenToPool(tokenC.address, poolC.address, from_=owner)

    assert poolA.address == pair1.tokenToPool(tokenA.address)
    assert poolB.address == pair1.tokenToPool(tokenB.address)
    assert poolB.address == pair2.tokenToPool(tokenB.address)
    assert poolC.address == pair2.tokenToPool(tokenC.address)

    amm.addPair(pair1.address, from_=owner)
    amm.addPair(pair2.address, from_=owner)

    assert pair1.address == amm.pairs(0)
    assert pair2.address == amm.pairs(1)
    assert poolA.address == pair1.poolA()
    assert poolB.address == pair1.poolB()
    assert poolB.address == pair2.poolA()
    assert poolC.address == pair2.poolB()

    print()
    print("Checking AMM Swap1")
    print()
    print("Swapping 10 TokenA for TokenB")
    tokenA.approve(amm.address, 10 * 10**18, from_=user1)

    user1_tokenA_balance_before = tokenA.balanceOf(user1)
    user1_tokenB_balance_before = tokenB.balanceOf(user1)
    poolA_tokenA_balance_before = tokenA.balanceOf(poolA)
    poolB_tokenB_balance_before = tokenB.balanceOf(poolB)
    tokenA_input = 10 * 10**18

    estimated_token_out = amm.getEstimatedTokenOut(
        tokenA.address, tokenB.address, tokenA_input, 0
    )
    print("Estimated Token Out 🪙: ", estimated_token_out)

    tx = amm.swapExactIn(tokenA.address, tokenA_input, tokenB.address, 0, from_=user1)

    print("Checking AMM After Swap")
    user1_tokenA_balance_after = tokenA.balanceOf(user1)
    user1_tokenB_balance_after = tokenB.balanceOf(user1)
    poolA_tokenA_balance_after = tokenA.balanceOf(poolA)
    poolB_tokenB_balance_after = tokenB.balanceOf(poolB)

    assert user1_tokenA_balance_before - user1_tokenA_balance_after == tokenA_input
    assert (
        user1_tokenB_balance_after - user1_tokenB_balance_before == estimated_token_out
    )
    assert poolA_tokenA_balance_after - poolA_tokenA_balance_before == tokenA_input
    assert (
        poolB_tokenB_balance_before - poolB_tokenB_balance_after == estimated_token_out
    )
    print("Swap1 Successful 🚀")
    print()

    print("Checking AMM Swap2")
    print("Swapping 5 TokenB for TokenC")

    user1_tokenB_balance_before = tokenB.balanceOf(user1)
    user1_tokenC_balance_before = tokenC.balanceOf(user1)
    poolB_tokenB_balance_before = tokenB.balanceOf(poolB)
    poolC_tokenC_balance_before = tokenC.balanceOf(poolC)
    tokenC_output = 5 * 10**18

    tokenB.approve(amm.address, 10 * 10**18, from_=user1)

    estimated_tokenB_in = amm.getEstimatedTokenIn(
        tokenB.address, tokenC.address, tokenC_output, 1
    )
    print("Estimated Token In 🪙: ", estimated_tokenB_in)

    tx2 = amm.swapExactOut(
        tokenB.address, tokenC.address, tokenC_output, 1, from_=user1
    )
    # print(tx2.console_logs)

    user1_tokenB_balance_after = tokenB.balanceOf(user1)
    user1_tokenC_balance_after = tokenC.balanceOf(user1)
    poolB_tokenB_balance_after = tokenB.balanceOf(poolB)
    poolC_tokenC_balance_after = tokenC.balanceOf(poolC)

    print("Checking After Swap")

    assert (
        user1_tokenB_balance_before - user1_tokenB_balance_after == estimated_tokenB_in
    )
    assert user1_tokenC_balance_after - user1_tokenC_balance_before == tokenC_output
    assert (
        poolB_tokenB_balance_after - poolB_tokenB_balance_before == estimated_tokenB_in
    )
    assert poolC_tokenC_balance_before - poolC_tokenC_balance_after == tokenC_output
    print("Swap2 Successful 🚀")
    print()

    print("Checking AMM Swap3")
    print("Swapping 15 TokenC for TokenB")

    user1_tokenB_balance_before = tokenB.balanceOf(user1)
    user1_tokenC_balance_before = tokenC.balanceOf(user1)
    poolB_tokenB_balance_before = tokenB.balanceOf(poolB)
    poolC_tokenC_balance_before = tokenC.balanceOf(poolC)
    tokenC_input = 15 * 10**18
    tokenC.approve(amm.address, tokenC_input, from_=user1)

    estimated_token_out = amm.getEstimatedTokenOut(
        tokenC.address, tokenB.address, tokenC_input, 1
    )
    print("Estimated Token Out 🪙: ", estimated_token_out)

    tx = amm.swapExactIn(tokenC.address, tokenC_input, tokenB.address, 1, from_=user1)

    print("Checking AMM After Swap")
    user1_tokenB_balance_after = tokenB.balanceOf(user1)
    user1_tokenC_balance_after = tokenC.balanceOf(user1)
    poolB_tokenB_balance_after = tokenB.balanceOf(poolB)
    poolC_tokenC_balance_after = tokenC.balanceOf(poolC)

    assert user1_tokenC_balance_before - user1_tokenC_balance_after == tokenC_input
    assert (
        user1_tokenB_balance_after - user1_tokenB_balance_before == estimated_token_out
    )
    assert poolC_tokenC_balance_after - poolC_tokenC_balance_before == tokenC_input
    assert (
        poolB_tokenB_balance_before - poolB_tokenB_balance_after == estimated_token_out
    )
    print("Swap3 Successful 🚀")
    print()

    print("Checking Reentrancy on AMM through Attack Contract")

    print("Deploying Attack Contract")
    attackContract = AttackerContract.deploy(
        amm.address, tokenB.address, tokenC.address, 10 * 10**18, 1, from_=owner
    )

    print("Minting 100 TokenA to Attack Contract")
    tokenA.mint(attackContract.address, 100 * 10**18, from_=owner)
    tokenA.mint(user1.address, 100 * 10**18, from_=owner)

    print("Setting Approval for Attack Contract")
    attackContract.setMaxApproval(amm.address, tokenA.address, from_=owner)
    attackContract.setMaxApproval(amm.address, tokenB.address, from_=owner)
    attackContract.setMaxApproval(amm.address, tokenC.address, from_=owner)

    print("Attack Contract Swapping 10 TokenA for TokenB")
    user1_tokenA_balance_before = tokenA.balanceOf(user1)
    user1_tokenB_balance_before = tokenB.balanceOf(user1)
    user1_tokenC_balance_before = tokenC.balanceOf(user1)

    print("Checking attack contract tokenA Balance")
    print(tokenA.balanceOf(attackContract.address))

    print("Checking attack contract tokenB Balance")
    print(tokenB.balanceOf(attackContract.address))

    tx = attackContract.attack(
        tokenA.address, 10 * 10**18, tokenB.address, 0, from_=user1
    )

    print("Checking attack contract tokenA Balance")
    print(tokenA.balanceOf(attackContract.address))

    print("Checking attack contract tokenB Balance")
    print(tokenB.balanceOf(attackContract.address))

    print("Attack status")
    print(attackContract.attacked())

    print("Checking Addresses")
    print("Attack Contract", attackContract.address)
    print("AMM Contract", attackContract.ammContract())
    print("Token A", attackContract.tokenA())
    print("Token B", attackContract.tokenB())

    print("Checking Tx Logs")
    print(tx.events)

    # print("Check attack status again")
    # attackContract.onTokenTransfer(tokenA.address, 10 * 10**18, from_=user1)
    # print(attackContract.attacked())

    user1_tokenA_balance_after = tokenA.balanceOf(user1)
    user1_tokenB_balance_after = tokenB.balanceOf(user1)
    user1_tokenC_balance_after = tokenC.balanceOf(user1)

    print("Checking After Swap")
    print("user1_tokenA_balance_before", user1_tokenA_balance_before)
    print("user1_tokenB_balance_before", user1_tokenB_balance_before)
    print("user1_tokenC_balance_before ", user1_tokenC_balance_before)
    print("user1_tokenA_balance_after", user1_tokenA_balance_after)
    print("user1_tokenB_balance_after", user1_tokenB_balance_after)
    print("user1_tokenC_balance_after", user1_tokenC_balance_after)

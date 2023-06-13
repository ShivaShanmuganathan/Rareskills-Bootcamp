# EVM puzzles

A collection of EVM puzzles. Each puzzle consists on sending a successful transaction to a contract. The bytecode of the contract is provided, and you need to fill the transaction data that won't revert the execution.

## How to play

Clone this repository and install its dependencies (`npm install` or `yarn`). Then run:

```
npx hardhat play
```

And the game will start.

In some puzzles you only need to provide the value that will be sent to the contract, in others the calldata, and in others both values.

You can use [`evm.codes`](https://www.evm.codes/)'s reference and playground to work through this.


## Solutions
1. Value: 8
2. Value: 4
3. Calldata: 0xFFFFFFFF
4. Value: 6
5. Value: 16
6. Calldata: 0x000000000000000000000000000000000000000000000000000000000000000a
7. Calldata: 0x60016000f3
8. Calldata: 0x60FD60005360016000F3
9. Value: 2
Calldata: 0xFFFFFFFF
10. Value: 15
Calldata: 0xFFFFFF
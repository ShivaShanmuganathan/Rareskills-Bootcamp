# Practice

### EVM Puzzles (suggested: 3 days)

- [x]  Complete all 10 https://github.com/fvictorio/evm-puzzles

### Ethernaut (suggested 2 days)

- [x]  Ethernaut 12 - Privacy
- [x]  Ethernaut 13 - Gatekeeper one
- [x]  Ethernaut 18 - Magic Number

### Gas puzzles (suggested 1 day)

https://github.com/RareSkills/gas-puzzles

- [x]  Array Sum
- [x]  Require


## Ethernaut Solutions

### [12. Privacy](https://ethernaut.openzeppelin.com/level/0x1ca9f1c518ec5681C2B7F97c7385C0164c3A22Fe)

#### Privacy Solution
1. Goal is to call unlock method with key
2. Retreive the `key` from `bytes32 data[3]` private variable and use it to call the `unlock` method
3. `key` data `(data[2])` is stored at storage slot 5
4. use `await web3.eth.getStorageAt(contract_address, 5)` to get the data at slot 5
5. convert the key to 16 bytes by halving it
6. call `unlock` method with `key`


### [13. GateKeeper One](https://ethernaut.openzeppelin.com/level/0x46f79002907a025599f355A04A512A6Fd45E671B)

#### GateKeeper One Solution
1. Goal is to bypass the 3 require statements and set the entrant address 
2. Figure out `_gateKey` value 
3. call `enter` method with `_gateKey`


### [13. MagicNumber](https://ethernaut.openzeppelin.com/level/0x4A151908Da311601D967a6fB9f8cFa5A3E88a251)
#### MagicNumber Solution
1. Goal is to make a contract with 10 opcodes that returns 42 when calling the function `whatIsTheMeaningOfLife`
2. `magicNumber.huff`
3. Contract OPCODE: 600a8060093d393df3602a60005260206000f3
4. Create contract using the bytecode
`new_addr = await web3.eth.sendTransaction({ from: player, data: '600a8060093d393df3602a60005260206000f3'}, function(err,res){console.log(res)})`
5. Set address of newly created contract
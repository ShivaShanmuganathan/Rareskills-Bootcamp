# Rareskills-Bootcamp

## Week 1

- [/] **Markdown file 1:** Create a markdown file about what problems ERC777 and ERC1363 solves. Why was ERC1363 introduced, and what issues are there with ERC777?
- [ ] **Markdown file 2:** Why does the SafeERC20 program exist and when should it be used?
- [x] **Solidity contract 1:** Token with sanctions. Create a fungible token that allows an admin to ban specified addresses from sending and receiving tokens.

  - [x] Create Contract: `SanctionedToken.sol`
  - [x] Add Natspec comments
  - [x] Use Formatter
  - [x] Add tests: npx hardhat test  --grep "SanctionToken"

- [x] **Solidity contract 2:** Token with god mode. A special address is able to transfer tokens between addresses at will.

  - [x] Create Contract
  - [x] Add Natspec comments
  - [x] Use Formatter
  - [x] Add tests: `npx hardhat test  --grep "TokenWithGodMode"`

- [x] **Solidity contract 3:** (**hard**) Token sale and buyback with bonding curve. The more tokens a user buys, the more expensive the token becomes. To keep things simple, use a linear bonding curve. When a person sends a token to the contract with ERC1363 or ERC777, it should trigger the receive function. If you use a separate contract to handle the reserve and use ERC20, you need to use the approve and send workflow. This should support fractions of tokens.

  - [x] Create Contract
    - [x] Figure out formula
    - [x] Think if you can use onTransferReceived
    - [x] Make view method to get price of token -> `getBuyPrice` and `getSellPrice`
    - [x] Consider the case someone might [sandwhich attack](https://medium.com/coinmonks/defi-sandwich-attack-explain-776f6f43b2fd) a bonding curve. What can you do about it?
      - [x] The depositTime ensures that users cannot immediately sell their tokens after buying them, as they must wait for a specified time interval before being eligible to sell.
    - [x] We have intentionally omitted other resources for bonding curves, we encourage you to find them on your own.
  - [x] Add Natspec comments
  - [x] Use Formatter
  - [x] Add tests
  

- [ ] **Solidity contract 4: (hard)** Untrusted escrow. Create a contract where a buyer can put an **arbitrary** ERC20 token into a contract and a seller can withdraw it 3 days later. Based on your readings above, what issues do you need to defend against? Create the safest version of this that you can while guarding against issues that you cannot control.
  - [ ] Create Contract
  - [ ] Add Natspec comments
  - [ ] Use Formatter
  - [ ] Add tests

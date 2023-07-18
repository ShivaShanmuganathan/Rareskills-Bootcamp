// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Pair {
    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin
    ) external;

    function swapExactOut(
        address tokenIn,
        uint256 amountInMax,
        address tokenOut,
        uint256 amountOut
    ) external;
}

contract AMM is Ownable {
    address public tokenA;
    address public tokenB;
    Pair public pair;

    bool private isSwapping;

    modifier nonReentrant() {
        require(!isSwapping, "Reentrant call");
        isSwapping = true;
        _;
        isSwapping = false;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOutMin
    ) external nonReentrant {
        pair.swapExactIn(tokenIn, amountIn, tokenOut, amountOutMin);
    }

    function swapExactOut(
        address tokenIn,
        uint256 amountInMax,
        address tokenOut,
        uint256 amountOut
    ) external nonReentrant {
        pair.swapExactOut(tokenIn, amountInMax, tokenOut, amountOut);
    }
}

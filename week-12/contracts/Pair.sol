// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface Pool {
    function getReserve() external returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

contract Pair is Ownable {
    address public poolA;
    address public poolB;
    address public ammContract; // The address of the AMM contract

    modifier isAMM() {
        require(
            msg.sender == ammContract,
            "Not authorized. Only AMM contract can call this function."
        );
        _;
    }

    constructor(address _poolA, address _poolB, address _ammContract) {
        poolA = _poolA;
        poolB = _poolB;
        ammContract = _ammContract;
    }

    function _getOutputAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputAmount > 0, "Input amount must be greater than 0");
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        // The constant product formula: inputReserve * outputReserve = (inputReserve - x) * (outputReserve + y)
        // where 'x' is the input amount and 'y' is the output amount

        // Rearranging the formula to solve for 'y'
        uint256 outputAmount = (inputReserve * outputReserve) /
            (inputReserve + inputAmount);

        require(outputAmount > 0, "Invalid output amount");

        return outputAmount;
    }

    function _getInputAmount(
        uint256 outputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(outputAmount > 0, "Output amount must be greater than 0");
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        // The constant product formula: inputReserve * outputReserve = (inputReserve - x) * (outputReserve + y)
        // where 'x' is the input amount and 'y' is the output amount

        // Rearranging the formula to solve for 'x'
        uint256 inputAmount = (inputReserve * outputAmount) /
            (outputReserve - outputAmount);

        require(inputAmount > 0, "Invalid input amount");

        return inputAmount;
    }

    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external isAMM {
        require(tokenIn == poolA || tokenIn == poolB, "Invalid tokenIn");
        require(tokenOut == poolA || tokenOut == poolB, "Invalid tokenOut");
        require(amountIn > 0, "Amount must be greater than 0");

        uint256 amountOut;
        uint256 reserveIn;
        uint256 reserveOut;

        if (tokenIn == poolA && tokenOut == poolB) {
            reserveIn = Pool(poolA).getReserve();
            reserveOut = Pool(poolB).getReserve();
        } else if (tokenIn == poolB && tokenOut == poolA) {
            reserveIn = Pool(poolB).getReserve();
            reserveOut = Pool(poolA).getReserve();
        } else {
            revert("Invalid tokenIn/tokenOut pair");
        }

        amountOut = _getOutputAmount(amountIn, reserveIn, reserveOut);

        Pool(poolA).deposit(amountIn);
        
        Pool(poolB).withdraw(amountOut);
    }

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOutMin
    ) external isAMM {
        require(tokenIn == poolA || tokenIn == poolB, "Invalid tokenIn");
        require(tokenOut == poolA || tokenOut == poolB, "Invalid tokenOut");
        require(amountOutMin > 0, "Amount must be greater than 0");

        uint256 amountIn;
        uint256 reserveIn;
        uint256 reserveOut;

        if (tokenIn == poolA && tokenOut == poolB) {
            reserveIn = Pool(poolA).getReserve();
            reserveOut = Pool(poolB).getReserve();
        } else if (tokenIn == poolB && tokenOut == poolA) {
            reserveIn = Pool(poolB).getReserve();
            reserveOut = Pool(poolA).getReserve();
        } else {
            revert("Invalid tokenIn/tokenOut pair");
        }

        amountIn = _getInputAmount(amountOutMin, reserveIn, reserveOut);

        Pool(poolA).deposit(amountIn);
        Pool(poolB).withdraw(amountOutMin);
    }
}

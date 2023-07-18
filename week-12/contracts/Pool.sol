// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pool is Ownable {
    IERC20 public token;

    address public pairContract;
    uint256 public constant maxApprovalAmount = type(uint256).max;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function approvePairContract(address _pairContract) external onlyOwner {
        require(_pairContract != address(0), "Pair contract address not set");

        require(
            token.approve(pairContract, maxApprovalAmount),
            "Approval failed"
        );
    }
}

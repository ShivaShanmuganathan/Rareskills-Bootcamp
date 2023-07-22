// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "woke/console.sol";

contract Pool is Ownable {
    IERC20 public token;
    uint256 private reserve;
    address[] public pairs;
    uint256 public constant maxApprovalAmount = type(uint256).max;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdraw(address indexed withdrawer, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function approveAndAddPairContract(
        address _pairContract
    ) external onlyOwner {
        require(_pairContract != address(0), "Pair contract address not set");
        require(
            token.approve(_pairContract, maxApprovalAmount),
            "Approval failed"
        );
        pairs.push(_pairContract);
    }

    function checkPairExists(address pairContract) public view returns (bool) {
        for (uint256 i = 0; i < pairs.length; i++) {
            if (pairs[i] == pairContract) {
                return true;
            }
        }
        return false;
    }

    modifier onlyPair() {
        require(
            checkPairExists(msg.sender),
            "Not authorized. Only pair contract can call this function."
        );
        _;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        reserve += amount;
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyPair {
        require(amount > 0, "Amount must be greater than 0");
        require(reserve >= amount, "Insufficient reserves");
        reserve -= amount;
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    function getReserve() external view returns (uint256) {
        return reserve;
    }
}

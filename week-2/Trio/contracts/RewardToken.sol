// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RewardToken
 * @author Shiva
 * @notice This smart contract is a Reward Token

 */

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract RewardToken is ERC20 {
    address public immutable stakeAndEarn;

    constructor(
        string memory _name,
        string memory _symbol,
        address _stakeAndEarn
    ) ERC20(_name, _symbol) {
        stakeAndEarn = _stakeAndEarn;
    }

    /// @notice Burn tokens
    /// @param from Address from which token will be burned
    /// @param amount Amount of token to burn
    function burn(address from, uint256 amount) external {
        require(from == msg.sender, "from address must be sender");
        _burn(from, amount);
    }

    /// @notice Only stakingContract is able to mint tokens
    /// @param to Address to which token will be minted
    /// @param amount Amount of token to mint
    function mint(address to, uint256 amount) external {
        require(
            msg.sender == stakeAndEarn,
            "msg.sender is not stake and earn contract"
        );
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RewardToken
 * @author Shiva
 * @notice This smart contract is a Reward Token
 * @dev A ERC20 contract representing a reward token that can be minted only by a specific staking contract.
 */

interface IRewardToken is IERC20 {
    /**
     * @dev Mint reward tokens to a specified address.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external;
}

contract RewardToken is ERC20 {
    address public immutable stakeAndEarn;

    /**
     * @dev Create a new RewardToken contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _stakeAndEarn The address of the staking contract that is allowed to mint tokens.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _stakeAndEarn
    ) ERC20(_name, _symbol) {
        stakeAndEarn = _stakeAndEarn;
    }

    /**
     * @dev Burn tokens from a specified address.
     * @param from The address to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external {
        require(from == msg.sender, "from address must be sender");
        _burn(from, amount);
    }

    /**
     * @dev Mint reward tokens to a specified address.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external {
        require(
            msg.sender == stakeAndEarn,
            "msg.sender is not stake and earn contract"
        );
        _mint(to, amount);
    }
}
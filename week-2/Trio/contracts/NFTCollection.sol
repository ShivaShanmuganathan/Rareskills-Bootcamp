// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title NFTCollection
 * @author Shiva
 * @notice This smart contract implements a smart contract trio: NFT with merkle tree discount, ERC20 token, staking contract.
 * @dev ERC721 NFTs are created with a supply of 20, and an ERC2918 royalty of 2.5% is included in the contract.
 */

contract NFTCollection is Ownable2Step, ReentrancyGuard, ERC721, ERC2981 {
    uint256 public constant tokenPrice = 0.1 ether;
    uint256 public constant discountedTokenPrice = 0.075 ether;
    uint256 public constant maxSupply = 20;
    bytes32 private merkleRoot;
    uint256 public tokenId = 1;

    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private ticketNumberBitmap = MAX_INT;

    event EtherWithdrawn(address indexed owner, uint256 amount);

    /**
     * @dev Constructor for the NFTCollection contract.
     * @param _name string Name of the token.
     * @param _symbol string Symbol of the token.
     * @param _merkleRoot Root of the merkle tree
     * @param royaltyFee Default royalty fee to be set for this NFT contract
     */
    constructor(
        string memory _name,
        string memory _symbol,
        bytes32 _merkleRoot,
        uint96 royaltyFee
    ) ERC721(_name, _symbol) {
        merkleRoot = _merkleRoot;
        _setDefaultRoyalty(_msgSender(), royaltyFee);
    }

    /**
     * @notice Mint NFT with tokenPrice
     * @param _to The address to which NFT will be minted to
     * @return tokenId minted for user
     */
    function mint(address _to) public payable nonReentrant returns (uint256) {
        require(msg.value >= tokenPrice, "Insufficient payment amount");
        uint256 _tokenId = tokenId;
        require(_tokenId <= maxSupply, "Maximum token supply has been reached");
        unchecked {
            tokenId = _tokenId + 1;
        }
        _safeMint(_to, _tokenId);
        return _tokenId;
    }

    /**
     * @dev Verifies a ticket using a merkle proof and mints a new NFT for the caller.
     * @param ticketNumber The number of the ticket to be verified.
     * @param merkleProof The merkle proof used to verify the ticket ownership.
     * @return The ID of the newly minted NFT.
     * Requirements:
     * - The caller must send sufficient payment to cover the discounted token price.
     * - The ticket number must not have been used before.
     * - The provided merkle proof must be valid.
     * - The maximum token supply has not been reached.
     */

    function verifyAndMint(
        uint8 ticketNumber,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant returns (uint256) {
        require(
            msg.value >= discountedTokenPrice,
            "Insufficient payment amount"
        );

        require(
            checkTicketStatus(ticketNumber),
            "ticketNumber has already been used"
        );
        require(
            isValidProof(ticketNumber, _msgSender(), merkleProof),
            "Invalid merkle proof"
        );

        ticketNumberBitmap = ticketNumberBitmap & ~(uint256(1) << ticketNumber);
        uint256 _tokenId = tokenId;
        require(_tokenId <= maxSupply, "Maximum token supply has been reached");
        unchecked {
            tokenId = _tokenId + 1;
        }
        _safeMint(_msgSender(), _tokenId);
        return _tokenId;
    }

    /**
     * @notice Modify a token royalty settings
     * @param _tokenId uint256 ID of the token to which royalty will be changed
     * @param receiver address Address that will receive royalties on sell
     * @param feeNumerator uint96 Amount of royalty, this is divided by 10000 to get a percentage
     */

    /**
     * @dev Sets the royalty receiver and fee for a given token.
     * @param _tokenId The ID of the token to set the royalty for.
     * @param receiver The address that should receive the royalty.
     * @param feeNumerator The numerator of the royalty fee, as a fraction of the total sale price. The denominator is set to 10,000.
     * @notice Only the owner or an approved address of the token can call this function.
     */
    function setTokenRoyalty(
        uint256 _tokenId,
        address receiver,
        uint96 feeNumerator
    ) external {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "Address is neither owner nor approved"
        );
        _setTokenRoyalty(_tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Standard Interface declaration
     * @dev ERC-165 support
     * @param interfaceId bytes4 The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev baseURI used with tokenURI
     */
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://raw.githubusercontent.com/ShivaShanmuganathan/Rareskills-Bootcamp/tree/week-2/week-2/nft-collection/";
    }

    /**
     * @dev Withdraws the Ether balance from the contract and transfers it to the owner's address.
     * @notice Only the contract owner can call this function.
     */
    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit EtherWithdrawn(owner(), balance);
    }

    /**
     * @dev Checks if a given ticket can be claimed by a specific address using a provided Merkle proof.
     * @param ticketNumber The ticket number to check.
     * @param claimer The address of the claimer.
     * @param merkleProof The Merkle proof used to verify the claim.
     * @return A boolean indicating whether the ticket can be claimed or not.
     */

    function canClaim(
        uint256 ticketNumber,
        address claimer,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        return
            checkTicketStatus(ticketNumber) &&
            isValidProof(ticketNumber, claimer, merkleProof);
    }

    /**
     * @dev Checks if the provided `merkleProof` is valid for the given `ticketNumber` and `claimer`.
     * @param ticketNumber The ticket number to be verified.
     * @param claimer The address of the user claiming the ticket.
     * @param merkleProof The merkle proof to be validated.
     * @return A boolean indicating whether the provided `merkleProof` is valid or not.
     */
    function isValidProof(
        uint256 ticketNumber,
        address claimer,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(
                    bytes.concat(keccak256(abi.encode(ticketNumber, claimer)))
                )
            );
    }

    /**
     * @dev Checks whether the ticket with the given ticket number is available for purchase or not.
     * @param ticketNumber The ticket number to check.
     * @return A boolean indicating whether the ticket is available or not.
     * Requirements:
     * - Ticket number must be lesser than 20.
     */

    function checkTicketStatus(
        uint256 ticketNumber
    ) internal view returns (bool) {
        require(ticketNumber < 20, "total supply error");
        uint256 isTicketNumberAvailable = (ticketNumberBitmap >> ticketNumber) &
            uint256(1);
        return isTicketNumberAvailable == 1;
    }

    /**
     * @dev Allows the owner to set the merkle root for the event
     * @param _merkleRoot The new merkle root value to be set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}

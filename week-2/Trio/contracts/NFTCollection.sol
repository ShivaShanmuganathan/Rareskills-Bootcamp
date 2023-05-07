// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// use reverts instead of require
// use EIP-712
// use OZ BitMaps

/**
 * @title NFTCollection
 *s @author Shiva
 * @notice This smart contract implements a smart contract trio: NFT with merkle tree discount, ERC20 token, staking contract.
 * @dev ERC721 NFTs are created with a supply of 20, and an ERC2918 royalty of 2.5% is included in the contract.
 */

//
//
// A merkle tree is used to allow addresses to mint NFTs at a discount, and openzeppelin's implementation of a bitmap is used for this.
// An ERC20 token is created to reward staking.
// A third smart contract is created to mint new ERC20 tokens and receive ERC721 tokens for staking.
// The staking mechanism follows the sequence described in the accompanying video.
// The funds from the NFT sale in the contract can be withdrawn by the owner using Ownable2Step.
// For more information, please visit [website] or see the accompanying documentation.

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
     * @notice Mint NFT with price = tokenPrice
     * @param _to address Address to which NFT will be minted
     * @return tokenId to let user know
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
     * @notice Mint NFT during presale. Valide presale ticketNumber is needed (whitelist)
     * @dev Some assembly code has been used for gas optimization purposes
     * @param ticketNumber uint256 Presale ticketNumber associated to _msgSender() address
     * @param merkleProof bytes32[] Proof used to verify if _msgSender() can mint using presale ticketNumber
     * @return tokenId to let user know
     */
    function verifyAndMint(
        uint8 ticketNumber,
        bytes32[] calldata merkleProof
    ) external payable returns (uint256) {
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

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit EtherWithdrawn(owner(), balance);
    }

    function canClaim(
        uint256 ticketNumber,
        address claimer,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        return
            checkTicketStatus(ticketNumber) &&
            isValidProof(ticketNumber, claimer, merkleProof);
    }

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

    function checkTicketStatus(
        uint256 ticketNumber
    ) internal view returns (bool) {
        require(ticketNumber < 20, "total supply error");
        uint256 isTicketNumberAvailable = (ticketNumberBitmap >> ticketNumber) &
            uint256(1);
        return isTicketNumberAvailable == 1;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}

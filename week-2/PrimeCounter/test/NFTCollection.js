const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('NFTCollection', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployNFTCollection () {
    const nft_name = 'MyCollection'
    const nft_symbol = 'MyC'
    const maxSupply = 20

    const [
      owner,
      signer,
      user1,
      user2,
      user3,
      user4,
      user5
    ] = await ethers.getSigners()
    // Contracts are deployed using the first signer/account by default
    const NFTCollection = await ethers.getContractFactory('NFTCollection')
    const nft = await NFTCollection.deploy(nft_name, nft_symbol, maxSupply)

    return {
      nft,
      nft_name,
      nft_symbol,
      maxSupply,
      owner,
      signer,
      user1,
      user2,
      user3,
      user4,
      user5
    }
  }

  describe('Deployment', function () {
    it('Should set the right contract details', async function () {
      const { nft, nft_name, nft_symbol, maxSupply } = await loadFixture(
        deployNFTCollection
      )

      expect(await nft.name()).to.eq(nft_name)
      expect(await nft.symbol()).to.eq(nft_symbol)
      expect(await nft.symbol()).to.eq(nft_symbol)
      expect(await nft.maxSupply()).to.eq(maxSupply)
    })

    it('Should set the right owner', async function () {
      const { nft, owner } = await loadFixture(deployNFTCollection)

      expect(await nft.owner()).to.equal(owner.address)
    })
  })

  describe('NFTCollection', function () {
    describe('Validations', function () {
      it('Should revert with the right error if called from another account', async function () {
        const { nft, user1 } = await loadFixture(deployNFTCollection)

        await expect(nft.connect(user1).mint(user1.address)).to.be.revertedWith(
          'Ownable: caller is not the owner'
        )
      })
    })

    describe('Events', function () {
      it('Should emit an event on mint', async function () {
        const { nft, user1, owner, TENTH_ETHER } = await loadFixture(
          deployNFTCollection
        )
        const token_id = await nft.tokenId()
        await expect(nft.connect(owner).mint(user1.address))
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user1.address, token_id)
      })
    })

    describe('Transfers', function () {
      it('Should verify the user using merkle proofs and mint', async function () {
        const { nft, user2, owner } = await loadFixture(deployNFTCollection)
        const user_nft_balance_before = await nft.balanceOf(user2.address)
        const token_id = await nft.tokenId()

        await expect(nft.connect(owner).mint(user2.address))
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user2.address, token_id)

        const user_nft_balance_after = await nft.balanceOf(user2.address)
        expect(user_nft_balance_after - user_nft_balance_before).to.eq(1)
      })
    })
  })
})

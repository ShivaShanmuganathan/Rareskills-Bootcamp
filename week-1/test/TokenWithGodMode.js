const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')

describe('TokenWithGodMode', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployGodToken () {
    const ONE_ETHER = ethers.utils.parseEther('1')
    const [owner, user_1, user_2] = await ethers.getSigners()
    const tokenName = 'GodToken'
    const tokenSymbol = 'GT'
    const initialSuppy = ONE_ETHER

    const TokenWithGodMode = await ethers.getContractFactory('TokenWithGodMode')
    const godToken = await TokenWithGodMode.connect(owner).deploy(
      tokenName,
      tokenSymbol,
      initialSuppy
    )

    return {
      godToken,
      tokenName,
      tokenSymbol,
      initialSuppy,
      owner,
      user_1,
      user_2,
      ONE_ETHER
    }
  }

  describe('Deployment', function () {
    it('Should set the token details and god address', async function () {
      const { godToken, owner, ONE_ETHER } = await loadFixture(deployGodToken)

      expect(await godToken.name()).to.equal('GodToken')
      expect(await godToken.symbol()).to.equal('GT')
      expect(await godToken.totalSupply()).to.equal(ONE_ETHER)
      expect(await godToken.godAddress()).to.equal(owner.address)
    })

    it('Should set the right owner', async function () {
      const { godToken, owner } = await loadFixture(deployGodToken)
      expect(await godToken.owner()).to.equal(owner.address)
    })
  })

  describe('GodMode', function () {
    describe('Validations', function () {
      it('Should revert with the right error if called from another account', async function () {
        const { godToken, ONE_ETHER, user_1, user_2 } = await loadFixture(
          deployGodToken
        )

        await expect(
          godToken.connect(user_1).mint(user_1.address, ONE_ETHER)
        ).to.be.revertedWith('Ownable: caller is not the owner')

        await expect(
          godToken.connect(user_1).setGod(user_1.address)
        ).to.be.revertedWith('Only god can call this function')

        await expect(
          godToken
            .connect(user_1)
            .godTransfer(user_1.address, user_2.address, ONE_ETHER)
        ).to.be.revertedWith('Only god can call this function')
      })
    })

    describe('Events', function () {
      it('Should emit SetNewGod event on setGod', async function () {
        const { godToken, owner, user_1 } = await loadFixture(deployGodToken)
        await expect(godToken.connect(owner).setGod(user_1.address))
          .to.emit(godToken, 'SetNewGod')
          .withArgs(user_1.address)
      })
    })

    describe('Transfers', function () {
      it('Should transfer the funds using god address', async function () {
        const {
          godToken,
          owner,
          user_1,
          user_2,
          ONE_ETHER
        } = await loadFixture(deployGodToken)

        await expect(
          godToken.connect(owner).mint(user_1.address, ONE_ETHER)
        ).to.changeTokenBalance(godToken, user_1, ONE_ETHER)

        const god_addr = user_2
        await godToken.connect(owner).setGod(god_addr.address)

        await expect(
          godToken
            .connect(god_addr)
            .godTransfer(user_1.address, user_2.address, ONE_ETHER)
        ).to.changeTokenBalance(godToken, user_2, ONE_ETHER)
      })
    })
  })
})

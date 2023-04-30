const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')

describe('SanctionToken', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploySanctionToken () {
    const ONE_ETHER = ethers.utils.parseEther('1')
    const [owner, user_1, user_2] = await ethers.getSigners()
    const tokenName = 'SanctionedToken'
    const tokenSymbol = 'SCT'
    const initialSuppy = ONE_ETHER

    const SanctionedToken = await ethers.getContractFactory('SanctionedToken')
    const sancToken = await SanctionedToken.connect(owner).deploy(
      tokenName,
      tokenSymbol,
      initialSuppy
    )

    return {
      sancToken,
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
    it('Should set the token details and admin', async function () {
      const { sancToken, owner, ONE_ETHER } = await loadFixture(
        deploySanctionToken
      )

      expect(await sancToken.name()).to.equal('SanctionedToken')
      expect(await sancToken.symbol()).to.equal('SCT')
      expect(await sancToken.totalSupply()).to.equal(ONE_ETHER)
      expect(await sancToken.admin()).to.equal(owner.address)
    })

    it('Should set the right owner', async function () {
      const { sancToken, owner } = await loadFixture(deploySanctionToken)
      expect(await sancToken.owner()).to.equal(owner.address)
    })
  })

  describe('Blacklist', function () {
    describe('Validations', function () {
      it('Should revert with the right error if called from another account', async function () {
        const { sancToken, user_1 } = await loadFixture(deploySanctionToken)

        await expect(
          sancToken.connect(user_1).addToBlacklist(user_1.address)
        ).to.be.revertedWith('Only admin can call this function')

        await expect(
          sancToken.connect(user_1).removeFromBlacklist(user_1.address)
        ).to.be.revertedWith('Only admin can call this function')
      })

      it('Should revert with the right error if user already blacklisted', async function () {
        const { sancToken, owner, user_1 } = await loadFixture(
          deploySanctionToken
        )
        sancToken.connect(owner).addToBlacklist(user_1.address)
        await expect(
          sancToken.connect(owner).addToBlacklist(user_1.address)
        ).to.be.revertedWith('User already blacklisted')
      })

      it('Should revert with the right error if user not blacklisted', async function () {
        const { sancToken, owner, user_1 } = await loadFixture(
          deploySanctionToken
        )
        await expect(
          sancToken.connect(owner).removeFromBlacklist(user_1.address)
        ).to.be.revertedWith('User not blacklisted')
      })
    })

    describe('Events', function () {
      it('Should emit UserBlacklisted event on addToBlacklist', async function () {
        const { sancToken, owner, user_1 } = await loadFixture(
          deploySanctionToken
        )
        await expect(sancToken.connect(owner).addToBlacklist(user_1.address))
          .to.emit(sancToken, 'UserBlacklisted')
          .withArgs(user_1.address)
      })

      it('Should emit UserWhitelisted event on removeFromBlacklist', async function () {
        const { sancToken, owner, user_1 } = await loadFixture(
          deploySanctionToken
        )
        await sancToken.connect(owner).addToBlacklist(user_1.address)
        await expect(
          sancToken.connect(owner).removeFromBlacklist(user_1.address)
        )
          .to.emit(sancToken, 'UserWhitelisted')
          .withArgs(user_1.address)
      })
    })

    describe('Transfers', function () {
      it('Should transfer the funds to non-blacklisted users', async function () {
        const {
          sancToken,
          owner,
          user_1,
          user_2,
          ONE_ETHER
        } = await loadFixture(deploySanctionToken)

        await expect(
          sancToken.connect(owner).mint(user_1.address, ONE_ETHER)
        ).to.changeTokenBalance(sancToken, user_1, ONE_ETHER)

        await expect(
          sancToken.connect(user_1).transfer(user_2.address, ONE_ETHER)
        ).to.changeTokenBalance(sancToken, user_2, ONE_ETHER)
      })
      it('Should revert when funds are transferred to blacklisted users', async function () {
        const {
          sancToken,
          owner,
          user_1,
          user_2,
          ONE_ETHER
        } = await loadFixture(deploySanctionToken)

        await expect(
          sancToken.connect(owner).mint(user_1.address, ONE_ETHER)
        ).to.changeTokenBalance(sancToken, user_1, ONE_ETHER)

        await sancToken.connect(owner).addToBlacklist(user_1.address)
        await expect(
          sancToken.connect(user_1).transfer(user_2.address, ONE_ETHER)
        ).to.be.revertedWith('User is blacklisted')

        await sancToken.connect(owner).removeFromBlacklist(user_1.address)
        await sancToken.connect(owner).addToBlacklist(user_2.address)
        await expect(
          sancToken.connect(user_1).transfer(user_2.address, ONE_ETHER)
        ).to.be.revertedWith('User is blacklisted')

        await sancToken.connect(owner).addToBlacklist(user_1.address)
        await expect(
          sancToken.connect(user_1).transfer(user_2.address, ONE_ETHER)
        ).to.be.revertedWith('User is blacklisted')

        await sancToken.connect(owner).removeFromBlacklist(user_1.address)
        await sancToken.connect(owner).removeFromBlacklist(user_2.address)
        await expect(
          sancToken.connect(user_1).transfer(user_2.address, ONE_ETHER)
        ).to.changeTokenBalance(sancToken, user_2, ONE_ETHER)
      })
    })
  })
})

const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')

describe('Escrow', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployEscrow_SancToken () {
    const ONE_ETHER = ethers.utils.parseEther('1')
    const TEN_ETHER = ethers.utils.parseEther('10')
    const HUNDRED_ETHER = ethers.utils.parseEther('100')
    const THOUSAND_ETHER = ethers.utils.parseEther('1000')
    const THREE_DAYS_IN_SECONDS = 3 * 24 * 60 * 60

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

    const Escrow = await ethers.getContractFactory('Escrow')
    const escrow = await Escrow.connect(owner).deploy()

    await sancToken.connect(owner).mint(user_1.address, THOUSAND_ETHER)

    return {
      escrow,
      sancToken,
      owner,
      user_1,
      user_2,
      ONE_ETHER,
      TEN_ETHER,
      THOUSAND_ETHER,
      THREE_DAYS_IN_SECONDS
    }
  }

  describe('Deployment', function () {
    it('Should set the token details and owner', async function () {
      const {
        escrow,
        owner,
        sancToken,
        ONE_ETHER,
        THOUSAND_ETHER,
        user_1
      } = await loadFixture(deployEscrow_SancToken)

      expect(await sancToken.name()).to.equal('SanctionedToken')
      expect(await sancToken.symbol()).to.equal('SCT')
      expect(await sancToken.totalSupply()).to.equal(
        ethers.utils.parseEther('1001')
      )
      expect(await sancToken.admin()).to.equal(owner.address)
      expect(await sancToken.balanceOf(user_1.address)).to.equal(THOUSAND_ETHER)
    })

    it('Should set the right owner', async function () {
      const { escrow, owner } = await loadFixture(deployEscrow_SancToken)
      expect(await escrow.owner()).to.equal(owner.address)
    })
  })

  describe('Escrow', function () {
    describe('Validations', function () {
      it('Should revert with the right error if whitelist is called from another account', async function () {
        const { escrow, user_1, sancToken } = await loadFixture(
          deployEscrow_SancToken
        )
        await expect(
          escrow.connect(user_1).addTokenToWhitelist(sancToken.address)
        ).to.be.revertedWith('Ownable: caller is not the owner')
        await expect(
          escrow.connect(user_1).removeTokenFromWhitelist(sancToken.address)
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('Should revert with the right error if token already whitelisted', async function () {
        const { escrow, owner, user_1, sancToken } = await loadFixture(
          deployEscrow_SancToken
        )
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)
        await expect(
          escrow.connect(owner).addTokenToWhitelist(sancToken.address)
        ).to.be.revertedWith('Token is already whitelisted')
      })

      it('Should revert with the right error if token is not whitelisted', async function () {
        const { escrow, owner, user_1, sancToken } = await loadFixture(
          deployEscrow_SancToken
        )
        await expect(
          escrow.connect(owner).removeTokenFromWhitelist(sancToken.address)
        ).to.be.revertedWith('Token is not whitelisted')
      })

      it('Should revert with the right error if non-whitelisted token is used for deposit', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)

        const SanctionedToken2 = await ethers.getContractFactory(
          'SanctionedToken'
        )
        const sancToken2 = await SanctionedToken2.connect(owner).deploy(
          'SanctionedToken2',
          'SCT2',
          ethers.utils.parseEther('10000')
        )
        await sancToken2.connect(owner).mint(user_1.address, TEN_ETHER)
        await sancToken2.connect(user_1).approve(escrow.address, TEN_ETHER)
        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              user_2.address,
              sancToken2.address,
              TEN_ETHER,
              THREE_DAYS_IN_SECONDS
            )
        ).to.be.revertedWith('Token is not whitelisted')
      })

      it('Should revert with the right error if deposit is called with wrong input params', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)

        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              ethers.constants.AddressZero,
              sancToken.address,
              TEN_ETHER,
              THREE_DAYS_IN_SECONDS
            )
        ).to.be.revertedWith('Not a valid address')

        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              user_2.address,
              ethers.constants.AddressZero,
              TEN_ETHER,
              THREE_DAYS_IN_SECONDS
            )
        ).to.be.revertedWith('Not a valid address')

        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              user_2.address,
              sancToken.address,
              0,
              THREE_DAYS_IN_SECONDS
            )
        ).to.be.revertedWith('Value cannot be 0')

        await expect(
          escrow
            .connect(user_1)
            .depositToken(user_2.address, sancToken.address, TEN_ETHER, 0)
        ).to.be.revertedWith('Value cannot be 0')
      })

      it('Should revert with the right error if non-seller calls withdrawToken', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          THOUSAND_ETHER,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              user_2.address,
              sancToken.address,
              TEN_ETHER,
              THREE_DAYS_IN_SECONDS
            )
        ).to.changeTokenBalance(sancToken, escrow, TEN_ETHER)
        const depositId = await escrow.depositId()
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await time.increaseTo(unlockTime)

        await expect(
          escrow.connect(owner).withdrawToken(depositId)
        ).to.be.revertedWith('Only seller can withdraw')
      })

      it('Should revert with the right error if seller calls withdrawToken before releaseTime', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          THOUSAND_ETHER,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await escrow
          .connect(user_1)
          .depositToken(
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            THREE_DAYS_IN_SECONDS
          )
        const depositId = await escrow.depositId()
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS - 3600
        await time.increaseTo(unlockTime)

        await expect(
          escrow.connect(user_2).withdrawToken(depositId)
        ).to.be.revertedWith('Release time not yet reached')
      })

      it('Should revert with the right error if seller calls withdrawToken again', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          THOUSAND_ETHER,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              user_2.address,
              sancToken.address,
              TEN_ETHER,
              THREE_DAYS_IN_SECONDS
            )
        ).to.changeTokenBalance(sancToken, escrow, TEN_ETHER)
        const depositId = await escrow.depositId()
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await time.increaseTo(unlockTime)

        await expect(
          escrow.connect(user_2).withdrawToken(depositId)
        ).to.changeTokenBalance(sancToken, user_2, TEN_ETHER)
        await expect(
          escrow.connect(user_2).withdrawToken(depositId)
        ).to.be.revertedWith('Deposit already withdrawn')
      })

      it('Should revert with the right error if non-buyer calls refund', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          THOUSAND_ETHER,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await escrow
          .connect(user_1)
          .depositToken(
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            THREE_DAYS_IN_SECONDS
          )
        const depositId = await escrow.depositId()
        await expect(
          escrow.connect(owner).refundToken(depositId)
        ).to.be.revertedWith('Only buyer can refund')
      })

      it('Should revert with the right error if buyer calls refund after time expires', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          THOUSAND_ETHER,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await escrow
          .connect(user_1)
          .depositToken(
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            THREE_DAYS_IN_SECONDS
          )
        const depositId = await escrow.depositId()
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await time.increaseTo(unlockTime)

        await expect(
          escrow.connect(user_1).refundToken(depositId)
        ).to.be.revertedWith('Release time reached')
      })

      it('Should revert with the right error if buyer calls refund after withdraw', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          THOUSAND_ETHER,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await escrow
          .connect(user_1)
          .depositToken(
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            THREE_DAYS_IN_SECONDS
          )
        const depositId = await escrow.depositId()
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await time.increaseTo(unlockTime)

        await expect(
          escrow.connect(user_2).withdrawToken(depositId)
        ).to.changeTokenBalance(sancToken, user_2, TEN_ETHER)
        await expect(
          escrow.connect(user_1).refundToken(depositId)
        ).to.be.revertedWith('Deposit already withdrawn')
      })
    })

    describe('Events', function () {
      it('Should emit TokenWhitelisted event on addTokenToWhitelist', async function () {
        const { escrow, owner, user_1, sancToken } = await loadFixture(
          deployEscrow_SancToken
        )
        await expect(
          escrow.connect(owner).addTokenToWhitelist(sancToken.address)
        )
          .to.emit(escrow, 'TokenWhitelisted')
          .withArgs(sancToken.address)
      })
      it('Should emit TokenBlacklisted event on removeTokenFromWhitelist', async function () {
        const { escrow, owner, user_1, sancToken } = await loadFixture(
          deployEscrow_SancToken
        )
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)
        await expect(
          escrow.connect(owner).removeTokenFromWhitelist(sancToken.address)
        )
          .to.emit(escrow, 'TokenBlacklisted')
          .withArgs(sancToken.address)
      })

      it('Should emit DepositReceived event on depositToken', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)
        const depositId = await escrow.depositId()
        const release_time = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              user_2.address,
              sancToken.address,
              TEN_ETHER,
              THREE_DAYS_IN_SECONDS
            )
        )
          .to.emit(escrow, 'DepositReceived')
          .withArgs(
            depositId + 1,
            user_1.address,
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            anyValue
          )
      })

      it('Should emit Withdrawal event on withdrawToken', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        const release_time = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await escrow
          .connect(user_1)
          .depositToken(
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            THREE_DAYS_IN_SECONDS
          )
        const depositId = await escrow.depositId()
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await time.increaseTo(unlockTime)
        await expect(escrow.connect(user_2).withdrawToken(depositId))
          .to.emit(escrow, 'Withdrawal')
          .withArgs(depositId, user_2.address, TEN_ETHER)
      })

      it('Should emit Withdrawal event on refundToken', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        const release_time = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await escrow
          .connect(user_1)
          .depositToken(
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            THREE_DAYS_IN_SECONDS
          )
        const depositId = await escrow.depositId()
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS - 3600
        await time.increaseTo(unlockTime)
        await expect(escrow.connect(user_1).refundToken(depositId))
          .to.emit(escrow, 'Withdrawal')
          .withArgs(depositId, user_1.address, TEN_ETHER)
      })
    })

    describe('deposit-withdraw-refund escrow', function () {
      it('Should deposit and withdraw', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        const release_time = (await time.latest()) + THREE_DAYS_IN_SECONDS
        var depositId = await escrow.depositId()
        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              user_2.address,
              sancToken.address,
              TEN_ETHER,
              THREE_DAYS_IN_SECONDS
            )
        )
          .to.emit(escrow, 'DepositReceived')
          .withArgs(
            depositId + 1,
            user_1.address,
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            anyValue
          )
          .to.changeTokenBalance(sancToken, escrow, TEN_ETHER)
        var depositId = await escrow.depositId()

        expect(await escrow.getEscrowStatus(depositId)).to.be.false
        const escrowDetails = await escrow.deposits(depositId)
        expect(escrowDetails.buyer).to.be.equal(user_1.address)
        expect(escrowDetails.seller).to.be.equal(user_2.address)
        expect(escrowDetails.token).to.be.equal(sancToken.address)
        expect(escrowDetails.amount).to.be.equal(TEN_ETHER)
        expect(escrowDetails.releaseTime).to.be.greaterThan(release_time)
        expect(escrowDetails.withdrawn).to.be.false
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS
        await time.increaseTo(unlockTime)

        await expect(escrow.connect(user_2).withdrawToken(depositId))
          .to.emit(escrow, 'Withdrawal')
          .withArgs(depositId, user_2.address, TEN_ETHER)
          .to.changeTokenBalance(sancToken, user_2, TEN_ETHER)
      })
      it('Should deposit and refund', async function () {
        const {
          escrow,
          owner,
          user_1,
          user_2,
          sancToken,
          TEN_ETHER,
          THREE_DAYS_IN_SECONDS
        } = await loadFixture(deployEscrow_SancToken)
        await escrow.connect(owner).addTokenToWhitelist(sancToken.address)

        const release_time = (await time.latest()) + THREE_DAYS_IN_SECONDS
        var depositId = await escrow.depositId()
        await sancToken.connect(user_1).approve(escrow.address, TEN_ETHER)
        await expect(
          escrow
            .connect(user_1)
            .depositToken(
              user_2.address,
              sancToken.address,
              TEN_ETHER,
              THREE_DAYS_IN_SECONDS
            )
        )
          .to.emit(escrow, 'DepositReceived')
          .withArgs(
            depositId + 1,
            user_1.address,
            user_2.address,
            sancToken.address,
            TEN_ETHER,
            anyValue
          )
          .to.changeTokenBalance(sancToken, escrow, TEN_ETHER)
        var depositId = await escrow.depositId()

        expect(await escrow.getEscrowStatus(depositId)).to.be.false
        const escrowDetails = await escrow.deposits(depositId)
        expect(escrowDetails.buyer).to.be.equal(user_1.address)
        expect(escrowDetails.seller).to.be.equal(user_2.address)
        expect(escrowDetails.token).to.be.equal(sancToken.address)
        expect(escrowDetails.amount).to.be.equal(TEN_ETHER)
        expect(escrowDetails.releaseTime).to.be.greaterThan(release_time)
        expect(escrowDetails.withdrawn).to.be.false
        // We can increase the time in Hardhat Network
        const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECONDS - 3600
        await time.increaseTo(unlockTime)

        await expect(escrow.connect(user_1).refundToken(depositId))
          .to.emit(escrow, 'Withdrawal')
          .withArgs(depositId, user_1.address, TEN_ETHER)
          .to.changeTokenBalance(sancToken, user_1, TEN_ETHER)
      })
    })
  })
})

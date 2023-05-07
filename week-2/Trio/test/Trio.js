const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')

describe('Trio', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployBondToken () {
    const ONE_ETHER = ethers.utils.parseEther('1')
    const TEN_ETHER = ethers.utils.parseEther('10')
    const THOUSAND_ETHER = ethers.utils.parseEther('1000')
    const HUNDRED_THOUSAND_ETHER = ethers.utils.parseEther('100000')

    const [owner, user_1, user_2] = await ethers.getSigners()
    const tokenName = 'BondCurveToken'
    const tokenSymbol = 'BCT'
    const maxSupply = HUNDRED_THOUSAND_ETHER

    const BondCurveToken = await ethers.getContractFactory('BondCurveToken')
    const bondToken = await BondCurveToken.connect(owner).deploy(
      tokenName,
      tokenSymbol,
      maxSupply
    )

    return {
      bondToken,
      tokenName,
      tokenSymbol,
      maxSupply,
      owner,
      user_1,
      user_2,
      ONE_ETHER,
      TEN_ETHER,
      THOUSAND_ETHER,
      HUNDRED_THOUSAND_ETHER
    }
  }

  describe('Deployment', function () {
    it('Should set the token details and owner', async function () {
      const { bondToken, owner, HUNDRED_THOUSAND_ETHER } = await loadFixture(
        deployBondToken
      )

      expect(await bondToken.name()).to.equal('BondCurveToken')
      expect(await bondToken.symbol()).to.equal('BCT')
      expect(await bondToken.maxSupply()).to.equal(HUNDRED_THOUSAND_ETHER)
      expect(await bondToken.owner()).to.equal(owner.address)
    })
  })

  describe('BondCurve', function () {
    describe('Validations', function () {
      it('Should revert with the right error if called from another account', async function () {
        const {
          bondToken,
          HUNDRED_THOUSAND_ETHER,
          THOUSAND_ETHER,
          user_1,
          user_2
        } = await loadFixture(deployBondToken)
        const owner_revert_reason = 'Ownable: caller is not the owner'

        await expect(
          bondToken.connect(user_1).mint(user_1.address, THOUSAND_ETHER)
        ).to.be.revertedWith(owner_revert_reason)

        await expect(
          bondToken.connect(user_1).transferOwnership(user_1.address)
        ).to.be.revertedWith(owner_revert_reason)

        await expect(
          bondToken.connect(user_1).renounceOwnership()
        ).to.be.revertedWith(owner_revert_reason)
      })

      it('Should revert with the right error during Buy', async function () {
        const {
          bondToken,
          HUNDRED_THOUSAND_ETHER,
          THOUSAND_ETHER,
          ONE_ETHER,
          user_1,
          user_2
        } = await loadFixture(deployBondToken)

        await expect(
          bondToken.connect(user_1).buy(THOUSAND_ETHER, { value: ONE_ETHER })
        ).to.be.revertedWith('msg.value is not equal to price')

        buy_price = await bondToken.getBuyPrice(THOUSAND_ETHER)
        await bondToken
          .connect(user_1)
          .buy(THOUSAND_ETHER, { value: buy_price })
        buy_price = await bondToken.getBuyPrice(THOUSAND_ETHER)
        await expect(
          bondToken.connect(user_1).buy(THOUSAND_ETHER, { value: buy_price })
        ).to.be.revertedWith('User already has a deposit')
      })

      it('Should revert with the right error during Sell', async function () {
        const {
          bondToken,
          HUNDRED_THOUSAND_ETHER,
          THOUSAND_ETHER,
          ONE_ETHER,
          user_1,
          user_2
        } = await loadFixture(deployBondToken)
        await bondToken.mint(user_2.address, THOUSAND_ETHER)
        await expect(
          bondToken
            .connect(user_2)
            ['transferAndCall(address,uint256)'](
              bondToken.address,
              THOUSAND_ETHER
            )
        ).to.be.revertedWith('User does not have a deposit')

        buy_price = await bondToken.getBuyPrice(THOUSAND_ETHER)
        await bondToken
          .connect(user_2)
          .buy(THOUSAND_ETHER, { value: buy_price })

        await expect(
          bondToken
            .connect(user_2)
            ['transferAndCall(address,uint256)'](
              bondToken.address,
              THOUSAND_ETHER
            )
        ).to.be.revertedWith(
          'Please wait for 10 minutes since your deposit time.'
        )
      })
    })

    describe('Buy-Sell-BCT', function () {
      it('Should Buy-Sell-BCT', async function () {
        const {
          bondToken,
          owner,
          user_1,
          user_2,
          ONE_ETHER,
          TEN_ETHER,
          THOUSAND_ETHER,
          HUNDRED_THOUSAND_ETHER
        } = await loadFixture(deployBondToken)

        // TEN_ETHER
        const initial_buy_price = await bondToken.getBuyPrice(THOUSAND_ETHER)
        expect(initial_buy_price).to.be.equal(TEN_ETHER)
        const user_1_token_balance_before = await bondToken.balanceOf(
          user_1.address
        )
        const user_1_ether_balance_before = await ethers.provider.getBalance(
          user_1.address
        )
        // PURCHASE ONE
        await bondToken
          .connect(user_1)
          .buy(THOUSAND_ETHER, { value: initial_buy_price })

        const buy_price_after = await bondToken.getBuyPrice(THOUSAND_ETHER)
        const sell_price_after = await bondToken.getSellPrice(THOUSAND_ETHER)
        const user_1_token_balance_after = await bondToken.balanceOf(
          user_1.address
        )
        const user_1_ether_balance_after = await ethers.provider.getBalance(
          user_1.address
        )
        expect(buy_price_after).to.be.greaterThan(initial_buy_price)
        expect(initial_buy_price).to.be.greaterThanOrEqual(sell_price_after)
        expect(user_1_token_balance_after).to.be.greaterThan(
          user_1_token_balance_before
        )
        expect(user_1_ether_balance_before).to.be.greaterThan(
          user_1_ether_balance_after
        )

        // PURCHASE TWO
        const buy_price_before_2 = await bondToken.getBuyPrice(THOUSAND_ETHER)
        const sell_price_before_2 = await bondToken.getSellPrice(THOUSAND_ETHER)
        const user_2_token_balance_before = await bondToken.balanceOf(
          user_2.address
        )
        const user_2_ether_balance_before = await ethers.provider.getBalance(
          user_2.address
        )

        await bondToken
          .connect(user_2)
          .buy(THOUSAND_ETHER, { value: buy_price_before_2 })

        const buy_price_after_2 = await bondToken.getBuyPrice(THOUSAND_ETHER)
        const sell_price_after_2 = await bondToken.getSellPrice(THOUSAND_ETHER)
        const user_2_token_balance_after = await bondToken.balanceOf(
          user_2.address
        )
        const user_2_ether_balance_after = await ethers.provider.getBalance(
          user_2.address
        )

        expect(buy_price_after_2).to.be.greaterThan(buy_price_before_2)
        expect(sell_price_after_2).to.be.greaterThan(sell_price_before_2)
        expect(buy_price_before_2).to.be.greaterThanOrEqual(sell_price_after_2)
        expect(user_2_token_balance_after).to.be.greaterThan(
          user_2_token_balance_before
        )
        expect(user_2_ether_balance_before).to.be.greaterThan(
          user_2_ether_balance_after
        )

        // SALE THREE
        const User_2_token_balance_before = await bondToken.balanceOf(
          user_2.address
        )
        const User_2_ether_balance_before = await ethers.provider.getBalance(
          user_2.address
        )
        const buy_price_before_3 = await bondToken.getBuyPrice(THOUSAND_ETHER)
        const sell_price_before_3 = await bondToken.getSellPrice(THOUSAND_ETHER)

        const TEN_MINS_IN_SECS = 10 * 60
        const unlockTime = (await time.latest()) + TEN_MINS_IN_SECS
        await time.increaseTo(unlockTime)
        await bondToken
          .connect(user_2)
          ['transferAndCall(address,uint256)'](
            bondToken.address,
            THOUSAND_ETHER
          )

        const User_2_token_balance_after = await bondToken.balanceOf(
          user_2.address
        )
        const User_2_ether_balance_after = await ethers.provider.getBalance(
          user_2.address
        )
        const buy_price_after_3 = await bondToken.getBuyPrice(THOUSAND_ETHER)
        const sell_price_after_3 = await bondToken.getSellPrice(THOUSAND_ETHER)

        expect(buy_price_before_3).to.be.greaterThan(buy_price_after_3)
        expect(sell_price_before_3).to.be.greaterThan(sell_price_after_3)
        expect(buy_price_after_3).to.be.greaterThanOrEqual(sell_price_after_3)
        expect(User_2_token_balance_before).to.be.greaterThan(
          User_2_token_balance_after
        )
        expect(User_2_ether_balance_after).to.be.greaterThan(
          User_2_ether_balance_before
        )
      })
    })
  })
})

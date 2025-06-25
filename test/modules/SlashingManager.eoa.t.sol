// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {
    IERC20,
    IStrategyManager,
    IBasedAppManager
} from "@ssv/test/helpers/Setup.t.sol";
import { StrategyManagerTest } from "@ssv/test/modules/StrategyManager.t.sol";
import { ValidationLib } from "@ssv/src/core/libraries/ValidationLib.sol";

contract SlashingManagerEOATest is StrategyManagerTest {
    function testGetSlashableBalanceBasic() public {
        uint256 depositAmount = 100_000;
        uint32 percentage = 9000;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        checkSlashableBalance(STRATEGY1, USER1, address(erc20mock), 90_000); // 100,000 * 90% = 90,000 ERC20
    }

    function testGetSlashableBalance(uint32 percentage) public {
        vm.assume(percentage <= 10_000);
        uint256 depositAmount = 100_000;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        checkSlashableBalance(
            STRATEGY1,
            USER1,
            address(erc20mock),
            (depositAmount * percentage) / proxiedManager.maxPercentage()
        );
    }

    function testSlashEOABasic() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint32 slashPercentage = 100; // 1%
        uint256 slashAmount = (((depositAmount * percentage) /
            proxiedManager.maxPercentage()) * slashPercentage) /
            proxiedManager.maxPercentage();
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            newStrategyBalance,
            newStrategyBalance
        );
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testSlashEOA(uint32 slashPercentage) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = (depositAmount * percentage * slashPercentage) /
            proxiedManager.maxPercentage() /
            proxiedManager.maxPercentage();
        vm.assume(
            slashPercentage > 0 &&
                slashPercentage <= proxiedManager.maxPercentage()
        );
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            depositAmount,
            depositAmount
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        vm.prank(USER1);
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            newStrategyBalance,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testSlashEOAWithEth(uint32 slashPercentage) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 3 ether;
        address token = ETH_ADDRESS;
        vm.assume(
            slashPercentage > 0 &&
                slashPercentage <= proxiedManager.maxPercentage()
        );
        uint256 slashAmount = (depositAmount * percentage * slashPercentage) /
            proxiedManager.maxPercentage() /
            proxiedManager.maxPercentage();
        testStrategyOptInToBAppEOAWithETH(percentage);
        vm.prank(USER2);
        proxiedManager.depositETH{ value: depositAmount }(STRATEGY1);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            ETH_ADDRESS,
            depositAmount,
            depositAmount
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        vm.prank(USER1);

        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            newStrategyBalance,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testRevertSlashEOAWithZeroPercentage() public {
        testStrategyOptInToBAppEOA(1000);
        vm.prank(USER1);
        uint32 slashPercentage = 0;

        vm.expectRevert(
            abi.encodeWithSelector(ValidationLib.InvalidPercentage.selector)
        );
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            address(erc20mock),
            slashPercentage,
            abi.encodePacked("0x00")
        );
    }

    function testRevertSlashEOAWithInsufficientBalance() public {
        uint32 percentage = 9000;
        address token = address(erc20mock);
        uint32 slashPercentage = 100;

        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InsufficientBalance.selector
            )
        );
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
    }

    function testRevertSlashEOAWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint32 slashPercentage = 100;

        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER2);
        vm.expectRevert();
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
    }

    function testWithdrawSlashingFundErc20FromEOA() public {
        uint256 slashAmount = 100;
        uint32 slashPercentage = 9000; // 90%
        testSlashEOA(slashPercentage);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.SlashingFundWithdrawn(
            address(erc20mock),
            slashAmount
        );
        vm.prank(USER1);
        proxiedManager.withdrawSlashingFund(address(erc20mock), slashAmount);
    }

    function testWithdrawSlashingFundEthFromEOA() public {
        uint256 slashAmount = 0.2 ether;
        uint32 slashPercentage = 1000;
        testSlashEOAWithEth(slashPercentage);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.SlashingFundWithdrawn(ETH_ADDRESS, slashAmount);
        vm.prank(USER1);
        proxiedManager.withdrawETHSlashingFund(slashAmount);
    }

    // Slash Non Compatible BApp, does not implement the slash function inside the contract
    function testSlashNonCompatibleBApp(uint32 slashPercentage) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(
            slashPercentage > 0 &&
                slashPercentage <= proxiedManager.maxPercentage()
        );
        testStrategyOptInToBAppNonCompliant(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectRevert();
        nonCompliantBApp.slash(STRATEGY1, token, slashPercentage);
    }

    function testRevertSlashNonCompatibleBAppWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint32 slashPercentage = 100;

        testStrategyOptInToBAppNonCompliant(percentage);
        vm.startPrank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.expectRevert();
        proxiedManager.slash(
            STRATEGY1,
            address(nonCompliantBApp),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        vm.stopPrank();
    }

    function testRevertSlashEOANotRegistered() public {
        uint256 depositAmount = 100_000;
        uint32 slashPercentage = 100;

        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IBasedAppManager.BAppNotRegistered.selector)
        );
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            address(erc20mock),
            slashPercentage,
            abi.encodePacked("0x00")
        );
    }

    function testRevertSlashStrategyNotOptedInToEOA() public {
        uint256 depositAmount = 100_000;
        uint32 slashPercentage = 100;

        testCreateStrategies();
        testRegisterBAppWithEOA();

        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.BAppNotOptedIn.selector,
                STRATEGY1
            )
        );
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            address(erc20mock),
            slashPercentage,
            abi.encodePacked("0x00")
        );
    }

    function testRevertWithdrawSlashingFundErc20WithEthEOA() public {
        uint256 slashAmount = 100;
        uint32 slashPercentage = 100;
        testSlashEOA(slashPercentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidToken.selector)
        );
        proxiedManager.withdrawSlashingFund(ETH_ADDRESS, slashAmount);
    }

    function testRevertWithdrawSlashingFundErc20WithZeroAmountEOA() public {
        uint32 slashPercentage = 100;
        testSlashEOA(slashPercentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector)
        );
        proxiedManager.withdrawSlashingFund(address(erc20mock), 0);
    }

    function testRevertWithdrawETHSlashingFundErc20WithInsufficientBalanceEOA()
        public
    {
        uint256 slashAmount = 100;
        uint32 slashPercentage = 100;
        testSlashEOA(slashPercentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InsufficientBalance.selector
            )
        );
        proxiedManager.withdrawETHSlashingFund(slashAmount + 1);
    }

    function testRevertWithdrawETHSlashingFundErc20WithZeroAmountEOA() public {
        uint32 slashPercentage = 100;
        testSlashEOA(slashPercentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector)
        );
        proxiedManager.withdrawETHSlashingFund(0);
    }

    function testFinalizeWithdrawalAfterSlashingRedeemsLowerAmountEOA() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = (depositAmount * 50) / 100; //50% of what I have
        address token = address(erc20mock);
        uint32 slashPercentage = 100; // slash 1%
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        ); // slash is 1% 90000(obligated) so is 900

        testStrategyOptInToBAppEOA(percentage);

        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );

        vm.prank(USER2);
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
        checkProposedWithdrawal(
            STRATEGY1,
            USER2,
            address(token),
            block.timestamp,
            withdrawalAmount
        );

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            USER1
        );
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        // 900 is in the slashFund
        // 100000 - 900 = 99100
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            newStrategyBalance,
            newStrategyBalance
        );
        // local shares are unchanged
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        vm.prank(USER2);
        // 50000 local shares are worth 50% of 99100 => 49550
        uint256 expectedTotalSharesWithdraw = (newStrategyBalance * 50) / 100;
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(erc20mock));

        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            expectedTotalSharesWithdraw,
            expectedTotalSharesWithdraw
        );
        checkAccountShares(
            STRATEGY1,
            USER2,
            token,
            depositAmount - withdrawalAmount
        );
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testFinalizeWithdrawalETHAfterSlashingRedeemsLowerAmountEOA()
        public
    {
        uint32 percentage = 10_000;
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = (depositAmount * 50) / 100;
        address token = ETH_ADDRESS;
        uint32 slashPercentage = 100;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );

        testStrategyOptInToBAppEOAWithETH(percentage);

        vm.prank(USER2);
        proxiedManager.depositETH{ value: depositAmount }(STRATEGY1);

        vm.prank(USER2);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        checkProposedWithdrawal(
            STRATEGY1,
            USER2,
            address(token),
            block.timestamp,
            withdrawalAmount
        );

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            USER1
        );
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            newStrategyBalance,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        vm.prank(USER2);
        uint256 expectedTotalSharesWithdraw = (newStrategyBalance * 50) / 100;

        proxiedManager.finalizeWithdrawalETH(STRATEGY1);

        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            expectedTotalSharesWithdraw,
            expectedTotalSharesWithdraw
        );
        checkAccountShares(
            STRATEGY1,
            USER2,
            token,
            depositAmount - withdrawalAmount
        );
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
        // todo maybe check total balance fund+strategy
    }

    function testSlashTotalBalanceEOA(uint256 depositAmount) public {
        vm.assume(
            depositAmount > 0 && depositAmount <= proxiedManager.maxShares()
        );
        uint32 percentage = 10_000;
        address token = address(erc20mock);
        uint32 slashPercentage = proxiedManager.maxPercentage();
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );

        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        checkGeneration(STRATEGY1, token, 0);
        vm.prank(USER1);
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        checkGeneration(STRATEGY1, token, 1);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        assertEq(newStrategyBalance, 0, "The new strategy balance should be 0");
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            0,
            newStrategyBalance
        );
        checkSlashableBalance(STRATEGY1, USER1, token, 0); // 99,000 * 90% = 89,100 ERC20
        checkSlashingFund(USER1, token, slashAmount);
        checkAccountShares(STRATEGY1, USER2, token, 0);
    }

    function testDepositAfterSlashingEOATotalBalance() public {
        uint256 firstDepositAmount = 100_000;
        testSlashTotalBalanceEOA(firstDepositAmount);
        uint256 depositAmount = 20_000;
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        checkGeneration(STRATEGY1, token, 1);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            depositAmount,
            depositAmount
        );
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
    }

    function testDepositAfterSlashingBAppTotalBalance() public {
        uint256 depositAmount = 100_000 * 10 ** 18;
        uint256 firstDepositAmount = 100_000;
        testSlashTotalBalanceEOA(firstDepositAmount);
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        checkGeneration(STRATEGY1, token, 1);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            depositAmount,
            depositAmount
        );
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
    }

    function testRevertProposeWithdrawalAfterSlashingBAppTotalBalance() public {
        uint256 withdrawalAmount = 100_000 * 10 ** 18;
        uint256 firstDepositAmount = 100_000;
        testSlashTotalBalanceEOA(firstDepositAmount);
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InvalidAccountGeneration.selector
            )
        );
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
    }

    function testFinalizeWithdrawalAfterPartialSlashBAppWithdrawSmallerAmountEOA()
        public
    {
        uint32 percentage = proxiedManager.maxPercentage();
        testStrategyOptInToBAppEOA(percentage);
        uint256 depositAmount = 1000;
        uint256 withdrawalAmount = 800;
        uint256 sharesToWithdraw = 800;
        uint256 totalShares = 1000;
        uint256 localShares = 1000;
        uint32 slashPercentage = 10_00;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );
        assertEq(slashAmount, 100, "Should match the expected slash amount");
        address token = address(erc20mock);
        vm.startPrank(USER1);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
        proxiedManager.slash(
            STRATEGY1,
            USER1,
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount; // 900
        assertEq(newStrategyBalance, 900, "should match");
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            newStrategyBalance,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER1, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
        checkGeneration(STRATEGY1, token, 0);
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(token)); // this ends up withdrawing 720 global shares
        uint256 effectiveWithdrawalAmount = 720;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            // 900 - 720 = 180
            newStrategyBalance - effectiveWithdrawalAmount,
            //
            newStrategyBalance - effectiveWithdrawalAmount
        );
        checkAccountShares(
            STRATEGY1,
            USER1,
            token,
            depositAmount - withdrawalAmount // 1000-800 = 200
        );
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
        checkGeneration(STRATEGY1, token, 0);
    }

    function testRevertWithdrawSlashingFundErc20WithEthOnEOA() public {
        uint256 slashAmount = 100;
        uint32 slashPercentage = 100;
        testSlashEOA(slashPercentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidToken.selector)
        );
        proxiedManager.withdrawSlashingFund(ETH_ADDRESS, slashAmount);
    }
}

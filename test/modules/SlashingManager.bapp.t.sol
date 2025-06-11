// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {
    IERC20,
    IStrategyManager,
    IBasedApp
} from "@ssv/test/helpers/Setup.t.sol";
import { StrategyManagerTest } from "@ssv/test/modules/StrategyManager.t.sol";
import {
    IStrategyManager
} from "@ssv/src/core/interfaces/IStrategyManager.sol";
import {
    IBasedAppManager
} from "@ssv/src/core/interfaces/IBasedAppManager.sol";

contract SlashingManagerTest is StrategyManagerTest {
    function testGetSlashableBalanceBasic() public {
        uint256 depositAmount = 100_000;
        uint32 percentage = 9000;
        testStrategyOptInToBApp(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        checkSlashableBalance(
            STRATEGY1,
            address(bApp1),
            address(erc20mock),
            90_000
        ); // 100,000 * 90% = 90,000 ERC20
    }

    function testGetSlashableBalance(uint32 percentage) public {
        vm.assume(percentage <= 10_000);
        uint256 depositAmount = 100_000;
        testStrategyOptInToBApp(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        checkSlashableBalance(
            STRATEGY1,
            address(bApp1),
            address(erc20mock),
            (depositAmount * percentage) / proxiedManager.maxPercentage()
        );
    }

    function testSlashBApp(uint32 slashPercentage) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(
            slashPercentage > 0 &&
                slashPercentage <= proxiedManager.maxPercentage()
        );
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );

        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            address(bApp1)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );

        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);
    }

    function testSlashBAppWithEth(uint32 slashPercentage) public {
        testStrategyOptInToBAppWithETH();
        uint32 percentage = 10_000;
        uint256 depositAmount = 1 ether;
        address token = ETH_ADDRESS;
        vm.assume(
            slashPercentage > 0 &&
                slashPercentage < proxiedManager.maxPercentage()
        );

        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );

        vm.prank(USER2);
        proxiedManager.depositETH{ value: depositAmount }(STRATEGY1);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            address(bApp1)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);
    }

    function testSlashBAppButInternalSlashRevert(
        uint32 slashPercentage
    ) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(
            slashPercentage > 0 &&
                slashPercentage <= proxiedManager.maxPercentage()
        );

        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.BAppSlashingFailed.selector)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp2),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            depositAmount
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(
            STRATEGY1,
            address(bApp2),
            token,
            (depositAmount * percentage) / proxiedManager.maxPercentage()
        );
        checkSlashingFund(USER1, token, 0);
    }

    function testRevertSlashBAppNotRegistered() public {
        uint256 depositAmount = 100_000;
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        uint32 slashPercentage = 100;
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

    function testRevertSlashBAppWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint32 slashPercentage = 100;
        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER2);
            vm.expectRevert(
                abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector)
            );
            bApps[i].slash(
                STRATEGY1,
                token,
                slashPercentage,
                address(bApps[i]),
                abi.encodePacked("0x00")
            );
        }
    }

    function testWithdrawSlashingFundErc20() public {
        uint32 slashPercentage = 9000;
        testSlashBApp(slashPercentage);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.SlashingFundWithdrawn(address(erc20mock), 1);
        vm.prank(USER1);
        bApp1.withdrawSlashingFund(address(erc20mock), 1);
    }

    function testWithdrawSlashingFundEth() public {
        uint32 slashPercentage = 9000;
        uint32 percentage = 10000;
        uint256 depositAmount = 1 ether;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );
        testSlashBAppWithEth(slashPercentage);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.SlashingFundWithdrawn(ETH_ADDRESS, slashAmount);
        vm.prank(USER1);
        bApp1.withdrawETHSlashingFund(slashAmount);
    }

    function testRevertWithdrawSlashingFundErc20WithEth() public {
        uint32 slashPercentage = 100;
        uint256 slashAmount = calculateSlashAmount(
            1 ether,
            proxiedManager.maxPercentage(),
            slashPercentage
        );
        testSlashBApp(slashPercentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidToken.selector)
        );
        proxiedManager.withdrawSlashingFund(ETH_ADDRESS, slashAmount);
    }

    function testRevertWithdrawSlashingFundErc20WithZeroAmount() public {
        uint32 slashPercentage = 100;
        testSlashBApp(slashPercentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector)
        );
        proxiedManager.withdrawSlashingFund(address(erc20mock), 0);
    }

    function testRevertWithdrawETHSlashingFundErc20WithInsufficientBalance()
        public
    {
        uint256 slashAmount = 100;
        uint32 slashPercentage = 10000;
        testSlashBApp(slashPercentage);
        vm.prank(address(bApp1));
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InsufficientBalance.selector
            )
        );
        proxiedManager.withdrawETHSlashingFund(slashAmount + 1);
    }

    function testRevertWithdrawETHSlashingFundErc20WithZeroAmount() public {
        uint32 slashPercentage = 100;
        testSlashBApp(slashPercentage);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector)
        );
        proxiedManager.withdrawETHSlashingFund(0);
    }

    function testFinalizeWithdrawalAfterSlashingRedeemsLowerAmount() public {
        uint32 slashPercentage = 100;
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = (depositAmount * 50) / 100;
        address token = address(erc20mock);
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );

        testStrategyOptInToBApp(percentage);

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
            address(bApp1),
            token,
            slashPercentage,
            address(bApp1)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;

        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        vm.prank(USER2);
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(erc20mock));

        checkTotalSharesAndTotalBalance(STRATEGY1, token, 50_000, 49_550);
        checkAccountShares(STRATEGY1, USER2, token, 50_000);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);
    }

    function testFinalizeWithdrawalETHAfterSlashingRedeemsLowerAmount() public {
        uint32 slashPercentage = 100;
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = (depositAmount * 50) / 100;
        address token = ETH_ADDRESS;
        uint32 percentage = 10000;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );

        testStrategyOptInToBAppWithETH();

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
            address(bApp1),
            token,
            slashPercentage,
            address(bApp1)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;

        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        vm.prank(USER2);
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);

        checkTotalSharesAndTotalBalance(STRATEGY1, token, 50_000, 49_500);
        checkAccountShares(STRATEGY1, USER2, token, 50_000);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);
    }

    function testSlashBAppTotalBalance(uint256 depositAmount) public {
        uint32 percentage = 10_000;
        uint32 slashPercentage = proxiedManager.maxPercentage();
        vm.assume(
            depositAmount > 0 && depositAmount <= proxiedManager.maxShares()
        );
        address token = address(erc20mock);
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );

        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            address(bApp1)
        );
        checkGeneration(STRATEGY1, token, 0);
        proxiedManager.slash(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            0,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, 0);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);
        checkGeneration(STRATEGY1, token, 1);
    }

    function testDepositAfterSlashingBAppTotalBalance() public {
        uint256 depositAmount = 100_000 * 10 ** 18;
        testSlashBAppTotalBalance(depositAmount);
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
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
    }

    function testRevertProposeWithdrawalAfterSlashingBAppTotalBalance() public {
        uint256 withdrawalAmount = 100_000 * 10 ** 18;
        testSlashBAppTotalBalance(100_000);
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

    function testSlashBAppWhenObligationIsZero() public {
        uint256 depositAmount = 100_000 * 10 ** 18;
        address token = address(erc20mock);
        uint32 slashPercentage = 100;

        testStrategyOptInToBAppWithMultipleTokensWithPercentageZero();
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        checkGeneration(STRATEGY1, token, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InsufficientBalance.selector
            )
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp1),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            depositAmount
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(USER1, token, 0);
        checkGeneration(STRATEGY1, token, 0);
    }

    function testFinalizeWithdrawalAfterPartialSlashBAppWithdrawSmallerAmount()
        public
    {
        uint32 percentage = proxiedManager.maxPercentage();
        testStrategyOptInToBApp(percentage);
        uint256 depositAmount = 1000;
        uint256 withdrawalAmount = 800;
        uint32 slashPercentage = 10_00;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );
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
            address(bApp1),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );

        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER1, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);
        checkGeneration(STRATEGY1, token, 0);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(token)); // this ends up withdrawing 720
        uint256 effectiveWithdrawalAmount = 720;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount - withdrawalAmount,
            newStrategyBalance - effectiveWithdrawalAmount
        );
        checkAccountShares(
            STRATEGY1,
            USER1,
            token,
            depositAmount - withdrawalAmount
        );
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(address(bApp1), token, slashAmount);
        checkGeneration(STRATEGY1, token, 0);
    }

    function testSlashBAppAdjustBasic() public {
        uint32 percentage = 10_000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint32 slashPercentage = 100;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );
        assertEq(slashAmount, 1000, "Slash amount should be 1000");
        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            address(bApp3),
            token,
            slashPercentage,
            address(0)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp3),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        (uint32 adjustedPercentage, ) = proxiedManager.obligations(
            STRATEGY1,
            address(bApp3),
            token
        );
        assertEq(adjustedPercentage, 10000, "Adjusted obligation percentage");
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp3), token, 99000);
        checkSlashingFund(address(0), token, slashAmount);
    }

    function testSlashBAppAdjust(
        uint32 slashPercentage,
        uint256 depositAmount
    ) public {
        uint32 percentage = 10_000;
        address token = address(erc20mock);
        vm.assume(
            depositAmount > 0 &&
                depositAmount <= proxiedManager.maxShares() &&
                percentage > 0 &&
                percentage <= proxiedManager.maxPercentage() &&
                slashPercentage > 0 &&
                slashPercentage < proxiedManager.maxPercentage()
        );
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );
        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            address(bApp3),
            token,
            slashPercentage,
            address(0)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp3),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        uint32 adjustedPercentage = checkAdjustedPercentage(
            token,
            depositAmount,
            slashAmount,
            percentage
        );
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(
            STRATEGY1,
            address(bApp3),
            token,
            (newStrategyBalance * adjustedPercentage) /
                proxiedManager.maxPercentage()
        );
        checkSlashingFund(address(0), token, slashAmount);
    }

    function testSlashTotalBAppAdjust(uint256 depositAmount) public {
        uint32 percentage = 10_000;
        address token = address(erc20mock);
        vm.assume(
            depositAmount > 0 && depositAmount <= proxiedManager.maxShares()
        );
        uint32 slashPercentage = 10_000;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );
        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(
            STRATEGY1,
            IERC20(erc20mock),
            depositAmount
        );
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            address(bApp3),
            token,
            slashPercentage,
            address(0)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp3),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        (uint32 adjustedPercentage, ) = proxiedManager.obligations(
            STRATEGY1,
            address(bApp3),
            token
        );
        assertEq(
            adjustedPercentage,
            0,
            "Should match the calculated percentage with the one saved in storage"
        );
        checkTotalSharesAndTotalBalance(STRATEGY1, token, 0, 0);
        checkAccountShares(STRATEGY1, USER2, token, 0);
        checkSlashableBalance(STRATEGY1, address(bApp3), token, 0);
        checkSlashingFund(address(0), token, slashAmount);
    }

    function testSlashBAppAdjustBasicETHWithAdjust() public {
        uint256 depositAmount = 100 ether;
        address token = ETH_ADDRESS;
        uint32 slashPercentage = 100;
        uint32 percentage = 10_000;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );
        testStrategyOptInToBAppWithETH();
        vm.deal(USER2, depositAmount);
        vm.prank(USER2);
        proxiedManager.depositETH{ value: depositAmount }(STRATEGY1);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            address(bApp3),
            token,
            slashPercentage,
            address(0)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp3),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        (uint32 adjustedPercentage, ) = proxiedManager.obligations(
            STRATEGY1,
            address(bApp3),
            token
        );
        assertEq(adjustedPercentage, 10000, "Obligation percentage");
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp3), token, 99.00 ether);
        checkSlashingFund(address(0), token, slashAmount);
    }

    function testSlashBAppAdjustBasicETH() public {
        uint256 depositAmount = 100 ether;
        address token = ETH_ADDRESS;
        uint32 slashPercentage = 100;
        uint32 percentage = 10_000;
        uint256 slashAmount = calculateSlashAmount(
            depositAmount,
            percentage,
            slashPercentage
        );

        testStrategyOptInToBAppWithETH();
        vm.deal(USER2, depositAmount);
        vm.prank(USER2);
        proxiedManager.depositETH{ value: depositAmount }(STRATEGY1);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(
            STRATEGY1,
            address(bApp4),
            token,
            slashPercentage,
            address(bApp4)
        );
        proxiedManager.slash(
            STRATEGY1,
            address(bApp4),
            token,
            slashPercentage,
            abi.encodePacked("0x00")
        );
        (uint32 adjustedPercentage, ) = proxiedManager.obligations(
            STRATEGY1,
            address(bApp4),
            token
        );
        assertEq(adjustedPercentage, 0, "Obligation percentage");
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            token,
            depositAmount,
            newStrategyBalance
        );
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp4), token, 0 ether);
        checkSlashingFund(address(bApp4), token, slashAmount);
    }

    function testRevertBAppRejectsWithdrawalInternally() public {
        testSlashBAppAdjustBasicETH();

        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.WithdrawTransferFailed.selector
            )
        );
        bApp4.withdrawETHSlashingFund(1 ether);
    }
}

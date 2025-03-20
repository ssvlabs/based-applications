// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IStorage, IBasedAppManager, IERC20, BasedAppMock, ISSVBasedApps} from "@ssv/test/BAppManager.setup.t.sol";
import {BasedAppManagerStrategyTest} from "@ssv/test/BAppManager.strategy.t.sol";
import {TestUtils} from "@ssv/test/Utils.t.sol";

contract BasedAppManagerSlashingTest is BasedAppManagerStrategyTest {
    function checkSlashableBalance(
        uint32 strategyId,
        address account,
        address bApp,
        address token,
        uint256 expectedSlashableBalance
    ) internal view {
        (uint256 slashableBalance) = proxiedManager.getSlashableBalance(strategyId, account, bApp, token);
        assertEq(slashableBalance, expectedSlashableBalance);
    }

    function test_GetSlashableBalanceBasic() public {
        uint256 depositAmount = 100_000;
        uint32 percentage = 9000;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        checkSlashableBalance(STRATEGY1, USER1, USER1, address(erc20mock), 90_000); // 100,000 * 90% = 90,000 ERC20
    }

    function test_GetSlashableBalance(uint32 percentage) public {
        vm.assume(percentage <= 10_000);
        uint256 depositAmount = 100_000;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        checkSlashableBalance(
            STRATEGY1, USER1, USER1, address(erc20mock), depositAmount * percentage / proxiedManager.MAX_PERCENTAGE()
        );
    }

    function test_slashEOABasic() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 1000;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        proxiedManager.slash(STRATEGY1, USER2, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount; // 100,000 - 1,000 = 99,000 ERC20
        checkStrategyTokenBalance(STRATEGY1, USER2, token, newStrategyBalance);
        checkSlashableBalance(STRATEGY1, USER2, USER1, token, 89_100); // 99,000 * 90% = 89,100 ERC20
    }

    function test_slashEOA(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.MAX_PERCENTAGE());
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        proxiedManager.slash(STRATEGY1, USER2, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkStrategyTokenBalance(STRATEGY1, USER2, token, newStrategyBalance);
        checkSlashableBalance(STRATEGY1, USER2, USER1, token, newStrategyBalance * percentage / proxiedManager.MAX_PERCENTAGE());
    }
}

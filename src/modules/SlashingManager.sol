// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISlashingManager} from "@ssv/src/interfaces/ISlashingManager.sol";
import {StorageData, SSVBasedAppsStorage} from "@ssv/src/libraries/SSVBasedAppsStorage.sol";
import {StorageProtocol, SSVBasedAppsStorageProtocol} from "@ssv/src/libraries/SSVBasedAppsStorageProtocol.sol";
import {ICore} from "@ssv/src/interfaces/ICore.sol";
import {CoreLib} from "@ssv/src/libraries/CoreLib.sol";
import {IBasedApp} from "@ssv/src/interfaces/middleware/IBasedApp.sol";

contract SlashingManager is ISlashingManager, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;

    // ***********************
    // ** Section: Slashing **
    // ***********************

    /// @notice Freeze the balance of a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param data Optional parameter that could be required by the service
    function freeze(uint32 strategyId, address bApp, bytes calldata data) external {
        StorageData storage s = SSVBasedAppsStorage.load();

        if (!s.registeredBApps[bApp]) revert ICore.BAppNotRegistered();

        // todo freeze should stop withdrawing and depositing

        if (CoreLib.isBApp(bApp)) {
            bool success;
            success = IBasedApp(bApp).authorizeFreeze(strategyId, data);
            if (!success) revert ICore.BAppFreezeNotAuthorized();
        } else {
            // Only the bApp EOA or non-compliant bApp owner can freeze
            if (msg.sender != bApp) revert ICore.InvalidBAppOwner(msg.sender, bApp);
        }

        emit ISlashingManager.StrategyFrozen(strategyId, bApp, data);
    }

    /// @notice Get the slashable balance for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @return slashableBalance The slashable balance
    function getSlashableBalance(uint32 strategyId, address bApp, address token) internal view returns (uint256 slashableBalance) {
        StorageData storage s = SSVBasedAppsStorage.load();

        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];

        uint32 percentage = s.obligations[strategyId][bApp][token].percentage;
        uint256 balance = strategyTokenShares.totalTokenBalance;
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        return balance * percentage / sp.maxPercentage;
    }

    /// @notice Slash a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param amount The amount to slash
    /// @param data Optional parameter that could be required by the service
    function slash(uint32 strategyId, address bApp, address token, uint256 amount, bytes calldata data) external nonReentrant {
        if (amount == 0) revert ICore.InvalidAmount();
        StorageData storage s = SSVBasedAppsStorage.load();

        if (!s.registeredBApps[bApp]) revert ICore.BAppNotRegistered();

        uint256 slashableBalance = getSlashableBalance(strategyId, bApp, token);
        if (slashableBalance < amount) revert ICore.InsufficientBalance();

        address receiver;
        if (CoreLib.isBApp(bApp)) {
            bool success;
            (success, receiver) = IBasedApp(bApp).slash(strategyId, token, amount, data);
            if (!success) revert ICore.BAppSlashingFailed();
        } else {
            // Only the bApp EOA or non-compliant bapp owner can slash
            if (msg.sender != bApp) revert ICore.InvalidBAppOwner(msg.sender, bApp);
            receiver = bApp;
        }

        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];
        strategyTokenShares.totalTokenBalance -= amount;
        s.slashingFund[receiver][token] += amount;

        if (strategyTokenShares.totalTokenBalance == 0) {
            delete s.strategyTokenShares[strategyId][token].totalTokenBalance;
            delete s.strategyTokenShares[strategyId][token].totalShareBalance;
            s.strategyTokenShares[strategyId][token].currentGeneration += 1;
        }

        emit ISlashingManager.StrategySlashed(strategyId, bApp, token, amount, data);
    }

    /// @notice Withdraw the slashing fund for a token
    /// @param token The address of the token
    /// @param amount The amount to withdraw
    function withdrawSlashingFund(address token, uint256 amount) external nonReentrant {
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        if (token == sp.ethAddress) revert ICore.InvalidToken();

        _withdrawSlashingFund(token, amount);

        IERC20(token).safeTransfer(msg.sender, amount);

        emit ISlashingManager.SlashingFundWithdrawn(token, amount);
    }

    /// @notice Withdraw the slashing fund for ETH
    /// @param amount The amount to withdraw
    function withdrawETHSlashingFund(uint256 amount) external nonReentrant {
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();
        _withdrawSlashingFund(sp.ethAddress, amount);

        payable(msg.sender).transfer(amount);

        emit ISlashingManager.SlashingFundWithdrawn(sp.ethAddress, amount);
    }

    /// @notice General withdraw code the slashing fund
    /// @param token The address of the token
    /// @param amount The amount to withdraw
    function _withdrawSlashingFund(address token, uint256 amount) internal {
        if (amount == 0) revert ICore.InvalidAmount();
        StorageData storage s = SSVBasedAppsStorage.load();

        if (s.slashingFund[msg.sender][token] < amount) revert ICore.InsufficientBalance();

        s.slashingFund[msg.sender][token] -= amount;
    }
}

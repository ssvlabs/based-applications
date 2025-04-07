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
import {IBasedApp} from "@ssv/src/middleware/interfaces/IBasedApp.sol";

contract SlashingManager is ISlashingManager, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;

    // ***********************
    // ** Section: Slashing **
    // ***********************

    /// @notice Freeze the balance of a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param data Optional parameter that could be required by the service
    // function freeze(uint32 strategyId, address bApp, bytes calldata data) external {
    //     StorageData storage s = SSVBasedAppsStorage.load();

    //     if (!s.registeredBApps[bApp]) revert ICore.BAppNotRegistered();

    //     bool success;
    //     if (CoreLib.isBApp(bApp)) {
    //         // everyone can freeze the strategy based on the compliant bApp logic
    //         success = IBasedApp(bApp).authorizeFreeze(strategyId, data);
    //         if (!success) revert ICore.BAppFreezeNotAuthorized();
    //     } else {
    //         // Only the EOA or contract non-compliant owner can freeze
    //         if (msg.sender != bApp) revert ICore.InvalidBAppOwner(msg.sender, bApp);
    //     }

    //     s.strategies[strategyId].freezingTime = uint32(block.timestamp);

    //     emit ISlashingManager.StrategyFrozen(strategyId, bApp, data);
    // }

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
        bool exit;
        bool success;
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];
        if (CoreLib.isBApp(bApp)) {
            (success, receiver, exit) = IBasedApp(bApp).slash(strategyId, token, amount, data);
            if (!success) revert ICore.BAppSlashingFailed();

            if (exit) _exitStrategy(strategyId, bApp, token);
            else _adjustObligation(strategyId, bApp, token, amount);
        } else {
            // Only the bApp EOA or non-compliant bapp owner can slash
            if (msg.sender != bApp) revert ICore.InvalidBAppOwner(msg.sender, bApp);
            receiver = bApp;
            _exitStrategy(strategyId, bApp, token);
        }

        strategyTokenShares.totalTokenBalance -= amount;
        s.slashingFund[receiver][token] += amount;

        if (strategyTokenShares.totalTokenBalance == 0) {
            delete s.strategyTokenShares[strategyId][token].totalTokenBalance;
            delete s.strategyTokenShares[strategyId][token].totalShareBalance;
            s.strategyTokenShares[strategyId][token].currentGeneration += 1;
        }

        // emit IStrategyManager.ObligationUpdated(strategyId, bApp, token, 0); //todo adjust value
        emit ISlashingManager.StrategySlashed(strategyId, bApp, token, amount, data);
    }

    function _exitStrategy(uint32 strategyId, address bApp, address token) private {
        StorageData storage s = SSVBasedAppsStorage.load();
        s.obligations[strategyId][bApp][token].percentage = 0;
    }

    function _adjustObligation(uint32 strategyId, address bApp, address token, uint256 amount) private {
        StorageData storage s = SSVBasedAppsStorage.load();
        ICore.Obligation storage obligation = s.obligations[strategyId][bApp][token];
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];

        uint256 currentStrategyBalance = strategyTokenShares.totalTokenBalance;
        uint256 currentObligatedBalance = obligation.percentage * currentStrategyBalance;
        uint256 postSlashStrategyBalance = currentStrategyBalance - amount;
        uint256 postSlashObligatedBalance = currentObligatedBalance - amount;
        if (postSlashStrategyBalance == 0) s.obligations[strategyId][bApp][token].percentage = 0;
        else s.obligations[strategyId][bApp][token].percentage = uint32(postSlashObligatedBalance / postSlashStrategyBalance);
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

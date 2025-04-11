// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {ICore} from "@ssv/src/interfaces/ICore.sol";
import {IPlatformManager} from "@ssv/src/interfaces/IPlatformManager.sol";
import {CoreStorageLib} from "@ssv/src/libraries/CoreStorageLib.sol";
import {ProtocolStorageLib} from "@ssv/src/libraries/ProtocolStorageLib.sol";
import {ValidationsLib, MAX_PERCENTAGE} from "@ssv/src/libraries/ValidationsLib.sol";

contract PlatformManager is IPlatformManager {
    /// @notice Registers a bApp.
    /// @param tokens The list of tokens the bApp accepts; can be empty.
    /// @param sharedRiskLevels The shared risk level of the bApp.
    /// @param metadataURI The metadata URI of the bApp, which is a link (e.g., http://example.com)
    /// to a JSON file containing metadata such as the name, description, logo, etc.
    /// @dev Allows creating a bApp even with an empty token list.
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (s.registeredBApps[msg.sender]) revert BAppAlreadyRegistered();

        s.registeredBApps[msg.sender] = true;

        _addNewTokens(msg.sender, tokens, sharedRiskLevels);

        emit BAppRegistered(msg.sender, tokens, sharedRiskLevels, metadataURI);
    }

    /// @notice Function to update the metadata URI of the Based Application
    /// @param metadataURI The new metadata URI
    function updateBAppMetadataURI(string calldata metadataURI) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        if (!s.registeredBApps[msg.sender]) revert BAppNotRegistered();

        emit BAppMetadataURIUpdated(msg.sender, metadataURI);
    }

    /// @notice Function to add tokens to a bApp
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to add
    /// @param sharedRiskLevels The shared risk levels of the tokens
    function _addNewTokens(address bApp, address[] calldata tokens, uint32[] calldata sharedRiskLevels) internal {
        ValidationsLib.validateArrayLengths(tokens, sharedRiskLevels);

        uint256 length = tokens.length;
        address token;
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        for (uint256 i = 0; i < length;) {
            token = tokens[i];
            ValidationsLib.validateNonZeroAddress(token);
            if (s.bAppTokens[bApp][token].isSet) revert TokenAlreadyAddedToBApp(token);
            _setTokenRiskLevel(bApp, token, sharedRiskLevels[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Internal function to set the shared risk level for a token
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param sharedRiskLevel The shared risk level
    function _setTokenRiskLevel(address bApp, address token, uint32 sharedRiskLevel) internal {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        ICore.SharedRiskLevel storage tokenData = s.bAppTokens[bApp][token];

        tokenData.value = sharedRiskLevel;
        tokenData.isSet = true;
    }

    // *****************************************
    // *********** Section: Account ************
    // *****************************************

    /// @notice Function to update the metadata URI of the Account
    /// @param metadataURI The new metadata URI
    function updateAccountMetadataURI(string calldata metadataURI) external {
        emit AccountMetadataURIUpdated(msg.sender, metadataURI);
    }

    // *****************************************
    // ** Section: Delegate Validator Balance **
    // *****************************************

    /// @notice Function to delegate a percentage of the account's balance to another account
    /// @param account The address of the account to delegate to
    /// @param percentage The percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function delegateBalance(address account, uint32 percentage) external {
        ValidationsLib.validatePercentage(percentage);

        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (s.delegations[msg.sender][account] != 0) revert DelegationAlreadyExists();

        unchecked {
            uint32 newTotal = s.totalDelegatedPercentage[msg.sender] + percentage;
            if (newTotal > MAX_PERCENTAGE) {
                revert ExceedingPercentageUpdate();
            }
            s.totalDelegatedPercentage[msg.sender] = newTotal;
        }
        s.delegations[msg.sender][account] = percentage;

        emit DelegationCreated(msg.sender, account, percentage);
    }

    /// @notice Function to update the delegated validator balance percentage to another account
    /// @param account The address of the account to delegate to
    /// @param percentage The updated percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function updateDelegatedBalance(address account, uint32 percentage) external {
        ValidationsLib.validatePercentage(percentage);
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        uint32 existingPercentage = s.delegations[msg.sender][account];
        if (existingPercentage == 0) revert DelegationDoesNotExist();
        if (existingPercentage == percentage) revert DelegationExistsWithSameValue();

        unchecked {
            uint32 newTotalPercentage = s.totalDelegatedPercentage[msg.sender] - existingPercentage + percentage;
            if (newTotalPercentage > MAX_PERCENTAGE) revert ExceedingPercentageUpdate();
            s.totalDelegatedPercentage[msg.sender] = newTotalPercentage;
        }

        s.delegations[msg.sender][account] = percentage;

        emit DelegationUpdated(msg.sender, account, percentage);
    }

    /// @notice Removes delegation from an account.
    /// @param account The address of the account whose delegation is being removed.
    function removeDelegatedBalance(address account) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        uint32 percentage = s.delegations[msg.sender][account];
        if (percentage == 0) revert DelegationDoesNotExist();

        unchecked {
            s.totalDelegatedPercentage[msg.sender] -= percentage;
        }

        delete s.delegations[msg.sender][account];

        emit DelegationRemoved(msg.sender, account);
    }

    // ***************************************************
    // *********** Section: Protocol settings ************
    // ***************************************************

    function updateFeeTimelockPeriod(uint32 feeTimelockPeriod) external {
        ProtocolStorageLib.load().feeTimelockPeriod = feeTimelockPeriod;
        emit FeeTimelockPeriodUpdated(feeTimelockPeriod);
    }

    function updateFeeExpireTime(uint32 feeExpireTime) external {
        ProtocolStorageLib.load().feeExpireTime = feeExpireTime;
        emit FeeExpireTimeUpdated(feeExpireTime);
    }

    function updateWithdrawalTimelockPeriod(uint32 withdrawalTimelockPeriod) external {
        ProtocolStorageLib.load().withdrawalTimelockPeriod = withdrawalTimelockPeriod;
        emit WithdrawalTimelockPeriodUpdated(withdrawalTimelockPeriod);
    }

    function updateWithdrawalExpireTime(uint32 withdrawalExpireTime) external {
        ProtocolStorageLib.load().withdrawalExpireTime = withdrawalExpireTime;
        emit WithdrawalExpireTimeUpdated(withdrawalExpireTime);
    }

    function updateObligationTimelockPeriod(uint32 obligationTimelockPeriod) external {
        ProtocolStorageLib.load().obligationTimelockPeriod = obligationTimelockPeriod;
        emit ObligationTimelockPeriodUpdated(obligationTimelockPeriod);
    }

    function updateObligationExpireTime(uint32 obligationExpireTime) external {
        ProtocolStorageLib.load().obligationExpireTime = obligationExpireTime;
        emit ObligationExpireTimeUpdated(obligationExpireTime);
    }

    function updateMaxShares(uint256 maxShares) external {
        ProtocolStorageLib.load().maxShares = maxShares;
        emit StrategyMaxSharesUpdated(maxShares);
    }

    function updateMaxFeeIncrement(uint32 maxFeeIncrement) external {
        ProtocolStorageLib.load().maxFeeIncrement = maxFeeIncrement;
        emit StrategyMaxFeeIncrementUpdated(maxFeeIncrement);
    }
}

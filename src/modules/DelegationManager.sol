// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {StorageData, SSVBasedAppsStorage} from "@ssv/src/libraries/SSVBasedAppsStorage.sol";
import {StorageProtocol, SSVBasedAppsStorageProtocol} from "@ssv/src/libraries/SSVBasedAppsStorageProtocol.sol";
import {ICore} from "@ssv/src/interfaces/ICore.sol";
import {IDelegationManager} from "@ssv/src/interfaces/IDelegationManager.sol";

contract DelegationManager is IDelegationManager {
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
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();
        if (percentage == 0 || percentage > sp.maxPercentage) revert ICore.InvalidPercentage();
        StorageData storage s = SSVBasedAppsStorage.load();

        if (s.delegations[msg.sender][account] != 0) revert ICore.DelegationAlreadyExists();

        unchecked {
            uint32 newTotal = s.totalDelegatedPercentage[msg.sender] + percentage;
            if (newTotal > sp.maxPercentage) {
                revert ICore.ExceedingPercentageUpdate();
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
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        if (percentage == 0 || percentage > sp.maxPercentage) revert ICore.InvalidPercentage();
        StorageData storage s = SSVBasedAppsStorage.load();

        uint32 existingPercentage = s.delegations[msg.sender][account];
        if (existingPercentage == 0) revert ICore.DelegationDoesNotExist();
        if (existingPercentage == percentage) revert ICore.DelegationExistsWithSameValue();

        unchecked {
            uint32 newTotalPercentage = s.totalDelegatedPercentage[msg.sender] - existingPercentage + percentage;
            if (newTotalPercentage > sp.maxPercentage) revert ICore.ExceedingPercentageUpdate();
            s.totalDelegatedPercentage[msg.sender] = newTotalPercentage;
        }

        s.delegations[msg.sender][account] = percentage;

        emit DelegationUpdated(msg.sender, account, percentage);
    }

    /// @notice Removes delegation from an account.
    /// @param account The address of the account whose delegation is being removed.
    function removeDelegatedBalance(address account) external {
        StorageData storage s = SSVBasedAppsStorage.load();

        uint32 percentage = s.delegations[msg.sender][account];
        if (percentage == 0) revert ICore.DelegationDoesNotExist();

        unchecked {
            s.totalDelegatedPercentage[msg.sender] -= percentage;
        }

        delete s.delegations[msg.sender][account];

        emit DelegationRemoved(msg.sender, account);
    }
}

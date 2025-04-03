// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface IDelegationManager {
    event AccountMetadataURIUpdated(address indexed account, string metadataURI);
    event DelegationCreated(address indexed delegator, address indexed receiver, uint32 percentage);
    event DelegationRemoved(address indexed delegator, address indexed receiver);
    event DelegationUpdated(address indexed delegator, address indexed receiver, uint32 percentage);

    function delegateBalance(address receiver, uint32 percentage) external;
    function removeDelegatedBalance(address receiver) external;
    function updateAccountMetadataURI(string calldata metadataURI) external;
    function updateDelegatedBalance(address receiver, uint32 percentage) external;
}

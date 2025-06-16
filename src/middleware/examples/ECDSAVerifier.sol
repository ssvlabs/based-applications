// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {
    OwnableBasedApp
} from "@ssv/src/middleware/modules/core+roles/OwnableBasedApp.sol";

import {
    SignatureChecker
} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract ECDSAVerifier is OwnableBasedApp {
    mapping(address => bool) public hasOptedIn;

    error InvalidSignature();
    error SignerAlreadyOptedIn();

    constructor(
        address _basedAppManager,
        address _initOwner
    ) OwnableBasedApp(_basedAppManager, _initOwner) {}

    function optInToBApp(
        uint32,
        address[] calldata,
        uint32[] calldata,
        bytes calldata data
    ) external override onlySSVBasedAppManager returns (bool success) {
        (address signer, bytes32 messageHash, bytes memory signature) = abi
            .decode(data, (address, bytes32, bytes));

        if (hasOptedIn[signer]) {
            revert SignerAlreadyOptedIn();
        }

        success = SignatureChecker.isValidSignatureNow(
            signer,
            messageHash,
            signature
        );

        if (success) hasOptedIn[signer] = true;
        else revert InvalidSignature();
    }
}

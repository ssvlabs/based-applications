// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {
    OwnableBasedApp
} from "@ssv/src/middleware/modules/core+roles/OwnableBasedApp.sol";

import {
    SignatureChecker
} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ECDSAVerifier is OwnableBasedApp, Test {
    mapping(address => bool) public hasOptedIn;
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
        success = SignatureChecker.isValidSignatureNow(
            signer,
            messageHash,
            signature
        );

        require(!hasOptedIn[signer], "Replay signature is not allowed");

        // Validate signature
        success = SignatureChecker.isValidSignatureNow(
            signer,
            messageHash,
            signature
        );
        require(success, "Invalid signature");

        // Prevent replay
        hasOptedIn[signer] = true; // mark as completed
    }
}

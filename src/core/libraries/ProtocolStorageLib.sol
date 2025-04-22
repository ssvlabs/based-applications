// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

library ProtocolStorageLib {
    /// @title SSV Based Apps Storage Protocol
    /// @notice Represents the operational settings and parameters required by the SSV Based Application Platform
    struct Data {
        uint32 feeTimelockPeriod;
        uint32 feeExpireTime;
        uint32 withdrawalTimelockPeriod;
        uint32 withdrawalExpireTime;
        uint32 obligationTimelockPeriod;
        uint32 obligationExpireTime;
        uint32 maxFeeIncrement;
        uint256 maxShares;
    }

    uint256 private constant SSV_STORAGE_POSITION =
        uint256(keccak256("ssv.based-apps.storage.protocol")) - 1;

    function load() internal pure returns (Data storage sd) {
        uint256 position = SSV_STORAGE_POSITION;
        assembly {
            sd.slot := position
        }
    }
}

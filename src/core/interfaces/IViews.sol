// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IViews {
    function delegations(
        address account,
        address receiver
    ) external view returns (uint32);
    function totalDelegatedPercentage(
        address delegator
    ) external view returns (uint32);
    function registeredBApps(
        address bApp
    ) external view returns (bool isRegistered);
    function strategies(
        uint32 strategyId
    )
        external
        view
        returns (address strategyAddress, address strategyOwner, uint32 fee);
    function ownedStrategies(
        address owner
    ) external view returns (uint32[] memory strategyIds);
    function strategyAccountShares(
        uint32 strategyId,
        address account,
        address token
    ) external view returns (uint256);
    function strategyTotalBalance(
        uint32 strategyId,
        address token
    ) external view returns (uint256);
    function strategyTotalShares(
        uint32 strategyId,
        address token
    ) external view returns (uint256);
    function strategyGeneration(
        uint32 strategyId,
        address token
    ) external view returns (uint256);
    function obligations(
        uint32 strategyId,
        address bApp,
        address token
    ) external view returns (uint32 percentage, bool isSet);
    function bAppTokens(
        address bApp,
        address token
    )
        external
        view
        returns (
            uint32 currentValue,
            bool isSet,
            uint32 pendingValue,
            uint32 effectTime
        );
    function accountBAppStrategy(
        address account,
        address bApp
    ) external view returns (uint32);
    function feeUpdateRequests(
        uint32 strategyId
    ) external view returns (uint32 percentage, uint32 requestTime);
    function withdrawalRequests(
        uint32 strategyId,
        address account,
        address token
    ) external view returns (uint256 shares, uint32 requestTime);
    function obligationRequests(
        uint32 strategyId,
        address token,
        address bApp
    ) external view returns (uint32 percentage, uint32 requestTime);
    function slashingFund(
        address account,
        address token
    ) external view returns (uint256);

    // External Protocol Views
    function maxPercentage() external pure returns (uint32);
    function ethAddress() external pure returns (address);
    function maxShares() external view returns (uint256);
    function maxFeeIncrement() external view returns (uint32);
    function feeTimelockPeriod() external view returns (uint32);
    function feeExpireTime() external view returns (uint32);
    function withdrawalTimelockPeriod() external view returns (uint32);
    function withdrawalExpireTime() external view returns (uint32);
    function obligationTimelockPeriod() external view returns (uint32);
    function obligationExpireTime() external view returns (uint32);
    function disabledFeatures() external view returns (uint32);
    function tokenUpdateTimelockPeriod() external view returns (uint32);
    function getVersion() external pure returns (string memory);
}

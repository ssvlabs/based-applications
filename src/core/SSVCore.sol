// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {ISSVCore} from "@ssv/src/interfaces/ISSVCore.sol";

import {IPlatformManager} from "@ssv/src/interfaces/IPlatformManager.sol";
import {IStrategyManager} from "@ssv/src/interfaces/IStrategyManager.sol";
import {ICore} from "@ssv/src/interfaces/ICore.sol";

import {CoreStorageLib, SSVCoreModules} from "@ssv/src/libraries/CoreStorageLib.sol";
import {ProtocolStorageLib} from "@ssv/src/libraries/ProtocolStorageLib.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MAX_PERCENTAGE} from "@ssv/src/libraries/ValidationsLib.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract SSVCore is ISSVCore, UUPSUpgradeable, Ownable2StepUpgradeable, IPlatformManager, IStrategyManager {
    // ***************************
    // ** Section: Initializers **
    // ***************************
    function initialize(address owner_, IPlatformManager ssvPlatformManager_, IStrategyManager ssvStrategyManager_, uint32 maxFeeIncrement_)
        external
        override
        initializer
        onlyProxy
    {
        __UUPSUpgradeable_init();
        __Ownable_init_unchained(owner_);
        __SSVBasedApplications_init_unchained(ssvPlatformManager_, ssvStrategyManager_, maxFeeIncrement_);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __SSVBasedApplications_init_unchained(IPlatformManager ssvPlatformManager_, IStrategyManager ssvStrategyManager_, uint32 maxFeeIncrement_)
        internal
        onlyInitializing
    {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        ProtocolStorageLib.Data storage sp = ProtocolStorageLib.load();
        s.ssvContracts[SSVCoreModules.SSV_STRATEGY_MANAGER] = address(ssvStrategyManager_);
        s.ssvContracts[SSVCoreModules.SSV_PLATFORM_MANAGER] = address(ssvPlatformManager_);

        if (maxFeeIncrement_ == 0 || maxFeeIncrement_ > 10_000) revert InvalidMaxFeeIncrement();

        sp.maxFeeIncrement = maxFeeIncrement_;
        // FYI set these values from parameters
        sp.feeTimelockPeriod = 7 days;
        sp.feeExpireTime = 1 days;
        sp.withdrawalTimelockPeriod = 5 days;
        sp.withdrawalExpireTime = 1 days;
        sp.obligationTimelockPeriod = 7 days;
        sp.obligationExpireTime = 1 days;
        sp.maxShares = 1e50;

        emit MaxFeeIncrementSet(sp.maxFeeIncrement);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ****************************
    // ** Section: UUPS Required **
    // ****************************
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // *********************************
    // ** Section: External Functions **
    // *********************************

    // solhint-disable no-unused-vars
    function updateBAppMetadataURI(string calldata metadataURI) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function createObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function createStrategy(uint32 fee, string calldata metadataURI) external returns (uint32 strategyId) {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function delegateBalance(address receiver, uint32 percentage) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function depositERC20(uint32 strategyId, IERC20 token, uint256 amount) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function depositETH(uint32 strategyId) external payable {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function finalizeFeeUpdate(uint32 strategyId) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function finalizeUpdateObligation(uint32 strategyId, address bApp, address token) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function finalizeWithdrawal(uint32 strategyId, IERC20 token) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function finalizeWithdrawalETH(uint32 strategyId) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function getSlashableBalance(uint32 strategyId, address bApp, address token) public view returns (uint256 slashableBalance) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];

        uint32 percentage = s.obligations[strategyId][bApp][token].percentage;
        uint256 balance = strategyTokenShares.totalTokenBalance;

        return balance * percentage / MAX_PERCENTAGE;
    }

    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function proposeUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function proposeWithdrawal(uint32 strategyId, address token, uint256 amount) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function reduceFee(uint32 strategyId, uint32 proposedFee) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function removeDelegatedBalance(address receiver) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateDelegatedBalance(address receiver, uint32 percentage) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateStrategyMetadataURI(uint32 strategyId, string calldata metadataURI) external {
        _delegateTo(SSVCoreModules.SSV_STRATEGY_MANAGER);
    }

    function updateAccountMetadataURI(string calldata metadataURI) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function optInToBApp(uint32 strategyId, address bApp, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    // *************************************
    // ** Section: External Functions DAO **
    // *************************************

    function updateFeeTimelockPeriod(uint32 value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateFeeExpireTime(uint32 value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateWithdrawalTimelockPeriod(uint32 value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateWithdrawalExpireTime(uint32 value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateObligationTimelockPeriod(uint32 value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateObligationExpireTime(uint32 value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateMaxPercentage(uint32 percentage) external onlyOwner {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateEthAddress(address value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateMaxShares(uint256 value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    function updateMaxFeeIncrement(uint32 value) external {
        _delegateTo(SSVCoreModules.SSV_PLATFORM_MANAGER);
    }

    // *****************************
    // ** Section: External Views **
    // *****************************

    function delegations(address account, address receiver) external view returns (uint32) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.delegations[account][receiver];
    }

    function totalDelegatedPercentage(address delegator) external view returns (uint32) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.totalDelegatedPercentage[delegator];
    }

    function registeredBApps(address bApp) external view returns (bool isRegistered) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.registeredBApps[bApp];
    }

    function strategies(uint32 strategyId) external view returns (address strategyOwner, uint32 fee) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (s.strategies[strategyId].owner, s.strategies[strategyId].fee);
    }

    function strategyAccountShares(uint32 strategyId, address account, address token) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];
        if (strategyTokenShares.accountGeneration[account] != strategyTokenShares.currentGeneration) return 0;
        else return s.strategyTokenShares[strategyId][token].accountShareBalance[account];
    }

    function strategyTotalBalance(uint32 strategyId, address token) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.strategyTokenShares[strategyId][token].totalTokenBalance;
    }

    function strategyTotalShares(uint32 strategyId, address token) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.strategyTokenShares[strategyId][token].totalShareBalance;
    }

    function strategyGeneration(uint32 strategyId, address token) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.strategyTokenShares[strategyId][token].currentGeneration;
    }

    function obligations(uint32 strategyId, address bApp, address token) external view returns (uint32 percentage, bool isSet) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (s.obligations[strategyId][bApp][token].percentage, s.obligations[strategyId][bApp][token].isSet);
    }

    function usedTokens(uint32 strategyId, address token) external view returns (uint32) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.usedTokens[strategyId][token];
    }

    function bAppTokens(address bApp, address token) external view returns (uint32 value, bool isSet) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (s.bAppTokens[bApp][token].value, s.bAppTokens[bApp][token].isSet);
    }

    function accountBAppStrategy(address account, address bApp) external view returns (uint32) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.accountBAppStrategy[account][bApp];
    }

    function feeUpdateRequests(uint32 strategyId) external view returns (uint32 percentage, uint32 requestTime) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (s.feeUpdateRequests[strategyId].percentage, s.feeUpdateRequests[strategyId].requestTime);
    }

    function withdrawalRequests(uint32 strategyId, address account, address token) external view returns (uint256 shares, uint32 requestTime) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (s.withdrawalRequests[strategyId][account][token].shares, s.withdrawalRequests[strategyId][account][token].requestTime);
    }

    function obligationRequests(uint32 strategyId, address token, address bApp) external view returns (uint32 percentage, uint32 requestTime) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return (s.obligationRequests[strategyId][token][bApp].percentage, s.obligationRequests[strategyId][token][bApp].requestTime);
    }

    function slashingFund(address account, address token) external view returns (uint256) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        return s.slashingFund[account][token];
    }

    // **************************************
    // ** Section: External Protocol Views **
    // **************************************

    function getVersion() external pure returns (string memory) {
        return "0.0.1";
    }

    function maxShares() external view returns (uint256) {
        return ProtocolStorageLib.load().maxShares;
    }

    function maxFeeIncrement() external view returns (uint32) {
        return ProtocolStorageLib.load().maxFeeIncrement;
    }

    function feeTimelockPeriod() external view returns (uint32) {
        return ProtocolStorageLib.load().feeTimelockPeriod;
    }

    function feeExpireTime() external view returns (uint32) {
        return ProtocolStorageLib.load().feeExpireTime;
    }

    function withdrawalTimelockPeriod() external view returns (uint32) {
        return ProtocolStorageLib.load().withdrawalTimelockPeriod;
    }

    function withdrawalExpireTime() external view returns (uint32) {
        return ProtocolStorageLib.load().withdrawalExpireTime;
    }

    function obligationTimelockPeriod() external view returns (uint32) {
        return ProtocolStorageLib.load().obligationTimelockPeriod;
    }

    function obligationExpireTime() external view returns (uint32) {
        return ProtocolStorageLib.load().obligationExpireTime;
    }

    function updateModules(SSVCoreModules[] calldata moduleIds, address[] calldata moduleAddresses) external onlyOwner {
        uint32 size;
        for (uint256 i; i < moduleIds.length; i++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                size := extcodesize(calldataload(add(moduleAddresses.offset, mul(i, 32))))
            }
            if (size == 0) revert TargetModuleDoesNotExist(uint8(moduleIds[i]));

            CoreStorageLib.load().ssvContracts[moduleIds[i]] = moduleAddresses[i];

            emit ModuleUpdated(moduleIds[i], moduleAddresses[i]);
        }
    }

    function _delegateTo(SSVCoreModules moduleId) internal {
        address implementation = CoreStorageLib.load().ssvContracts[moduleId];
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            // slither-disable-next-line incorrect-return
            default { return(0, returndatasize()) }
        }
    }
}

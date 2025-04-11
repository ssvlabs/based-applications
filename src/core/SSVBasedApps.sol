// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {CoreLib} from "@ssv/src/core/libraries/CoreLib.sol";
import {IBasedAppManager} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import {ICore} from "@ssv/src/core/interfaces/ICore.sol";
import {IDelegationManager} from "@ssv/src/core/interfaces/IDelegationManager.sol";
import {ISlashingManager} from "@ssv/src/core/interfaces/ISlashingManager.sol";
import {ISSVBasedApps} from "@ssv/src/core/interfaces/ISSVBasedApps.sol";
import {IProtocolManager} from "@ssv/src/core/interfaces/IProtocolManager.sol";
import {IStrategyManager} from "@ssv/src/core/interfaces/IStrategyManager.sol";
import {SSVBasedAppsModules} from "@ssv/src/core/libraries/SSVBasedAppsStorage.sol";
import {SSVBasedAppsStorage, StorageData} from "@ssv/src/core/libraries/SSVBasedAppsStorage.sol";
import {SSVBasedAppsStorageProtocol, StorageProtocol} from "@ssv/src/core/libraries/SSVBasedAppsStorageProtocol.sol";
import {SSVProxy} from "@ssv/src/core/SSVProxy.sol";

contract SSVBasedApps is
    ISSVBasedApps,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    IBasedAppManager,
    IStrategyManager,
    IProtocolManager,
    ISlashingManager,
    IDelegationManager,
    SSVProxy
{
    // ***************************
    // ** Section: Initializers **
    // ***************************
    function initialize(
        address owner_,
        IBasedAppManager ssvBasedAppManger_,
        IStrategyManager ssvStrategyManager_,
        IProtocolManager protocolManager_,
        ISlashingManager ssvSlashingManager_,
        IDelegationManager ssvDelegationManager_,
        StorageProtocol memory config
    ) external override initializer onlyProxy {
        __UUPSUpgradeable_init();
        __Ownable_init_unchained(owner_);
        __SSVBasedApplications_init_unchained(ssvBasedAppManger_, ssvStrategyManager_, protocolManager_, ssvSlashingManager_, ssvDelegationManager_, config);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __SSVBasedApplications_init_unchained(
        IBasedAppManager ssvBasedAppManger_,
        IStrategyManager ssvStrategyManager_,
        IProtocolManager protocolManager_,
        ISlashingManager ssvSlashingManager_,
        IDelegationManager ssvDelegationManager_,
        StorageProtocol memory config
    ) internal onlyInitializing {
        StorageData storage s = SSVBasedAppsStorage.load();
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();
        s.ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER] = address(ssvStrategyManager_);
        s.ssvContracts[SSVBasedAppsModules.SSV_BASED_APPS_MANAGER] = address(ssvBasedAppManger_);
        s.ssvContracts[SSVBasedAppsModules.SSV_DAO] = address(protocolManager_);
        s.ssvContracts[SSVBasedAppsModules.SSV_SLASHING_MANAGER] = address(ssvSlashingManager_);
        s.ssvContracts[SSVBasedAppsModules.SSV_DELEGATION_MANAGER] = address(ssvDelegationManager_);

        if (config.maxFeeIncrement == 0 || config.maxFeeIncrement > 10_000) revert ICore.InvalidMaxFeeIncrement();

        sp.maxFeeIncrement = config.maxFeeIncrement;
        sp.feeTimelockPeriod = config.feeTimelockPeriod;
        sp.feeExpireTime = config.feeExpireTime;
        sp.withdrawalTimelockPeriod = config.withdrawalTimelockPeriod;
        sp.withdrawalExpireTime = config.withdrawalExpireTime;
        sp.obligationTimelockPeriod = config.obligationTimelockPeriod;
        sp.obligationExpireTime = config.obligationExpireTime;
        sp.maxPercentage = config.maxPercentage;
        sp.ethAddress = config.ethAddress;
        sp.maxShares = config.maxShares;

        // sp.feeExpireTime = 1 days;
        // sp.feeTimelockPeriod = 7 days;
        // sp.withdrawalTimelockPeriod = 14 days;
        // sp.withdrawalExpireTime = 3 days;
        // sp.obligationTimelockPeriod = 14 days;
        // sp.obligationExpireTime = 3 days;
        // sp.maxPercentage = 1e4;
        // sp.ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        // sp.maxShares = 1e50;

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
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_BASED_APPS_MANAGER]);
    }

    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_BASED_APPS_MANAGER]);
    }

    function createObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function createStrategy(uint32 fee, string calldata metadataURI) external returns (uint32 strategyId) {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function delegateBalance(address receiver, uint32 percentage) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DELEGATION_MANAGER]);
    }

    function depositERC20(uint32 strategyId, IERC20 token, uint256 amount) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function depositETH(uint32 strategyId) external payable {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function finalizeFeeUpdate(uint32 strategyId) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function finalizeUpdateObligation(uint32 strategyId, address bApp, address token) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function finalizeWithdrawal(uint32 strategyId, IERC20 token) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function finalizeWithdrawalETH(uint32 strategyId) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function getSlashableBalance(uint32 strategyId, address bApp, address token) public view returns (uint256 slashableBalance) {
        StorageData storage s = SSVBasedAppsStorage.load();

        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];

        uint32 percentage = s.obligations[strategyId][bApp][token].percentage;
        uint256 balance = strategyTokenShares.totalTokenBalance;
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        return balance * percentage / sp.maxPercentage;
    }

    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function proposeUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function proposeWithdrawal(uint32 strategyId, address token, uint256 amount) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function reduceFee(uint32 strategyId, uint32 proposedFee) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function removeDelegatedBalance(address receiver) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DELEGATION_MANAGER]);
    }

    function updateDelegatedBalance(address receiver, uint32 percentage) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DELEGATION_MANAGER]);
    }

    function updateStrategyMetadataURI(uint32 strategyId, string calldata metadataURI) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    function updateAccountMetadataURI(string calldata metadataURI) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DELEGATION_MANAGER]);
    }

    function slash(uint32 strategyId, address bApp, address token, uint256 amount, bytes calldata data) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_SLASHING_MANAGER]);
    }

    function withdrawSlashingFund(address token, uint256 amount) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_SLASHING_MANAGER]);
    }

    function withdrawETHSlashingFund(uint256 amount) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_SLASHING_MANAGER]);
    }

    function optInToBApp(uint32 strategyId, address bApp, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data) external {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_STRATEGY_MANAGER]);
    }

    // *************************************
    // ** Section: External Functions DAO **
    // *************************************

    function updateFeeTimelockPeriod(uint32 value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateFeeExpireTime(uint32 value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateWithdrawalTimelockPeriod(uint32 value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateWithdrawalExpireTime(uint32 value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateObligationTimelockPeriod(uint32 value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateObligationExpireTime(uint32 value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateMaxPercentage(uint32 percentage) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateEthAddress(address value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateMaxShares(uint256 value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    function updateMaxFeeIncrement(uint32 value) external onlyOwner {
        _delegate(SSVBasedAppsStorage.load().ssvContracts[SSVBasedAppsModules.SSV_DAO]);
    }

    // *****************************
    // ** Section: External Views **
    // *****************************

    function delegations(address account, address receiver) external view returns (uint32) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.delegations[account][receiver];
    }

    function totalDelegatedPercentage(address delegator) external view returns (uint32) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.totalDelegatedPercentage[delegator];
    }

    function registeredBApps(address bApp) external view returns (bool isRegistered) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.registeredBApps[bApp];
    }

    function strategies(uint32 strategyId) external view returns (address strategyOwner, uint32 fee, uint32 freezingTime) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return (s.strategies[strategyId].owner, s.strategies[strategyId].fee, s.strategies[strategyId].freezingTime);
    }

    function strategyAccountShares(uint32 strategyId, address account, address token) external view returns (uint256) {
        StorageData storage s = SSVBasedAppsStorage.load();
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];
        if (strategyTokenShares.accountGeneration[account] != strategyTokenShares.currentGeneration) return 0;
        else return s.strategyTokenShares[strategyId][token].accountShareBalance[account];
    }

    function strategyTotalBalance(uint32 strategyId, address token) external view returns (uint256) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.strategyTokenShares[strategyId][token].totalTokenBalance;
    }

    function strategyTotalShares(uint32 strategyId, address token) external view returns (uint256) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.strategyTokenShares[strategyId][token].totalShareBalance;
    }

    function strategyGeneration(uint32 strategyId, address token) external view returns (uint256) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.strategyTokenShares[strategyId][token].currentGeneration;
    }

    function obligations(uint32 strategyId, address bApp, address token) external view returns (uint32 percentage, bool isSet) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return (s.obligations[strategyId][bApp][token].percentage, s.obligations[strategyId][bApp][token].isSet);
    }

    function usedTokens(uint32 strategyId, address token) external view returns (uint32) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.usedTokens[strategyId][token];
    }

    function bAppTokens(address bApp, address token) external view returns (uint32 value, bool isSet) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return (s.bAppTokens[bApp][token].value, s.bAppTokens[bApp][token].isSet);
    }

    function accountBAppStrategy(address account, address bApp) external view returns (uint32) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.accountBAppStrategy[account][bApp];
    }

    function feeUpdateRequests(uint32 strategyId) external view returns (uint32 percentage, uint32 requestTime) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return (s.feeUpdateRequests[strategyId].percentage, s.feeUpdateRequests[strategyId].requestTime);
    }

    function withdrawalRequests(uint32 strategyId, address account, address token) external view returns (uint256 shares, uint32 requestTime) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return (s.withdrawalRequests[strategyId][account][token].shares, s.withdrawalRequests[strategyId][account][token].requestTime);
    }

    function obligationRequests(uint32 strategyId, address token, address bApp) external view returns (uint32 percentage, uint32 requestTime) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return (s.obligationRequests[strategyId][token][bApp].percentage, s.obligationRequests[strategyId][token][bApp].requestTime);
    }

    function slashingFund(address account, address token) external view returns (uint256) {
        StorageData storage s = SSVBasedAppsStorage.load();
        return s.slashingFund[account][token];
    }

    // **************************************
    // ** Section: External Protocol Views **
    // **************************************

    function maxPercentage() external view returns (uint32) {
        return SSVBasedAppsStorageProtocol.load().maxPercentage;
    }

    function ethAddress() external view returns (address) {
        return SSVBasedAppsStorageProtocol.load().ethAddress;
    }

    function maxShares() external view returns (uint256) {
        return SSVBasedAppsStorageProtocol.load().maxShares;
    }

    function maxFeeIncrement() external view returns (uint32) {
        return SSVBasedAppsStorageProtocol.load().maxFeeIncrement;
    }

    function feeTimelockPeriod() external view returns (uint32) {
        return SSVBasedAppsStorageProtocol.load().feeTimelockPeriod;
    }

    function feeExpireTime() external view returns (uint32) {
        return SSVBasedAppsStorageProtocol.load().feeExpireTime;
    }

    function withdrawalTimelockPeriod() external view returns (uint32) {
        return SSVBasedAppsStorageProtocol.load().withdrawalTimelockPeriod;
    }

    function withdrawalExpireTime() external view returns (uint32) {
        return SSVBasedAppsStorageProtocol.load().withdrawalExpireTime;
    }

    function obligationTimelockPeriod() external view returns (uint32) {
        return SSVBasedAppsStorageProtocol.load().obligationTimelockPeriod;
    }

    function obligationExpireTime() external view returns (uint32) {
        return SSVBasedAppsStorageProtocol.load().obligationExpireTime;
    }

    // *********************************
    // ** Section: External Libraries **
    // *********************************

    function getVersion() external pure returns (string memory version) {
        return CoreLib.getVersion();
    }

    function updateModule(SSVBasedAppsModules moduleId, address moduleAddress) external onlyOwner {
        CoreLib.setModuleContract(moduleId, moduleAddress);
    }
}

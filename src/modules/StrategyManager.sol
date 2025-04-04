// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICore} from "@ssv/src/interfaces/ICore.sol";
import {IBasedApp} from "@ssv/src/interfaces/middleware/IBasedApp.sol";
import {IStrategyManager} from "@ssv/src/interfaces/IStrategyManager.sol";
import {StorageData, SSVBasedAppsStorage} from "@ssv/src/libraries/SSVBasedAppsStorage.sol";
import {StorageProtocol, SSVBasedAppsStorageProtocol} from "@ssv/src/libraries/SSVBasedAppsStorageProtocol.sol";
import {CoreLib} from "@ssv/src/libraries/CoreLib.sol";

/**
 * @title SSVBasedApps
 * @notice The Core Contract to manage Based Applications, s.Delegations & Strategies for SSV Based Applications Platform.
 *
 * **************
 * ** GLOSSARY **
 * **************
 * @dev The following terms are used throughout the contract:
 *
 * - **Account**: An Ethereum address that can:
 *   1. Delegate its balance to another address.
 *   2. Create and manage a strategy.
 *   3. Create and manage a bApp.
 *
 * - **Based Application**: or bApp.
 *   The entity that requests validation services from operators. On-chain is represented by an Ethereum address.
 *   A bApp can be created by registering to this Core Contract, specifying the risk level.
 *   The bApp can also specify one or many tokens as slashable capital to be provided by strategies.
 *   During the bApp registration, the bApp owner can set the shared risk level and optionally a metadata URI, to be used in the SSV bApp marketplace.
 *
 * - **Delegator**: An Ethereum address that has Ethereum Validator Balance of Staked ETH within the SSV platform. This capital delegated is non-slashable.
 *   The delegator can decide to delegate its balance to itself or/and to a single or many receiver accounts.
 *   The delegator has to set its address as the receiver account, when the delegator wants to delegate its balance to itself.
 *   The delegated balance goes to an account and not to a strategy. This receiver account can manage only a single strategy.
 *
 * - **Strategy**: The entity that manages the slashable assets bounded to based apps.
 *   The strategy has its own balance, accounted in this core contract.
 *   The strategy can be created by an account that becomes its owner.
 *   The assets can be ERC20 tokens or Native ETH tokens, that can be deposited or withdrawn by the participants.
 *   The strategy can manage its assets via s.obligations to one or many bApps.
 *
 * - **Obligation**: A percentage of the strategy's balance of ERC20 (or Native ETH), that is reserved for securing a bApp.
 *   The obligation is set exclusively by the strategy owner and can be updated by the strategy owner.
 *   The tokens specified in an obligation needs to match the tokens specified in the bApp.
 *
 * *************
 * ** AUTHORS **
 * *************
 * @author
 * Marco Tabasco
 * Riccardo Persiani
 */
contract StrategyManager is ReentrancyGuardTransient, IStrategyManager {
    using SafeERC20 for IERC20;

    /// @notice Allow the function to be called only by the strategy owner
    /// @param strategyId The ID of the strategy
    modifier onlyStrategyOwner(uint32 strategyId) {
        StorageData storage s = SSVBasedAppsStorage.load();

        if (s.strategies[strategyId].owner != msg.sender) {
            revert ICore.InvalidStrategyOwner(msg.sender, s.strategies[strategyId].owner);
        }
        _;
    }

    /// @notice Allow the function to be called only if the strategy is not frozen
    /// @param strategyId The ID of the strategy
    /// @dev This modifier is used to prevent withdrawals when the strategy is frozen
    /// @dev The strategy can be frozen by the bApp owner when malicious behavior is detected
    modifier onlyNotFrozen(uint32 strategyId) {
        StorageData storage s = SSVBasedAppsStorage.load();

        if (s.strategies[strategyId].isFrozen) {
            revert ICore.StrategyIsFrozen();
        }
        _;
    }

    // ***********************
    // ** Section: Strategy **
    // ***********************

    /// @notice Function to create a new Strategy
    /// @param metadataURI The metadata URI of the strategy
    /// @return strategyId The ID of the new Strategy
    function createStrategy(uint32 fee, string calldata metadataURI) external returns (uint32 strategyId) {
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        if (fee > sp.maxPercentage) revert ICore.InvalidStrategyFee();
        StorageData storage s = SSVBasedAppsStorage.load();

        unchecked {
            strategyId = ++s._strategyCounter;
        }

        ICore.Strategy storage newStrategy = s.strategies[strategyId];
        newStrategy.owner = msg.sender;
        newStrategy.fee = fee;

        emit StrategyCreated(strategyId, msg.sender, fee, metadataURI);
    }

    /// @notice Function to update the metadata URI of the Strategy
    /// @param strategyId The id of the strategy
    /// @param metadataURI The new metadata URI
    function updateStrategyMetadataURI(uint32 strategyId, string calldata metadataURI) external onlyStrategyOwner(strategyId) {
        emit StrategyMetadataURIUpdated(strategyId, metadataURI);
    }

    /// @notice Opt-in to a bApp with a list of tokens and obligation percentages
    /// @dev checks that each token is supported by the bApp, but not that the obligation is > 0
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to opt-in with
    /// @param obligationPercentages The list of obligation percentages for each token
    /// @param data Optional parameter that could be required by the service
    function optInToBApp(uint32 strategyId, address bApp, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data)
        external
        onlyStrategyOwner(strategyId)
    {
        if (tokens.length != obligationPercentages.length) revert ICore.LengthsNotMatching();
        StorageData storage s = SSVBasedAppsStorage.load();
        // Check if a strategy exists for the given bApp.
        // It is not possible opt-in to the same bApp twice with the same strategy owner.
        if (s.accountBAppStrategy[msg.sender][bApp] != 0) revert ICore.BAppAlreadyOptedIn();

        _createOptInObligations(strategyId, bApp, tokens, obligationPercentages);

        s.accountBAppStrategy[msg.sender][bApp] = strategyId;

        if (CoreLib.isBApp(bApp)) {
            bool success = IBasedApp(bApp).optInToBApp(strategyId, tokens, obligationPercentages, data);
            if (!success) revert ICore.BAppOptInFailed();
        }

        emit BAppOptedInByStrategy(strategyId, bApp, data, tokens, obligationPercentages);
    }

    /// @notice Deposit ERC20 tokens into the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to deposit
    function depositERC20(uint32 strategyId, IERC20 token, uint256 amount) external nonReentrant {
        _beforeDeposit(strategyId, address(token), amount);

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit StrategyDeposit(strategyId, msg.sender, address(token), amount);
    }

    /// @notice Deposit ETH into the strategy
    /// @param strategyId The ID of the strategy
    function depositETH(uint32 strategyId) external payable nonReentrant {
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();
        _beforeDeposit(strategyId, sp.ethAddress, msg.value);

        emit StrategyDeposit(strategyId, msg.sender, sp.ethAddress, msg.value);
    }

    /// @notice Propose a withdrawal of ERC20 tokens from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    /// @param amount The amount to withdraw.
    function proposeWithdrawal(uint32 strategyId, address token, uint256 amount) external {
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();
        if (token == sp.ethAddress) revert ICore.InvalidToken();
        _proposeWithdrawal(strategyId, token, amount);
    }

    /// @notice Finalize the ERC20 withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    function finalizeWithdrawal(uint32 strategyId, IERC20 token) external nonReentrant {
        uint256 amount = _finalizeWithdrawal(strategyId, address(token));

        token.safeTransfer(msg.sender, amount);

        emit StrategyWithdrawal(strategyId, msg.sender, address(token), amount, false);
    }

    /// @notice Propose an ETH withdrawal from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param amount The amount of ETH to withdraw.
    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external {
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();
        _proposeWithdrawal(strategyId, sp.ethAddress, amount);
    }

    /// @notice Finalize the ETH withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    function finalizeWithdrawalETH(uint32 strategyId) external nonReentrant {
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        uint256 amount = _finalizeWithdrawal(strategyId, sp.ethAddress);

        payable(msg.sender).transfer(amount);

        emit StrategyWithdrawal(strategyId, msg.sender, sp.ethAddress, amount, false);
    }

    /// @notice Add a new obligation for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function createObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external onlyStrategyOwner(strategyId) {
        StorageData storage s = SSVBasedAppsStorage.load();

        if (s.accountBAppStrategy[msg.sender][bApp] != strategyId) revert ICore.BAppNotOptedIn();

        _createSingleObligation(strategyId, bApp, token, obligationPercentage);

        emit ObligationCreated(strategyId, bApp, token, obligationPercentage);
    }

    /// @notice Propose a withdrawal of ERC20 tokens from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    /// @param obligationPercentage The new percentage of the obligation
    function proposeUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external onlyStrategyOwner(strategyId) {
        _validateObligationUpdateInput(strategyId, bApp, token, obligationPercentage);

        StorageData storage s = SSVBasedAppsStorage.load();

        ICore.ObligationRequest storage request = s.obligationRequests[strategyId][bApp][token];

        request.percentage = obligationPercentage;
        request.requestTime = uint32(block.timestamp);

        emit ObligationUpdateProposed(strategyId, bApp, address(token), obligationPercentage);
    }

    /// @notice Finalize the withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    /// @param bApp The address of the bApp.
    /// @param token The ERC20 token address.
    function finalizeUpdateObligation(uint32 strategyId, address bApp, address token) external onlyStrategyOwner(strategyId) {
        StorageData storage s = SSVBasedAppsStorage.load();

        ICore.ObligationRequest storage request = s.obligationRequests[strategyId][bApp][address(token)];
        uint256 requestTime = request.requestTime;
        uint32 percentage = request.percentage;

        if (requestTime == 0) revert ICore.NoPendingObligationUpdate();
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        _checkTimelocks(requestTime, sp.obligationTimelockPeriod, sp.obligationExpireTime);

        if (percentage == 0 && s.obligations[strategyId][bApp][address(token)].percentage > 0) {
            s.usedTokens[strategyId][address(token)] -= 1;
        }

        _updateObligation(strategyId, bApp, address(token), percentage);

        emit ObligationUpdated(strategyId, bApp, address(token), percentage);

        delete s.obligationRequests[strategyId][bApp][address(token)];
    }

    /// @notice Instantly lowers the fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function reduceFee(uint32 strategyId, uint32 proposedFee) external onlyStrategyOwner(strategyId) {
        StorageData storage s = SSVBasedAppsStorage.load();

        if (proposedFee >= s.strategies[strategyId].fee) revert ICore.InvalidPercentageIncrement();

        s.strategies[strategyId].fee = proposedFee;

        emit StrategyFeeUpdated(strategyId, msg.sender, proposedFee, true);
    }

    /// @notice Propose a new fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external onlyStrategyOwner(strategyId) {
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        if (proposedFee > sp.maxPercentage) revert ICore.InvalidPercentage();
        StorageData storage s = SSVBasedAppsStorage.load();

        ICore.Strategy storage strategy = s.strategies[strategyId];
        uint32 fee = strategy.fee;

        if (proposedFee == fee) revert ICore.FeeAlreadySet();
        if (proposedFee > fee + sp.maxFeeIncrement) revert ICore.InvalidPercentageIncrement();

        ICore.FeeUpdateRequest storage request = s.feeUpdateRequests[strategyId];

        request.percentage = proposedFee;
        request.requestTime = uint32(block.timestamp);

        emit StrategyFeeUpdateProposed(strategyId, msg.sender, proposedFee);
    }

    /// @notice Finalize the fee update for a strategy
    /// @param strategyId The ID of the strategy
    function finalizeFeeUpdate(uint32 strategyId) external onlyStrategyOwner(strategyId) {
        StorageData storage s = SSVBasedAppsStorage.load();
        ICore.Strategy storage strategy = s.strategies[strategyId];
        ICore.FeeUpdateRequest storage request = s.feeUpdateRequests[strategyId];

        uint256 feeRequestTime = request.requestTime;

        if (feeRequestTime == 0) revert ICore.NoPendingFeeUpdate();
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();
        _checkTimelocks(feeRequestTime, sp.feeTimelockPeriod, sp.feeExpireTime);

        strategy.fee = request.percentage;
        delete request.percentage;
        delete request.requestTime;

        emit StrategyFeeUpdated(strategyId, msg.sender, strategy.fee, false);
    }

    // **********************
    // ** Section: Helpers **
    // **********************

    /// @notice Set the obligation percentages for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to set s.obligations for
    /// @param obligationPercentages The list of obligation percentages for each token
    function _createOptInObligations(uint32 strategyId, address bApp, address[] calldata tokens, uint32[] calldata obligationPercentages) private {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length;) {
            _createSingleObligation(strategyId, bApp, tokens[i], obligationPercentages[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Set a single obligation for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function _createSingleObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) private {
        StorageData storage s = SSVBasedAppsStorage.load();

        if (!s.bAppTokens[bApp][token].isSet) revert ICore.TokenNotSupportedByBApp(token);
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        if (obligationPercentage > sp.maxPercentage) revert ICore.InvalidPercentage();

        if (s.obligations[strategyId][bApp][token].isSet) revert ICore.ObligationAlreadySet();

        if (obligationPercentage != 0) {
            s.usedTokens[strategyId][token] += 1;
            s.obligations[strategyId][bApp][token].percentage = obligationPercentage;
        }

        s.obligations[strategyId][bApp][token].isSet = true;
    }

    /// @notice Validate the input for the obligation creation or update
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function _validateObligationUpdateInput(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) private view {
        StorageData storage s = SSVBasedAppsStorage.load();

        if (s.accountBAppStrategy[msg.sender][bApp] != strategyId) revert ICore.BAppNotOptedIn();
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        if (obligationPercentage > sp.maxPercentage) revert ICore.InvalidPercentage();

        if (obligationPercentage == s.obligations[strategyId][bApp][token].percentage) {
            revert ICore.ObligationAlreadySet();
        }
        if (!s.obligations[strategyId][bApp][token].isSet) revert ICore.ObligationHasNotBeenCreated();
    }

    /// @notice Update a single obligation for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    function _updateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) private {
        StorageData storage s = SSVBasedAppsStorage.load();

        if (s.obligations[strategyId][bApp][token].percentage == 0 && obligationPercentage > 0) {
            s.usedTokens[strategyId][token] += 1;
        }
        s.obligations[strategyId][bApp][token].percentage = obligationPercentage;
    }

    /// @notice Check the timelocks
    /// @param requestTime The time of the request
    /// @param timelockPeriod The timelock period
    /// @param expireTime The expire time
    function _checkTimelocks(uint256 requestTime, uint256 timelockPeriod, uint256 expireTime) internal view {
        uint256 currentTime = uint32(block.timestamp);
        uint256 unlockTime = requestTime + timelockPeriod;
        if (currentTime < unlockTime) revert ICore.TimelockNotElapsed();
        if (currentTime > unlockTime + expireTime) {
            revert ICore.RequestTimeExpired();
        }
    }

    function _beforeDeposit(uint32 strategyId, address token, uint256 amount) internal {
        if (amount == 0) revert ICore.InvalidAmount();

        StorageData storage s = SSVBasedAppsStorage.load();
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];

        uint256 totalTokenBalance = strategyTokenShares.totalTokenBalance;
        uint256 totalShares = strategyTokenShares.totalShareBalance;

        uint256 shares;
        if (totalShares == 0 || totalTokenBalance == 0) shares = amount;
        else shares = (amount * totalShares) / totalTokenBalance;

        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();
        if (totalShares + shares > sp.maxShares) revert ICore.ExceedingMaxShares();

        if (strategyTokenShares.currentGeneration != strategyTokenShares.accountGeneration[msg.sender]) {
            strategyTokenShares.accountGeneration[msg.sender] = strategyTokenShares.currentGeneration;
            /// @dev override the previous share balance
            strategyTokenShares.accountShareBalance[msg.sender] = shares;
        } else {
            strategyTokenShares.accountShareBalance[msg.sender] += shares;
        }

        strategyTokenShares.totalShareBalance += shares;
        strategyTokenShares.totalTokenBalance += amount;
    }

    function _proposeWithdrawal(uint32 strategyId, address token, uint256 amount) internal {
        if (amount == 0) revert ICore.InvalidAmount();

        StorageData storage s = SSVBasedAppsStorage.load();
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];

        if (strategyTokenShares.currentGeneration != strategyTokenShares.accountGeneration[msg.sender]) revert ICore.InvalidAccountGeneration();
        uint256 totalTokenBalance = strategyTokenShares.totalTokenBalance;
        uint256 totalShares = strategyTokenShares.totalShareBalance;

        if (totalTokenBalance == 0 || totalShares == 0) revert ICore.InsufficientLiquidity();
        uint256 shares = (amount * totalShares) / totalTokenBalance;

        if (strategyTokenShares.accountShareBalance[msg.sender] < shares) revert ICore.InsufficientBalance();
        ICore.WithdrawalRequest storage request = s.withdrawalRequests[strategyId][msg.sender][address(token)];

        request.shares = shares;
        request.requestTime = uint32(block.timestamp);

        emit StrategyWithdrawalProposed(strategyId, msg.sender, address(token), amount);
    }

    function _finalizeWithdrawal(uint32 strategyId, address token) private returns (uint256 amount) {
        StorageData storage s = SSVBasedAppsStorage.load();

        ICore.WithdrawalRequest storage request = s.withdrawalRequests[strategyId][msg.sender][token];
        uint256 requestTime = request.requestTime;

        if (requestTime == 0) revert ICore.NoPendingWithdrawal();
        StorageProtocol storage sp = SSVBasedAppsStorageProtocol.load();

        _checkTimelocks(requestTime, sp.withdrawalTimelockPeriod, sp.withdrawalExpireTime);

        uint256 shares = request.shares;

        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[strategyId][token];

        if (strategyTokenShares.currentGeneration != strategyTokenShares.accountGeneration[msg.sender]) revert ICore.InvalidAccountGeneration();

        uint256 totalTokenBalance = strategyTokenShares.totalTokenBalance;
        uint256 totalShares = strategyTokenShares.totalShareBalance;

        // TODO: To Check: double check that this is not needed
        // if (totalTokenBalance == 0 || totalShares == 0) revert ICore.InsufficientLiquidity();

        amount = (shares * totalTokenBalance) / totalShares;

        strategyTokenShares.accountShareBalance[msg.sender] -= shares;
        strategyTokenShares.totalShareBalance -= shares;
        strategyTokenShares.totalTokenBalance -= amount;

        delete s.withdrawalRequests[strategyId][msg.sender][token];

        return amount;
    }
}

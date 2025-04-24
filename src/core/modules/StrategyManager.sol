// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { ValidationLib, MAX_PERCENTAGE, ETH_ADDRESS } from "@ssv/src/core/libraries/ValidationLib.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";
import { IStrategyManager } from "@ssv/src/core/interfaces/IStrategyManager.sol";
import { CoreStorageLib } from "@ssv/src/core/libraries/CoreStorageLib.sol";
import { ProtocolStorageLib } from "@ssv/src/core/libraries/ProtocolStorageLib.sol";
import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";

import { IBasedApp } from "@ssv/src/middleware/interfaces/IBasedApp.sol";

contract StrategyManager is ReentrancyGuardTransient, IStrategyManager {
    using SafeERC20 for IERC20;

    uint32 private constant SLASHING_DISABLED = 1 << 0;
    uint32 private constant WITHDRAWALS_DISABLED = 1 << 1;

    /// @notice Checks if the caller is the strategy owner
    /// @param strategyId The ID of the strategy
    /// @param s The CoreStorageLib data
    function _onlyStrategyOwner(
        uint32 strategyId,
        CoreStorageLib.Data storage s
    ) private view {
        if (s.strategies[strategyId].owner != msg.sender) {
            revert InvalidStrategyOwner(
                msg.sender,
                s.strategies[strategyId].owner
            );
        }
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
        ValidationLib.validatePercentageAndNonZero(percentage);
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (s.delegations[msg.sender][account] != 0) {
            revert DelegationAlreadyExists();
        }

        unchecked {
            uint32 newTotal = s.totalDelegatedPercentage[msg.sender] +
                percentage;
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
    function updateDelegatedBalance(
        address account,
        uint32 percentage
    ) external {
        ValidationLib.validatePercentageAndNonZero(percentage);

        CoreStorageLib.Data storage s = CoreStorageLib.load();

        uint32 existingPercentage = s.delegations[msg.sender][account];
        if (existingPercentage == 0) revert DelegationDoesNotExist();
        if (existingPercentage == percentage) {
            revert DelegationExistsWithSameValue();
        }

        unchecked {
            uint32 newTotalPercentage = s.totalDelegatedPercentage[msg.sender] -
                existingPercentage +
                percentage;
            if (newTotalPercentage > MAX_PERCENTAGE) {
                revert ExceedingPercentageUpdate();
            }
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

    // ***********************
    // ** Section: Strategy **
    // ***********************

    /// @notice Function to create a new Strategy
    /// @param metadataURI The metadata URI of the strategy
    /// @return strategyId The ID of the new Strategy
    function createStrategy(
        uint32 fee,
        string calldata metadataURI
    ) external returns (uint32 strategyId) {
        if (fee > MAX_PERCENTAGE) revert InvalidStrategyFee();
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        unchecked {
            strategyId = ++s._strategyCounter;
        }

        ICore.Strategy storage newStrategy = s.strategies[strategyId];
        newStrategy.owner = msg.sender;
        newStrategy.fee = fee;

        s.strategyOwners[msg.sender].push(strategyId);

        emit StrategyCreated(strategyId, msg.sender, fee, metadataURI);
    }

    /// @notice Function to update the metadata URI of the Strategy
    /// @param strategyId The id of the strategy
    /// @param metadataURI The new metadata URI
    function updateStrategyMetadataURI(
        uint32 strategyId,
        string calldata metadataURI
    ) external {
        _onlyStrategyOwner(strategyId, CoreStorageLib.load());
        emit StrategyMetadataURIUpdated(strategyId, metadataURI);
    }

    /// @notice Opt-in to a bApp with a list of tokens and obligation percentages
    /// @dev checks that each token is supported by the bApp, but not that the obligation is > 0
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to opt-in with
    /// @param obligationPercentages The list of obligation percentages for each token
    /// @param data Optional parameter that could be required by the service
    function optInToBApp(
        uint32 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        _onlyStrategyOwner(strategyId, s);

        ValidationLib.validateArrayLengths(tokens, obligationPercentages);

        // Check if a strategy exists for the given bApp.
        // It is not possible opt-in to the same bApp twice with the same strategy owner.
        if (s.accountBAppStrategy[msg.sender][bApp] != 0) {
            revert BAppAlreadyOptedIn();
        }

        _createOptInObligations(
            strategyId,
            bApp,
            tokens,
            obligationPercentages
        );

        s.accountBAppStrategy[msg.sender][bApp] = strategyId;

        if (_isBApp(bApp)) {
            bool success = IBasedApp(bApp).optInToBApp(
                strategyId,
                tokens,
                obligationPercentages,
                data
            );
            if (!success) revert BAppOptInFailed();
        }

        emit BAppOptedInByStrategy(
            strategyId,
            bApp,
            data,
            tokens,
            obligationPercentages
        );
    }

    /// @notice Function to check if an address uses the correct bApp interface
    /// @param bApp The address of the bApp
    /// @return True if the address uses the correct bApp interface
    function _isBApp(address bApp) private view returns (bool) {
        return
            ERC165Checker.supportsInterface(bApp, type(IBasedApp).interfaceId);
    }

    /// @notice Deposit ERC20 tokens into the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to deposit
    function depositERC20(
        uint32 strategyId,
        IERC20 token,
        uint256 amount
    ) external nonReentrant {
        _beforeDeposit(strategyId, address(token), amount);

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit StrategyDeposit(strategyId, msg.sender, address(token), amount);
    }

    /// @notice Deposit ETH into the strategy
    /// @param strategyId The ID of the strategy
    function depositETH(uint32 strategyId) external payable nonReentrant {
        _beforeDeposit(strategyId, ETH_ADDRESS, msg.value);

        emit StrategyDeposit(strategyId, msg.sender, ETH_ADDRESS, msg.value);
    }

    /// @notice Propose a withdrawal of ERC20 tokens from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    /// @param amount The amount to withdraw.
    function proposeWithdrawal(
        uint32 strategyId,
        address token,
        uint256 amount
    ) external {
        _checkWithdrawalsAllowed();

        if (token == ETH_ADDRESS) revert InvalidToken();
        _proposeWithdrawal(strategyId, token, amount);
    }

    /// @notice Finalize the ERC20 withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    function finalizeWithdrawal(
        uint32 strategyId,
        IERC20 token
    ) external nonReentrant {
        _checkWithdrawalsAllowed();

        uint256 amount = _finalizeWithdrawal(strategyId, address(token));

        token.safeTransfer(msg.sender, amount);

        emit StrategyWithdrawal(
            strategyId,
            msg.sender,
            address(token),
            amount,
            false
        );
    }

    /// @notice Propose an ETH withdrawal from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param amount The amount of ETH to withdraw.
    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external {
        _checkWithdrawalsAllowed();
        _proposeWithdrawal(strategyId, ETH_ADDRESS, amount);
    }

    /// @notice Finalize the ETH withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    function finalizeWithdrawalETH(uint32 strategyId) external nonReentrant {
        _checkWithdrawalsAllowed();

        uint256 amount = _finalizeWithdrawal(strategyId, ETH_ADDRESS);

        payable(msg.sender).transfer(amount);

        emit StrategyWithdrawal(
            strategyId,
            msg.sender,
            ETH_ADDRESS,
            amount,
            false
        );
    }

    /// @notice Add a new obligation for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function createObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        _onlyStrategyOwner(strategyId, s);

        if (s.accountBAppStrategy[msg.sender][bApp] != strategyId) {
            revert BAppNotOptedIn();
        }

        _createSingleObligation(strategyId, bApp, token, obligationPercentage);

        emit ObligationCreated(strategyId, bApp, token, obligationPercentage);
    }

    /// @notice Propose a withdrawal of ERC20 tokens from the strategy.
    /// @param strategyId The ID of the strategy.
    /// @param token The ERC20 token address.
    /// @param obligationPercentage The new percentage of the obligation
    function proposeUpdateObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        _onlyStrategyOwner(strategyId, s);

        _validateObligationUpdateInput(
            strategyId,
            bApp,
            token,
            obligationPercentage
        );

        ICore.ObligationRequest storage request = s.obligationRequests[
            strategyId
        ][bApp][token];

        request.percentage = obligationPercentage;
        request.requestTime = uint32(block.timestamp);

        emit ObligationUpdateProposed(
            strategyId,
            bApp,
            address(token),
            obligationPercentage
        );
    }

    /// @notice Finalize the withdrawal after the timelock period has passed.
    /// @param strategyId The ID of the strategy.
    /// @param bApp The address of the bApp.
    /// @param token The ERC20 token address.
    function finalizeUpdateObligation(
        uint32 strategyId,
        address bApp,
        address token
    ) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        _onlyStrategyOwner(strategyId, s);

        ICore.ObligationRequest storage request = s.obligationRequests[
            strategyId
        ][bApp][address(token)];
        uint256 requestTime = request.requestTime;
        uint32 percentage = request.percentage;

        if (requestTime == 0) revert NoPendingObligationUpdate();
        ProtocolStorageLib.Data storage sp = ProtocolStorageLib.load();

        _checkTimelocks(
            requestTime,
            sp.obligationTimelockPeriod,
            sp.obligationExpireTime
        );

        s.obligations[strategyId][bApp][address(token)].percentage = percentage;

        emit ObligationUpdated(strategyId, bApp, address(token), percentage);

        delete s.obligationRequests[strategyId][bApp][address(token)];
    }

    /// @notice Instantly lowers the fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function reduceFee(uint32 strategyId, uint32 proposedFee) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        _onlyStrategyOwner(strategyId, s);

        if (proposedFee >= s.strategies[strategyId].fee) {
            revert InvalidPercentageIncrement();
        }

        s.strategies[strategyId].fee = proposedFee;

        emit StrategyFeeUpdated(strategyId, msg.sender, proposedFee, true);
    }

    /// @notice Propose a new fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        _onlyStrategyOwner(strategyId, s);

        ProtocolStorageLib.Data storage sp = ProtocolStorageLib.load();

        ValidationLib.validatePercentage(proposedFee);

        ICore.Strategy storage strategy = s.strategies[strategyId];
        uint32 fee = strategy.fee;

        if (proposedFee == fee) revert FeeAlreadySet();
        if (proposedFee > fee + sp.maxFeeIncrement) {
            revert InvalidPercentageIncrement();
        }

        ICore.FeeUpdateRequest storage request = s.feeUpdateRequests[
            strategyId
        ];

        request.percentage = proposedFee;
        request.requestTime = uint32(block.timestamp);

        emit StrategyFeeUpdateProposed(strategyId, msg.sender, proposedFee);
    }

    /// @notice Finalize the fee update for a strategy
    /// @param strategyId The ID of the strategy
    function finalizeFeeUpdate(uint32 strategyId) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        _onlyStrategyOwner(strategyId, s);

        ICore.Strategy storage strategy = s.strategies[strategyId];
        ICore.FeeUpdateRequest storage request = s.feeUpdateRequests[
            strategyId
        ];

        uint256 feeRequestTime = request.requestTime;

        if (feeRequestTime == 0) revert NoPendingFeeUpdate();
        ProtocolStorageLib.Data storage sp = ProtocolStorageLib.load();
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
    function _createOptInObligations(
        uint32 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages
    ) private {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; ) {
            _createSingleObligation(
                strategyId,
                bApp,
                tokens[i],
                obligationPercentages[i]
            );
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
    function _createSingleObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) private {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (!s.bAppTokens[bApp][token].isSet) {
            revert TokenNotSupportedByBApp(token);
        }

        ValidationLib.validatePercentage(obligationPercentage);

        if (s.obligations[strategyId][bApp][token].isSet) {
            revert ObligationAlreadySet();
        }

        if (obligationPercentage != 0) {
            s
            .obligations[strategyId][bApp][token]
                .percentage = obligationPercentage;
        }

        s.obligations[strategyId][bApp][token].isSet = true;
    }

    /// @notice Validate the input for the obligation creation or update
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function _validateObligationUpdateInput(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) private view {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (s.accountBAppStrategy[msg.sender][bApp] != strategyId) {
            revert BAppNotOptedIn();
        }

        //if (obligationPercentage > MAX_PERCENTAGE) revert ICore.InvalidPercentage();
        ValidationLib.validatePercentage(obligationPercentage);

        if (
            obligationPercentage ==
            s.obligations[strategyId][bApp][token].percentage
        ) {
            revert ObligationAlreadySet();
        }
        if (!s.obligations[strategyId][bApp][token].isSet) {
            revert ObligationHasNotBeenCreated();
        }
    }

    /// @notice Check the timelocks
    /// @param requestTime The time of the request
    /// @param timelockPeriod The timelock period
    /// @param expireTime The expire time
    function _checkTimelocks(
        uint256 requestTime,
        uint256 timelockPeriod,
        uint256 expireTime
    ) internal view {
        uint256 currentTime = uint32(block.timestamp);
        uint256 unlockTime = requestTime + timelockPeriod;
        if (currentTime < unlockTime) revert TimelockNotElapsed();
        if (currentTime > unlockTime + expireTime) {
            revert RequestTimeExpired();
        }
    }

    function _beforeDeposit(
        uint32 strategyId,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) revert InvalidAmount();

        CoreStorageLib.Data storage s = CoreStorageLib.load();
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[
            strategyId
        ][token];

        uint256 totalTokenBalance = strategyTokenShares.totalTokenBalance;
        uint256 totalShares = strategyTokenShares.totalShareBalance;

        uint256 shares;
        if (totalShares == 0 || totalTokenBalance == 0) shares = amount;
        else shares = (amount * totalShares) / totalTokenBalance;

        ProtocolStorageLib.Data storage sp = ProtocolStorageLib.load();
        if (totalShares + shares > sp.maxShares) revert ExceedingMaxShares();

        if (
            strategyTokenShares.currentGeneration !=
            strategyTokenShares.accountGeneration[msg.sender]
        ) {
            strategyTokenShares.accountGeneration[
                msg.sender
            ] = strategyTokenShares.currentGeneration;
            /// @dev override the previous share balance
            strategyTokenShares.accountShareBalance[msg.sender] = shares;
        } else {
            strategyTokenShares.accountShareBalance[msg.sender] += shares;
        }

        strategyTokenShares.totalShareBalance += shares;
        strategyTokenShares.totalTokenBalance += amount;
    }

    function _proposeWithdrawal(
        uint32 strategyId,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) revert InvalidAmount();

        CoreStorageLib.Data storage s = CoreStorageLib.load();
        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[
            strategyId
        ][token];

        if (
            strategyTokenShares.currentGeneration !=
            strategyTokenShares.accountGeneration[msg.sender]
        ) revert InvalidAccountGeneration();
        uint256 totalTokenBalance = strategyTokenShares.totalTokenBalance;
        uint256 totalShares = strategyTokenShares.totalShareBalance;

        if (totalTokenBalance == 0 || totalShares == 0) {
            revert InsufficientLiquidity();
        }
        uint256 shares = (amount * totalShares) / totalTokenBalance;

        if (strategyTokenShares.accountShareBalance[msg.sender] < shares) {
            revert InsufficientBalance();
        }
        ICore.WithdrawalRequest storage request = s.withdrawalRequests[
            strategyId
        ][msg.sender][address(token)];

        request.shares = shares;
        request.requestTime = uint32(block.timestamp);

        emit StrategyWithdrawalProposed(
            strategyId,
            msg.sender,
            address(token),
            amount
        );
    }

    function _finalizeWithdrawal(
        uint32 strategyId,
        address token
    ) private returns (uint256 amount) {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        ICore.WithdrawalRequest storage request = s.withdrawalRequests[
            strategyId
        ][msg.sender][token];
        uint256 requestTime = request.requestTime;

        if (requestTime == 0) revert NoPendingWithdrawal();
        ProtocolStorageLib.Data storage sp = ProtocolStorageLib.load();

        _checkTimelocks(
            requestTime,
            sp.withdrawalTimelockPeriod,
            sp.withdrawalExpireTime
        );

        uint256 shares = request.shares;

        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[
            strategyId
        ][token];

        if (
            strategyTokenShares.currentGeneration !=
            strategyTokenShares.accountGeneration[msg.sender]
        ) revert InvalidAccountGeneration();

        uint256 totalTokenBalance = strategyTokenShares.totalTokenBalance;
        uint256 totalShares = strategyTokenShares.totalShareBalance;

        amount = (shares * totalTokenBalance) / totalShares;

        strategyTokenShares.accountShareBalance[msg.sender] -= shares;
        strategyTokenShares.totalShareBalance -= shares;
        strategyTokenShares.totalTokenBalance -= amount;

        delete s.withdrawalRequests[strategyId][msg.sender][token];

        return amount;
    }

    // ***********************
    // ** Section: Slashing **
    // ***********************

    /// @notice Get the slashable balance for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @return slashableBalance The slashable balance
    function getSlashableBalance(
        CoreStorageLib.Data storage s,
        uint32 strategyId,
        address bApp,
        address token,
        ICore.Shares storage strategyTokenShares
    ) internal view returns (uint256 slashableBalance) {
        uint32 percentage = s.obligations[strategyId][bApp][token].percentage;
        uint256 balance = strategyTokenShares.totalTokenBalance;

        return (balance * percentage) / MAX_PERCENTAGE;
    }

    /// @notice Slash a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param percentage The amount to slash
    /// @param data Optional parameter that could be required by the service
    function slash(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 percentage,
        bytes calldata data
    ) external nonReentrant {
        _checkSlashingAllowed();

        ValidationLib.validatePercentageAndNonZero(percentage);

        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (!s.registeredBApps[bApp]) {
            revert IBasedAppManager.BAppNotRegistered();
        }

        ICore.Shares storage strategyTokenShares = s.strategyTokenShares[
            strategyId
        ][token];
        uint256 slashableBalance = getSlashableBalance(
            s,
            strategyId,
            bApp,
            token,
            strategyTokenShares
        );
        if (slashableBalance == 0) revert InsufficientBalance();
        uint256 amount = (slashableBalance * percentage) / MAX_PERCENTAGE;

        address receiver;
        bool exit;
        bool success;

        if (_isBApp(bApp)) {
            (success, receiver, exit) = IBasedApp(bApp).slash(
                strategyId,
                token,
                percentage,
                msg.sender,
                data
            );
            if (!success) revert IStrategyManager.BAppSlashingFailed();

            if (exit) _exitStrategy(s, strategyId, bApp, token);
            else
                _adjustObligation(
                    s,
                    strategyId,
                    bApp,
                    token,
                    amount,
                    strategyTokenShares
                );
        } else {
            // Only the bApp EOA or non-compliant bapp owner can slash
            if (msg.sender != bApp) revert InvalidBAppOwner(msg.sender, bApp);
            receiver = bApp;
            _exitStrategy(s, strategyId, bApp, token);
        }

        strategyTokenShares.totalTokenBalance -= amount;
        s.slashingFund[receiver][token] += amount;

        if (strategyTokenShares.totalTokenBalance == 0) {
            delete strategyTokenShares.totalTokenBalance;
            delete strategyTokenShares.totalShareBalance;
            strategyTokenShares.currentGeneration += 1;
        }

        emit IStrategyManager.StrategySlashed(
            strategyId,
            bApp,
            token,
            percentage,
            receiver
        );
    }

    function _exitStrategy(
        CoreStorageLib.Data storage s,
        uint32 strategyId,
        address bApp,
        address token
    ) private {
        s.obligations[strategyId][bApp][token].percentage = 0;

        emit IStrategyManager.ObligationUpdated(strategyId, bApp, token, 0);
    }

    function _adjustObligation(
        CoreStorageLib.Data storage s,
        uint32 strategyId,
        address bApp,
        address token,
        uint256 amount,
        ICore.Shares storage strategyTokenShares
    ) internal {
        ICore.Obligation storage obligation = s.obligations[strategyId][bApp][
            token
        ];
        uint256 currentStrategyBalance = strategyTokenShares.totalTokenBalance;
        uint256 currentObligatedBalance = (obligation.percentage *
            currentStrategyBalance) / MAX_PERCENTAGE;
        uint256 postSlashStrategyBalance = currentStrategyBalance - amount;
        uint256 postSlashObligatedBalance = currentObligatedBalance - amount;
        if (postSlashStrategyBalance == 0) {
            obligation.percentage = 0;
            emit IStrategyManager.ObligationUpdated(strategyId, bApp, token, 0);
        } else {
            uint32 postSlashObligationPercentage = uint32(
                (postSlashObligatedBalance / postSlashStrategyBalance) *
                    MAX_PERCENTAGE
            );
            obligation.percentage = postSlashObligationPercentage;
            emit IStrategyManager.ObligationUpdated(
                strategyId,
                bApp,
                token,
                postSlashObligationPercentage
            );
        }
    }

    /// @notice Withdraw the slashing fund for a token
    /// @param token The address of the token
    /// @param amount The amount to withdraw
    function withdrawSlashingFund(
        address token,
        uint256 amount
    ) external nonReentrant {
        if (token == ETH_ADDRESS) revert InvalidToken();

        _withdrawSlashingFund(token, amount);

        IERC20(token).safeTransfer(msg.sender, amount);

        emit IStrategyManager.SlashingFundWithdrawn(token, amount);
    }

    /// @notice Withdraw the slashing fund for ETH
    /// @param amount The amount to withdraw
    function withdrawETHSlashingFund(uint256 amount) external nonReentrant {
        _withdrawSlashingFund(ETH_ADDRESS, amount);

        (bool success, ) = payable(msg.sender).call{ value: amount }("");
        if (!success) revert WithdrawTransferFailed();

        emit IStrategyManager.SlashingFundWithdrawn(ETH_ADDRESS, amount);
    }

    /// @notice General withdraw code the slashing fund
    /// @param token The address of the token
    /// @param amount The amount to withdraw
    function _withdrawSlashingFund(address token, uint256 amount) internal {
        if (amount == 0) revert InvalidAmount();
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (s.slashingFund[msg.sender][token] < amount) {
            revert InsufficientBalance();
        }

        s.slashingFund[msg.sender][token] -= amount;
    }

    function _checkSlashingAllowed() internal view {
        if (
            ProtocolStorageLib.load().disabledFeatures & SLASHING_DISABLED != 0
        ) {
            revert SlashingDisabled();
        }
    }

    function _checkWithdrawalsAllowed() internal view {
        if (
            ProtocolStorageLib.load().disabledFeatures & WITHDRAWALS_DISABLED !=
            0
        ) {
            revert WithdrawalsDisabled();
        }
    }
}

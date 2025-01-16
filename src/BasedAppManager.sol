// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ICore.sol";
import "./interfaces/IBasedAppManager.sol";

/**
 * @title BasedAppManager
 * @notice Core contract to manage strategies, bApps, and obligations for SSV Based Apps.
 *
 * **************
 * ** GLOSSARY **
 * **************
 * @dev The following terms are used throughout the contract:
 *
 * - **Account**: An Ethereum address that can:
 *   1. Delegate its balance to another address.
 *   2. Create a strategy.
 *   3. Create a bApp.
 *
 * - **Delegator**: An Ethereum address that delegates its balance to a receiver.
 *   The delegator can be equal to the receiver, meaning the delegator delegates its balance to itself.
 *
 * - **Strategy**: A component that manages the delegated ERC20 tokens and has obligations to bApps.
 *
 * - **Obligation**: A percentage of the strategy's balance in ERC20 (or ETH) that is reserved for securing a bApp.
 *
 * - **BApp**: Accountable Validator BApp (AVS).
 *   A bApp is an entity that requests validation from strategies, requiring a minimum balance to operate.
 *
 * *************
 * ** AUTHORS **
 * *************
 * @author
 * Marco Tabasco
 * Riccardo Persiani
 */
contract BasedAppManager is Initializable, OwnableUpgradeable, UUPSUpgradeable, IBasedAppManager {
    using SafeERC20 for IERC20;

    uint32 public constant MAX_PERCENTAGE = 1e4;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant FEE_TIMELOCK_PERIOD = 7 days;
    uint256 public constant WITHDRAWAL_TIMELOCK_PERIOD = 5 days;
    uint256 public constant OBLIGATION_TIMELOCK_PERIOD = 7 days;
    uint256 public constant WITHDRAWAL_EXPIRE_TIME = 1 days;
    uint256 public constant FEE_EXPIRE_TIME = 1 days;
    uint256 public constant OBLIGATION_EXPIRE_TIME = 1 days;
    uint32 public constant MAX_FEE_INCREMENT = 500; // 5% // TODO set in the constructor...

    uint256 private _strategyCounter;

    /**
     * @notice Tracks the bApps created
     * @dev The bApp is identified with its address
     */
    mapping(address bApp => ICore.BApp) public bApps;
    /**
     * @notice Tracks the strategies created
     * @dev The strategy ID is incremental and unique
     */
    mapping(uint256 strategyId => ICore.Strategy) public strategies;
    /**
     * @notice Links an account to a single strategy for a specific bApp
     * @dev Guarantees that an account cannot have more than one strategy for a given bApp
     */
    mapping(address account => mapping(address bApp => uint256 strategyId)) public accountBAppStrategy;
    /**
     * @notice Tracks the percentage of validator balance a delegator has delegated to a specific receiver
     * @dev Each delegator can allocate a portion of their validator balance to multiple accounts including itself
     */
    mapping(address delegator => mapping(address account => uint32 percentage)) public delegations;
    /**
     * @notice Tracks the total percentage of validator balance a delegator has delegated across all receivers
     * @dev Ensures that a delegator cannot delegate more than 100% of their validator balance
     */
    mapping(address delegator => uint32 totalPercentage) public totalDelegatedPercentage;
    /**
     * @notice Tracks the token balances for individual strategies.
     * @dev Tracks that how much a token account has in a specific strategy
     */
    mapping(uint256 strategyId => mapping(address account => mapping(address token => uint256 balance))) public
        strategyTokenBalances;
    /**
     * @notice Tracks obligation percentages for a strategy based on specific bApps and tokens.
     * @dev Uses a hash of the bApp and token to map the obligation percentage for the strategy.
     */
    mapping(uint256 strategyId => mapping(address bApp => mapping(address token => uint32 obligationPercentage))) public
        obligations;
    /**
     * @notice Tracks unallocated tokens in a strategy.
     * @dev Count the number of bApps that have one obligation set for the token.
     * If the counter is 0, the token is unused and we can allow fast withdrawal.
     */
    mapping(uint256 strategyId => mapping(address token => uint32 bAppsCounter)) public usedTokens;
    /**
     * @notice Tracks all the withdrawal requests divided by token per strategy.
     * @dev User can have only one pending withdrawal request per token.
     *  Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint256 strategyId => mapping(address account => mapping(address token => ICore.WithdrawalRequest))) public
        withdrawalRequests;
    /**
     * @notice Tracks all the obligation change requests divided by token per strategy.
     * @dev Strategy can have only one pending obligation change request per token.
     * Only the strategy owner can submit one.
     * Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint256 strategyId => mapping(address token => mapping(address bApp => ICore.ObligationRequest))) public
        obligationRequests;

    mapping(uint256 strategyId => mapping(address bApp => uint32 numberOfObligations)) public obligationsCounter;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // *****************************************
    // ** Section: Delegate Validator Balance **
    // *****************************************

    /// @notice Function to delegate a percentage of the account's balance to another account
    /// @param receiver The address of the account to delegate to
    /// @param percentage The percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function delegateBalance(address receiver, uint32 percentage) external {
        if (percentage == 0 || percentage > MAX_PERCENTAGE) {
            revert ICore.InvalidPercentage();
        }

        if (delegations[msg.sender][receiver] != 0) {
            revert ICore.DelegationAlreadyExists();
        }

        if (totalDelegatedPercentage[msg.sender] + percentage > MAX_PERCENTAGE) {
            revert ICore.ExceedingPercentageUpdate();
        }

        delegations[msg.sender][receiver] = percentage;
        totalDelegatedPercentage[msg.sender] += percentage;

        emit DelegatedBalance(msg.sender, receiver, percentage);
    }

    /// @notice Function to update the delegated validator balance percentage to another account
    /// @param receiver The address of the account to delegate to
    /// @param percentage The updated percentage of the account's balance to delegate
    /// @dev The percentage is scaled by 1e4 so the minimum unit is 0.01%
    function updateDelegatedBalance(address receiver, uint32 percentage) external {
        if (percentage == 0 || percentage > MAX_PERCENTAGE) {
            revert ICore.InvalidPercentage();
        }

        uint32 existingPercentage = delegations[msg.sender][receiver];
        if (existingPercentage == percentage) {
            revert ICore.DelegationExistsWithSameValue();
        }
        if (existingPercentage == 0) {
            revert ICore.DelegationDoesNotExist();
        }

        uint32 newTotalPercentage = totalDelegatedPercentage[msg.sender] - existingPercentage + percentage;
        if (newTotalPercentage > MAX_PERCENTAGE) {
            revert ICore.ExceedingPercentageUpdate();
        }

        delegations[msg.sender][receiver] = percentage;
        totalDelegatedPercentage[msg.sender] = newTotalPercentage;

        emit DelegatedBalance(msg.sender, receiver, percentage);
    }

    /// @notice Function to remove delegation from an account
    /// @param receiver The address of the account to remove delegation from
    function removeDelegatedBalance(
        address receiver
    ) external {
        uint32 percentage = delegations[msg.sender][receiver];
        if (percentage == 0) {
            revert ICore.DelegationDoesNotExist();
        }

        // Clear delegation
        delegations[msg.sender][receiver] = 0;
        totalDelegatedPercentage[msg.sender] -= percentage;

        emit RemoveDelegatedBalance(msg.sender, receiver);
    }

    // ********************
    // ** Section: bApps **
    // ********************

    /// @notice Function to register a bApp
    /// @param owner The address of the owner
    /// @param bAppAddress The address of the bApp
    /// @param tokens The list of tokens the bApp accepts
    /// @param sharedRiskLevel The shared risk level of the bApp
    function registerBApp(
        address owner,
        address bAppAddress,
        address[] calldata tokens,
        uint32 sharedRiskLevel
    ) external {
        ICore.BApp storage bApp = bApps[bAppAddress];
        if (bApp.owner != address(0)) {
            revert ICore.BAppAlreadyRegistered();
        }
        bApp.owner = owner;
        bApp.sharedRiskLevel = sharedRiskLevel;

        for (uint256 i = 0; i < tokens.length; i++) {
            bApp.tokens.push(tokens[i]);
        }

        emit BAppRegistered(bAppAddress, owner, msg.sender);
    }

    /// @notice Function to add tokens to a bApp
    /// @param bAppAddress The address of the bApp
    /// @param tokens The list of tokens to add
    function addTokensToBApp(address bAppAddress, address[] calldata tokens) external {
        ICore.BApp storage bApp = bApps[bAppAddress];
        for (uint256 i = 0; i < tokens.length; i++) {
            for (uint256 j = 0; j < bApp.tokens.length; j++) {
                if (bApp.tokens[j] == tokens[i]) {
                    revert ICore.TokenAlreadyAddedToBApp(tokens[i]);
                }
            }
            bApp.tokens.push(tokens[i]);
        }
        emit BAppTokensUpdated(bAppAddress, tokens);
    }

    /// @notice Function to get the tokens for a bApp
    /// @param bAppAddress The address of the bApp
    function getBAppTokens(
        address bAppAddress
    ) external view returns (address[] memory) {
        return bApps[bAppAddress].tokens;
    }

    // ***********************
    // ** Section: Strategy **
    // ***********************

    /// @notice Function to create a new Strategy
    /// @return strategyId The ID of the new Strategy
    function createStrategy(
        uint32 fee
    ) external returns (uint256 strategyId) {
        if (fee > MAX_PERCENTAGE) {
            revert ICore.InvalidDelegationFee();
        }
        strategyId = ++_strategyCounter;

        ICore.Strategy storage newStrategy = strategies[strategyId];
        newStrategy.owner = msg.sender;
        newStrategy.fee = fee;

        emit StrategyCreated(strategyId, msg.sender);
    }

    /// @notice Opt-in to a bApp with a list of tokens and obligation percentages
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to opt-in with
    /// @param obligationPercentages The list of obligation percentages for each token
    function optInToBApp(
        uint256 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages
    ) external {
        if (tokens.length != obligationPercentages.length) revert ICore.TokensLengthNotMatchingPercentages();

        ICore.BApp storage existingBApp = bApps[bApp];
        matchTokens(tokens, existingBApp.tokens);

        // Check if a strategy exists for the given bApp
        // you cannot opt-in to the same bApp twice with the same strategy owner
        if (accountBAppStrategy[msg.sender][bApp] != 0) revert ICore.BAppAlreadyOptedIn();

        ICore.Strategy storage strategy = strategies[strategyId];
        if (strategy.owner != msg.sender) revert ICore.InvalidStrategyOwner(msg.sender, strategy.owner);

        emit BAppOptedIn(strategyId, bApp);

        _setObligations(strategyId, bApp, tokens, obligationPercentages);

        accountBAppStrategy[msg.sender][bApp] = strategyId;
    }

    /// @notice Deposit ERC20 tokens into the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to deposit
    function depositERC20(uint256 strategyId, IERC20 token, uint256 amount) external {
        if (amount == 0) revert ICore.InvalidAmount();

        strategyTokenBalances[strategyId][msg.sender][address(token)] += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit StrategyDeposit(strategyId, msg.sender, address(token), amount);
    }

    /// @notice Deposit ETH into the strategy
    /// @param strategyId The ID of the strategy
    function depositETH(
        uint256 strategyId
    ) external payable {
        if (msg.value == 0) revert ICore.InvalidAmount();

        strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] += msg.value;

        emit StrategyDeposit(strategyId, msg.sender, ETH_ADDRESS, msg.value);
    }

    /// @notice Withdraw ERC20 tokens from the strategy
    /// @param strategyId The ID of the strategy
    /// @param token The ERC20 token address
    /// @param amount The amount to withdraw
    function fastWithdrawERC20(uint256 strategyId, IERC20 token, uint256 amount) external {
        if (amount == 0) revert ICore.InvalidAmount();

        if (usedTokens[strategyId][address(token)] != 0) revert ICore.TokenIsUsedByTheBApp();

        // Check if the user has enough balance for the selected token
        if (strategyTokenBalances[strategyId][msg.sender][address(token)] < amount) revert ICore.InsufficientBalance();

        strategyTokenBalances[strategyId][msg.sender][address(token)] -= amount;

        token.safeTransfer(msg.sender, amount);

        emit StrategyWithdrawal(strategyId, msg.sender, address(token), amount);
    }

    /// @notice Withdraw ETH from the strategy
    /// @param strategyId The ID of the strategy
    /// @param amount The amount to withdraw
    function fastWithdrawETH(uint256 strategyId, uint256 amount) external {
        if (amount == 0) revert ICore.InvalidAmount();

        if (usedTokens[strategyId][ETH_ADDRESS] != 0) revert ICore.TokenIsUsedByTheBApp();

        if (strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] < amount) revert ICore.InsufficientBalance();

        strategyTokenBalances[strategyId][msg.sender][ETH_ADDRESS] -= amount;

        payable(msg.sender).transfer(amount);

        emit StrategyWithdrawal(strategyId, msg.sender, ETH_ADDRESS, amount);
    }

    /**
     * @notice Propose a withdrawal of ERC20 tokens from the strategy.
     * @param strategyId The ID of the strategy.
     * @param token The ERC20 token address.
     * @param amount The amount to withdraw.
     */
    function proposeWithdrawal(uint256 strategyId, address token, uint256 amount) external {
        if (amount == 0) revert ICore.InvalidAmount();

        if (strategyTokenBalances[strategyId][msg.sender][address(token)] < amount) revert ICore.InsufficientBalance();

        ICore.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][address(token)];

        request.amount = amount;
        request.requestTime = block.timestamp;

        emit WithdrawalProposed(
            strategyId, msg.sender, address(token), amount, block.timestamp + WITHDRAWAL_TIMELOCK_PERIOD
        );
    }

    /**
     * @notice Finalize the withdrawal after the timelock period has passed.
     * @param strategyId The ID of the strategy.
     * @param token The ERC20 token address.
     */
    function finalizeWithdrawal(uint256 strategyId, IERC20 token) external {
        ICore.WithdrawalRequest storage request = withdrawalRequests[strategyId][msg.sender][address(token)];
        if (block.timestamp < request.requestTime + WITHDRAWAL_TIMELOCK_PERIOD) {
            revert ICore.WithdrawalTimelockNotElapsed();
        }

        if (block.timestamp > request.requestTime + WITHDRAWAL_TIMELOCK_PERIOD + WITHDRAWAL_EXPIRE_TIME) {
            revert ICore.WithdrawalExpired();
        }

        uint256 amount = request.amount;
        // if (amount == 0) revert ICore.InvalidAmount(); todo check if not necessary?

        strategyTokenBalances[strategyId][msg.sender][address(token)] -= amount;

        delete withdrawalRequests[strategyId][msg.sender][address(token)];

        token.safeTransfer(msg.sender, amount);

        emit WithdrawalFinalized(strategyId, msg.sender, address(token), amount);
    }

    // TODO: add eth proposeWithdrawal and finalizeWithdrawal

    /// @notice Set the obligation percentages for a strategy
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to set obligations for
    /// @param obligationPercentages The list of obligation percentages for each token
    function _setObligations(
        uint256 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages
    ) private {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint32 obligationPercentage = obligationPercentages[i];

            if (obligationPercentage == 0 || obligationPercentage > MAX_PERCENTAGE) revert ICore.InvalidPercentage();

            obligations[strategyId][bApp][token] = obligationPercentage;
            obligationsCounter[strategyId][bApp] += 1;
            usedTokens[strategyId][token] += 1;

            emit BAppObligationSet(strategyId, bApp, token, obligationPercentage);
        }
    }

    /// @notice Add a new obligation for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function createObligation(uint256 strategyId, address bApp, address token, uint32 obligationPercentage) external {
        if (strategies[strategyId].owner != msg.sender) {
            revert ICore.InvalidStrategyOwner(msg.sender, strategies[strategyId].owner);
        }
        // todo maybe not allow to create a 0 percentage obligation?
        if (obligationPercentage > MAX_PERCENTAGE) revert ICore.InvalidPercentage();
        if (obligations[strategyId][bApp][token] != 0) revert ICore.ObligationAlreadySet();

        // TODO Check the implications, what if a strategy is create and then the obligation deleted? This could block the strategy
        // todo use another method to check if a strategyWasOptedIn?
        // TODO allow obligation to be 0 but still be counted?
        if (obligationsCounter[strategyId][bApp] == 0) revert ICore.BAppNotOptedIn();

        address[] storage bAppTokens = bApps[bApp].tokens;
        matchToken(token, bAppTokens);

        obligations[strategyId][bApp][token] = obligationPercentage;
        accountBAppStrategy[msg.sender][bApp] = strategyId;
        usedTokens[strategyId][token] += 1;
        obligationsCounter[strategyId][bApp] += 1;

        emit BAppObligationSet(strategyId, bApp, token, obligationPercentage);
    }

    /// @notice Fast set obligation ratio higher for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param obligationPercentage The obligation percentage
    function fastUpdateObligation(
        uint256 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external {
        if (strategies[strategyId].owner != msg.sender) {
            revert ICore.InvalidStrategyOwner(msg.sender, strategies[strategyId].owner);
        }
        if (obligationPercentage > MAX_PERCENTAGE) revert ICore.InvalidPercentage();
        if (obligationPercentage <= obligations[strategyId][bApp][token]) revert ICore.InvalidPercentage();

        obligations[strategyId][bApp][token] = obligationPercentage;

        emit BAppObligationUpdated(strategyId, bApp, token, obligationPercentage);
    }

    /**
     * @notice Propose a withdrawal of ERC20 tokens from the strategy.
     * @param strategyId The ID of the strategy.
     * @param token The ERC20 token address.
     * @param obligationPercentage The new percentage of the obligation
     */
    function proposeUpdateObligation(
        uint256 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external {
        if (strategies[strategyId].owner != msg.sender) {
            revert ICore.InvalidStrategyOwner(msg.sender, strategies[strategyId].owner);
        }
        if (obligationPercentage > MAX_PERCENTAGE) revert ICore.InvalidPercentage();

        ICore.ObligationRequest storage request = obligationRequests[strategyId][bApp][token];

        request.percentage = obligationPercentage;
        request.requestTime = block.timestamp;

        emit ObligationUpdateProposed(
            strategyId,
            msg.sender,
            address(token),
            obligationPercentage,
            request.requestTime + OBLIGATION_TIMELOCK_PERIOD
        );
    }

    /**
     * @notice Finalize the withdrawal after the timelock period has passed.
     * @param strategyId The ID of the strategy.
     * @param bApp The address of the bApp.
     * @param token The ERC20 token address.
     */
    function finalizeUpdateObligation(uint256 strategyId, address bApp, address token) external {
        if (strategies[strategyId].owner != msg.sender) {
            revert ICore.InvalidStrategyOwner(msg.sender, strategies[strategyId].owner);
        }

        ICore.ObligationRequest storage request = obligationRequests[strategyId][bApp][address(token)];
        uint256 requestTime = request.requestTime;
        uint32 percentage = request.percentage;

        if (requestTime == 0) revert ICore.NoPendingObligationUpdate();

        if (block.timestamp < request.requestTime + OBLIGATION_TIMELOCK_PERIOD) {
            revert ICore.ObligationTimelockNotElapsed();
        }

        if (block.timestamp > request.requestTime + OBLIGATION_TIMELOCK_PERIOD + OBLIGATION_EXPIRE_TIME) {
            revert ICore.UpdateObligationExpired();
        }
        // Remove the obligation if the percentage is 0
        if (percentage == 0) {
            usedTokens[strategyId][address(token)] -= 1;
            // obligationsCounter[strategyId][bApp] -= 1; // todo: consider to not decrement and keep it there as sign that was opted in and can update in future instead of recreating // double check over the codebase
        }

        obligations[strategyId][bApp][address(token)] = percentage;

        emit ObligationUpdateFinalized(strategyId, msg.sender, address(token), percentage);

        // TODO: maybe empty the request structure or not needed to save gas?
        // delete obligationRequests[strategyId][bApp][address(token)];
    }

    /// @notice Propose a new fee for a strategy
    /// @param strategyId The ID of the strategy
    /// @param proposedFee The proposed fee
    function proposeFeeUpdate(uint256 strategyId, uint32 proposedFee) external {
        if (strategies[strategyId].owner != msg.sender) {
            revert ICore.InvalidStrategyOwner(msg.sender, strategies[strategyId].owner);
        }
        if (proposedFee > MAX_PERCENTAGE) revert ICore.InvalidPercentage();

        ICore.Strategy storage strategy = strategies[strategyId];
        uint32 fee = strategy.fee;

        if (proposedFee > fee + MAX_FEE_INCREMENT) revert ICore.InvalidPercentageIncrement();
        if (proposedFee == fee) revert ICore.FeeAlreadySet();

        strategy.feeProposed = proposedFee;
        strategy.feeUpdateTime = block.timestamp + FEE_TIMELOCK_PERIOD;

        emit StrategyFeeUpdateRequested(strategyId, msg.sender, proposedFee, fee, strategy.feeUpdateTime);
    }

    /// @notice Finalize the fee update for a strategy
    /// @param strategyId The ID of the strategy
    function finalizeFeeUpdate(
        uint256 strategyId
    ) external {
        ICore.Strategy storage strategy = strategies[strategyId];
        if (strategy.owner != msg.sender) {
            revert ICore.InvalidStrategyOwner(msg.sender, strategy.owner);
        }

        uint256 feeUpdateTime = strategy.feeUpdateTime;

        if (block.timestamp < feeUpdateTime) revert ICore.FeeTimelockNotElapsed();

        if (block.timestamp > feeUpdateTime + FEE_EXPIRE_TIME) {
            revert ICore.FeeUpdateExpired();
        }

        uint32 oldFee = strategy.fee;
        strategy.fee = strategy.feeProposed;
        strategy.feeProposed = 0;
        strategy.feeUpdateTime = 0;

        emit StrategyFeeUpdated(strategyId, msg.sender, strategy.fee, oldFee);
    }

    // **********************
    // ** Section: Helpers **
    // **********************

    // Match the tokens of strategy with the bApp
    // Complexity: O(n * m)
    function matchTokens(address[] calldata tokens, address[] memory bAppTokens) internal pure {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            matchToken(token, bAppTokens);
        }
    }

    function matchToken(address token, address[] memory bAppTokens) internal pure {
        bool matched = false;
        for (uint256 i = 0; i < bAppTokens.length; ++i) {
            address bAppToken = bAppTokens[i];
            if (bAppToken == token) {
                matched = true;
                break;
            }
        }
        if (!matched) revert ICore.TokenNoTSupportedByBApp(token);
    }

    // ********************************
    // ** Section: Not Supported yet **
    // ********************************
    // todo: createNativeETHObligation

    // TODO: this function is not used now, but could be useful in the future if the bApp can remove supported tokens.

    /// @notice Remove obligation for a bApp
    /// @param strategyId The ID of the strategy
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    // function fastRemoveObligation(uint256 strategyId, address bApp, address token) external {
    //     require(strategies[strategyId].owner == msg.sender, "Not the strategy owner");
    //     require(obligations[strategyId][bApp][token] > 0, "Obligation not set");

    //     for (uint256 i = 0; i < bApps[bApp].tokens.length; i++) {
    //         if (bApps[bApp].tokens[i] == token) {
    //             revert("token is used by the bApp");
    //         }
    //     }

    //     obligations[strategyId][bApp][token] = 0;
    //     usedTokens[strategyId][token] -= 1;
    //     obligationsCounter[strategyId][bApp] -= 1;

    //     emit BAppObligationUpdated(strategyId, bApp, token, 0);
    //     // todo: create a new event for removedObligation?
    // }
}

# bApp Onboarding Guide

This guide outlines the steps for based applications creators looking to build on the bApps platform.

## 1. Creating and Configuring a bApp

1. **Define core attributes**:
- `bApp`: a unique 20-byte address that uniquely identifies the bApp.
- `tokens`:  A list of ERC-20 tokens to be used in the bApp's security mechanism. For ETH, use the special address [`0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L62).
- `sharedRiskLevels`: a list with $\beta$ values, one for each token, representing the bApp's tolerance for risk (token over-usage).
2. **Optional Non-Slashable Validator Balance**: If the bApp uses non-slashable validator balance, it should be configured off-chain, in the bApp's network.
3. **Register the bApp**: Use the [`registerBApp`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L249) function of the smart contract:
```solidity
function registerBApp(
   address bApp,
   address[] calldata tokens,
   uint32[] calldata sharedRiskLevels,
   string calldata metadataURI
)
```
- `metadataURI`: Additional information about your bApp (e.g., a website).
4. **Update Configuration**: After registratering, the bApp configuration can be updated by the `owner` account.

## 2. Securing the bApp

Once the bApp is registered, strategies can join it and allocate capital to secure it.

### 2.1 Opting in

The strategy opts in to the bApp by using the [`optInToBApp`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L333) function of the smart contract:
```solidity
function optInToBApp(
   uint256 strategyId,
   address bApp,
   address[] calldata tokens,
   uint32[] calldata obligationPercentages,
   bytes calldata data
)
```
- `tokens`: List of tokens to obligate to the bApp.
- `obligationPercentages`: The proportion of each token's balance to commit to the bApp.
- `data`: An extra optional field for off-chain information required by the bApp for participation.

For example, if `tokens = [SSV]` and `obligationPercentages = [50%]`, then 50% of the strategy's `SSV` balance will be obligated to the bApp.

### 2.2 Strategy's Funds

To compose the their balances, strategies:
1. receive ERC20 (or ETH) via [**deposits**](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L376) from accounts.
2. inherent the non-slashable validator balance from its owner account. Accounts [**delegate**](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L201) validator balances between themselves, and the strategy inherits its owner's non-delegated balance plus the received balances from other accounts.

## 3. Participant Weight

bApp clients track the weight of each participant in the bApp. For that, clients will:

1. **Gather Obligated Balances**: First, for each token used by the bApp, it should get the obligated balance from each strategy.
```go
ObligatedBalance map[Token]map[Strategy]Amount
```
2. **Sum Obligations**: From `ObligatedBalance`, it can sum all obligations and compute the total amount obligated to the bApp by all strategies.
```go
TotalBAppBalance map[Token]Amount
```
3. **Calculate Risk**: For each token, it should get the risk (token-over usage) of each strategy.
```go
Risk map[Token]map[Strategy]float64
```
4. **Compute Risk-Aware Weights**: With this information, it can compute the weight of a participant for a certain token by

$$W_{\text{strategy, token}} = c_{\text{token}} \times \frac{ObligatedBalance[\text{token}][\text{strategy}]}{TotalBAppBalance[\text{token}]} e^{-\beta_{\text{token}} \times max(1, Risk[\text{token}][\text{strategy}])}$$

where $c_{\text{token}}$ is a normalization constant defined as

$$c_{\text{token}} = \left( \sum_{\text{strategy}} \frac{ObligatedBalance[\text{token}][\text{strategy}]}{TotalBAppBalance[\text{token}]} e^{-\beta_{\text{token}} \times max(1, Risk[\text{token}][\text{strategy}])} \right)^{-1}$$


> [!NOTE]
> If the bApp uses validator balance, the client should also read a `map[Strategy]ValidatorBalance` with the amount from each strategy. As this capital doesn't involve any type of risk, all risk values can be set to 0. Thus, for this capital, this is equivalent to
> $$W_{\text{strategy, validator balance}} = \frac{ObligatedBalance[\text{validator balance}][\text{strategy}]}{TotalBAppBalance[\text{validator balance}]}$$


5. **Combine into the Final Weight**: With the per-token weights, the final step is to compute a final weight for the participant using a **combination function**. Such function is defined by the bApp and can be tailored to its specific needs. Traditional examples include the arithmetic mean, geometric mean, and harmonic mean.


**Example**: Let's consider a bApp that uses tokens $A$ and $B$, and considers $A$ to be twice as important as $B$. Then, it could use the following weighted harmonic mean as its combination function:

$$W^{\text{final}}_{\text{strategy}} = c_{\text{final}} \times \frac{1}{\frac{2/3}{W_{\text{strategy, A}}} + \frac{1/3}{W_{\text{strategy, B}}}}$$

where $c_{\text{final}}$ is a normalization constant computed as

$$c_{\text{final}} = \left( \sum_{\text{strategy}} \frac{1}{\frac{2/3}{W_{\text{strategy, A}}} + \frac{1/3}{W_{\text{strategy, B}}}} \right)^{-1}$$


### 3.1 Fecthing obligated balances, validator balances, and risks

**Map of obligation balances**

```r
function ObligatedBalances(bApp)
   obligatedBalances = New(Map<Token, Map<Strategy, Amount>>)

   # Get bApp tokens
   bAppTokens = api.GetbAppTokens(bApp)

   # Loop through every strategy
   strategies = api.GetStrategies()
   for strategy in strategies do

      # Check if strategy participates in the bApp
      if !api.StrategyOptedInToBApp(strategy, bApp) then
         # If not, continue
         continue

      # Get strategy balance
      balance = api.GetStrategyBalance(strategy)

      # Add obligated balance for each bApp token
      for token in bAppTokens do
         obligationPercentage = api.GetObligation(strategy, bApp, token)
         obligatedBalances[token][strategy] = obligationPercentage * balance[token]

   return obligatedBalances
```

**Map of validator balances**

```r
function ValidatorBalances(bApp)
   validatorBalances = New(Map<Strategy, Amount>)

   # Loop through every strategy
   strategies = api.GetStrategies()
   for strategy in strategies do

      # Check if strategy participates in the bApp
      if !api.StrategyOptedInToBApp(strategy, bApp) then
         # If not, continue
         continue

      # Get account that owns the strategy
      ownerAccount = api.GetStrategyOwnerAccount(strategy)

      # Store validator balance
      validatorBalances[strategy] = ComputeEffectiveValidatorBalance(ownerAccount)

   return obligatedBalances


function ComputeEffectiveValidatorBalance(account)

   total = 0

   # Gets the percentage that the account delegated to others
   percentageDelegatedToOthers = api.GetTotalDelegation(account)

   # Add non-delegated validator balance
   accountsOriginalValidatorBalance = GetOriginalValidatorBalance(account)
   total += accountsOriginalValidatorBalance * (1 - percentageDelegatedToOthers)

   # Get all other accounts that delegated to it along with the percentages
   delegatorsToAccount = New(Map<Account, Percentage>)
   delegatorsToAccount = api.GetDelegatorsToAccount(account)

   # Add the delegated balances
   for delegator, percentage in delegatorsToAccount
      total += GetOriginalValidatorBalance(delegator) * percentage

   return total


function GetOriginalValidatorBalance(account)

   total = 0

   # Get SSV validators from account
   validatorsPubKeys = SSVNode.GetValidatorsPubKeys(account)

   for PubKey in validatorsPubKeys
      # Get validator balance and active status
      balance, isActive = ETHNode.GetValidatorBalance(PubKey)

      if isActive
         total += balance

   return total
```

**Map of risks**

```r
function Risks(bApp)
   risks = New(Map<Token, Map<Strategy, Percentage>>)

   # Get bApp tokens
   bAppTokens = api.GetbAppTokens(bApp)

   # Loop through every strategy
   strategies = api.GetStrategies()
   for strategy in strategies do

      # Check if strategy participates in the bApp
      if !api.StrategyOptedInToBApp(strategy, bApp) then
         # If not, continue
         continue

      # Store risk (i.e. sum of all obligation percentages)
      risks[token][strategy] = api.AddAllObligationsForToken(strategy, token)

   return risks
```

**API Calls**

For reference, we list the API calls used in the above snippets along with the chain state variables that should be read for each call.
- `GetbAppTokens(bApp)`: [`bAppTokens`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L84)
- `GetStrategies()`: [`strategies`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L89)
- `StrategyOptedInToBApp(strategy, bApp)`: [`accountBAppStrategy`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L94)
- `GetStrategyBalance(strategy)`: [`strategyTokenBalances`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L109)
- `GetObligation(strategy, bApp, token)`: [`obligations`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L115)
- `GetStrategyOwnerAccount(strategy)`: [`strategies`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L89)
- `GetTotalDelegation(account)`: [`totalDelegatedPercentage`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L104)
- `GetDelegatorsToAccount(account)`: [`delegations`](https://github.com/ssvlabs/based-applications/blob/92a5d3d276148604e3fc087c1c121f78b136a741/src/BasedAppManager.sol#L99)

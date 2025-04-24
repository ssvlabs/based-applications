# WhitelistExample
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/middleware/examples/WhitelistExample.sol)

**Inherits:**
[OwnableBasedApp](/src/middleware/modules/core+roles/OwnableBasedApp.sol/abstract.OwnableBasedApp.md), [BasedAppWhitelisted](/src/middleware/modules/BasedAppWhitelisted.sol/abstract.BasedAppWhitelisted.md)


## Functions
### constructor


```solidity
constructor(address _basedAppManager, address _initOwner) OwnableBasedApp(_basedAppManager, _initOwner);
```

### optInToBApp


```solidity
function optInToBApp(uint32 strategyId, address[] calldata, uint32[] calldata, bytes calldata)
    external
    view
    override
    onlySSVBasedAppManager
    returns (bool success);
```


## About Safe Guards

Safe Guards are used when there are restrictions on top of the n-out-of-m scheme.
Safe Guards can make checks before and after a Safe transaction. The check before a transaction can programmatically check all the parameters of the respective transaction before execution. The check after a transaction is called at the end of the transaction execution and can be used to perform checks on the final state of the Safe.

## This Safe Guard

Is intended to grant certain owners of a Safe, special authority to execute certain functions.    
By default the following functions are restricted to be executed only by "super" users:  
``` 
// From @safe-contracts/contracts/base/OwnerManager.sol
// cast sig 'addOwnerWithThreshold(address,uint256)'
bytes4 internal constant addOwnerWithThreshold = 0x0d582f13;
// cast sig 'removeOwner(address,address,uint256)'
bytes4 internal constant removeOwner = 0xf8dc5dd9;
// cast sig 'swapOwner(address,address,address)'
bytes4 internal constant swapOwner = 0xe318b52b;
// cast sig 'changeThreshold(uint256)'
bytes4 internal constant changeThreshold = 0x694e80c3;
// cast sig 'setSuperOwner(address,bool)'

// From src/contracts/SuperOwnerGuard.sol
bytes4 internal constant setSuperOwner = 0xf282e9ff;
// cast sig 'setSuperRestrictedSelector(bytes4,bool)'
bytes4 internal constant setSuperRestrictedSelector = 0x2bcf063a;
```
This allows the "super" user to remain in control of the Safe signers, while delegating all other functions of the safe to the other non-super users.

## Factory

Create your guard via the factory on Sepolia: 0xF24872F41F6d14904C3781D39E864D9555857A3e.   

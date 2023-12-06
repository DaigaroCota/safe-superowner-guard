## About Safe Guards

Safe Guards are used when there are restrictions on top of the n-out-of-m scheme.
Safe Guards can make checks before and after a Safe transaction. The check before a transaction can programmatically check all the parameters of the respective transaction before execution. The check after a transaction is called at the end of the transaction execution and can be used to perform checks on the final state of the Safe.

## This Safe Guard

Is intended to grant certain owners of a Safe, special authority to execute certain functions.    
By default the following functions are restricted to be executed only by the "super" users:  
``` 
/*
 * @dev From @safe-contracts/contracts/base/OwnerManager.sol
 */

// cast sig 'addOwnerWithThreshold(address,uint256)'
bytes4 internal constant addOwnerWithThreshold = 0x0d582f13;

// cast sig 'removeOwner(address,address,uint256)'
bytes4 internal constant removeOwner = 0xf8dc5dd9;

// cast sig 'swapOwner(address,address,address)'
bytes4 internal constant swapOwner = 0xe318b52b;

// cast sig 'changeThreshold(uint256)'
bytes4 internal constant changeThreshold = 0x694e80c3;

/*
 * @dev From src/contracts/SuperOwnerGuard.sol
 *
 */

// cast sig 'setSuperOwner(address,bool)'
bytes4 internal constant setSuperOwner = 0xf282e9ff;

// cast sig 'setSuperRestrictedSelector(bytes4,bool)'
bytes4 internal constant setSuperRestrictedSelector = 0x2bcf063a;
```
This allows the "super" user to remain in control of the Safe signers, while delegating all other functions of the Safe to the other non-super users.

## Factory

Create your guard via the factory contract:    
   

| Chain    | Factory address                                             |
|----------|-------------------------------------------------------------|
|Sepolia   |0x2A80DF2Ab893fa02191d8A9Af1061A5554F4fDAD                   |


## Steps to set-up guard

These steps assume you already have a Safe deployed and at least 1 signer with 1:1 signatures threshold.   
If you already have a guard set-up in your Safe you will have to remove it. See steps on how to remove a guard [here]().   

1. Identify the factory contract in the chain you want to set this guard.
2. In the factory contract call method `createGuard`. You will need the address of the Safe, and an array of users to become "super" users.
3. Once you deploy your guard, you will need to set it as the active guard in your Safe. To do this, use Safe's transaction builder to self-call the Safe's method `setGuard(address)`. The address is the guard created in Step 2.
4. Collect the required signatures and execute the transaction. Once your transaction is confirmed, only the "super" owners will be able to execute changes to the signers of the Safe.


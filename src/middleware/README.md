## Explain

## have 

another modules example to showcase on how to use thte data structure, called bls strategy that extend opt in function and you do the BLS signature verification (100k gas).
30-40 operators. explain these concepts but we need to have it.
ALSO we want ECDSA(2-3k gas)
think these examples in terms of security. if someone provide bls data, we don't want replay attack, be careful on security. 
in that module we need to verify that is valid but also we allow unique public key (maybe use salt). 
if we use BLS i don't want to allow more than one strategy with the same owner/bls. just like we do on the ssv based app manager. 

we don't weant jsut a function for verification.

last function is: bapp with EOA initially, then I want to update to a contract. Viceversa? (potentially). 

also think about other interesting ideas, real world use cases. 

I want next week progresses, connect with Othentic and share the progresses. 
Get some feedback, and help them and get help. 

----

// todo: whitelist strategy/ whitelist manager - these are other examples

// maybe this could be abstract and become a module

// have modules not examples...

// another module is capped strategies, ex: limit how much capital people can put in me. for example up to 100k SSV.
// function opt in to bapp we hook delegate deposit. we can have see the balance.
// pause module additional.
// but let's try to do it on chain.
// check on-chain hte balance.
// some bapps don't want more that 100k ssv for example cause they don't want to pay more rewards


    // TODO split this contract in modules

// instead of the owner, just go the bApp address, pass the msg.sender to whitelistManager and if true, you allow to do manager

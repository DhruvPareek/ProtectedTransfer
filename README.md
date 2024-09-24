# SafeTransactions
Transfer eth or tokens from one address to another in a protected manner. This contract is helpful to prevent burning tokens to the wrong address during a transaction. A sender creates a transaction with a secret, then only the intended recipient can claim the eth or tokens from the transaction.

A sender can call the sendEth() function with the intended recipient's address and a secret string. The sender should then share this secret string with the intended recipient. The recipient can claim the eth from the transaction by calling the claimEth() function with the sender's address and the secret string.

If the sender accidentally directed the transaction to the wrong address, they can use the cancelSendEth() function to cancel the transaction and redeem the Eth. The cancelSendEth() function must be called with the incorrectly entered original recipient address and the secret string. The sender can view the emitted EthTxCreated event from sendEth() to see the incorrect recipient address and verify the secret with the emitted secret hash.

An incorrecty addressed recipient will not be able to claim your tokens. Since only the sender and the intended recipient should know the secret, it is impossible for anyone else to claim the eth. The misdirected eth will sit in the smart contract until the original sender cancels the transaction.

This smart contract also supports the same functionality for ERC20 tokens with the functions sendToken, cancelSendToken, claimToken. All of these functions also require the ERC20's contract address as a parameter.

Frontend --> 

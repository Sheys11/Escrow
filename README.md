# Escrow
An Escrow Contract for a crypto-fiat on-ramp & off-ramp P2P exchange.

## Contract Logic
This contract logic centers around a simple escrow contract with a supply receive, and withdraw functions to enable successful transactions which includes the deposition and withdrawal of funds by both buyers and merchants.

The supply function recieves buyer's transaction details in encoded bytes32 hashes through the frontend and is stored on-chain. In order for a merchant to receive a particular buyer's funds, the same bytes32 hash - alongside other values(buyer's address, transaction Id, amounts, and the traded token address)- must be passed to the function. Inside the receive function, the parameters are compared with the existing stored values on-chain to verify the supplied variables before the token values are transferred to the merchant.

The withdrawal function will also allow the buyer to retrieve their funds incase of any defaults by the merchants.

This contract has no trustless mechanism as it is currently impossible to track real world fiat transactions on-chain. So it's expected to have a centralised fintech app built on it to pass these messages into it's database and reuse it for the retrieval of merchants funds. This would give the creators a choice to either self-fufill the fiat transactions automatedly or use a very efficient order-matching system.

## Contributions
I would love any contribution to this as this is just a simple proof of concept!
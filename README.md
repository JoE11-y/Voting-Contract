# Voting-Contract
Tezos Tacode Submission

This is a Voting contract built with Cameligo for the Tezos blockchain, in this contract there are two entry points, the init entrypoint and the voting entrypoint.
The admin is the one that can call the init entrypoint and he passes in an array of names, from which the names for the candidates map are gotten and their respective votes counts set to zero.
While other users can access the contract with the voting entrypoint, where they are required to have at least 0.5tz before they can vote as the fee. There are several checks put in place to ensure there is no double voting and all the users have to pass in is the name of the candidate they wish to vote.

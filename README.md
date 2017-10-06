# atlant-dao-contracts

<p align="center">
<img src="https://user-images.githubusercontent.com/12106540/29994000-3d005684-8fce-11e7-97ea-a16a6c607a3f.png" />
</p>

**Platform tokenholders DAO**

ATLANT DAO and property tokenization platform implemented as smart contracts written in Solidity language (Ethereum) using Truffle framework.

# Supported functionality
## Property platform
* Adding properties for sale
* Property approval/rejection by lawyer
* PTO initialization

## DAO
* Changing voting rules (debate time, minimum quorum)
* Proposing a new percent fee for new PTOs
* Voting and proposal execution

## PTO
* Refunds in case of PTO cancellation
* Property token distibution to ATL token holders

## How to launch and test Solidity contracts
* Run "./testrpc.sh" in Command Line
* Open Git Bash or any othe command line tool and run "truffle compile" from the project directory
* Run "truffle test" to run existing tokenization tests

**Commands list**
```
./testrpc.sh
truffle compile
truffle test
```

Built with Truffle and OpenZeppelin.

Published under MIT license.

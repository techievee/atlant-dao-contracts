pragma solidity ^0.4.11;

import "./installed/token/StandardToken.sol";

contract MockToken is StandardToken {
    function setBalance(uint _value) {
        balances[msg.sender] = _value;
				totalSupply += _value;
    }
}

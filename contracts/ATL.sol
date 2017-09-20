pragma solidity ^0.4.11;

import "./installed/token/StandardToken.sol";

contract ATL{
  mapping (address => uint256) public balanceOf;
	uint public totalSupply;
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

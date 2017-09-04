pragma solidity ^0.4.11;

contract ATL {
    mapping (address => uint256) public balanceOf;
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}

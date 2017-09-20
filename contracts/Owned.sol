pragma solidity ^0.4.11;

//contract defining ownership
contract owned {
    address public owner;

		//constructor
    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

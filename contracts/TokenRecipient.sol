pragma solidity ^0.4.11;

//contract that defines token ownership transfer
contract tokenRecipient {
    event receivedEther(address sender, uint amount);
    event receivedTokens(address _from, uint256 _value, address _token, bytes _extraData);

    function () payable {
        receivedEther(msg.sender, msg.value);
    }
}

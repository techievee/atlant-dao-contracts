pragma solidity ^0.4.11;

import "./PropertyToken.sol";
import "./TokenRecipient.sol";

/* The property shareholder association contract*/
contract PropertyAssociation is tokenRecipient{

    /* Contract Variables and events */
    PropertyToken public propertyTokenAddress;

    /* modifier that allows only shareholders to vote and create new proposals */
    modifier onlyShareholders {
        require (propertyTokenAddress.balanceOf(msg.sender) > 0);
        _;
    }

    /* First time setup */
    function PropertyAssociation(PropertyToken tokenAddress) {
			propertyTokenAddress = PropertyToken(tokenAddress);
    }
}

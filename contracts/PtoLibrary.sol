pragma solidity ^0.4.11;

import "./Pto.sol";

library PtoLib {
	function createPto(address owner, uint ptoFee, uint propertyID, address lawyerAddress) {
		new PTO(owner, ptoFee, propertyID, lawyerAddress);
	}
}

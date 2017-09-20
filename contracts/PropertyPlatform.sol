pragma solidity ^0.4.11;

import "./TokenRecipient.sol";
import "./PtoLibrary.sol";

contract PropertyPlatform is tokenRecipient{
    //Lawyer[] lawyers; //there will be an array of lawyers in the future
		Lawyer public lawyer;
		Property[] properties;

		event PropertyAdded(string propertyName, uint propertyPrice, uint propertyArea);
		event PropertyApproved(uint propertyId, bool approved);

		struct Lawyer {
			string name;
			uint fee;
			address lawyerAddress;
		}

		struct Property {
			string name;
			uint price;
			uint area;
			Lawyer assignedLawyer;
			address seller;
			//PTO pto;
			bool approved;
			bool lawyerReviewed;
		}

		//constructor
    function PropertyPlatform(string lawyerName, uint lawyerFee, address lawyerAddress) {
			lawyer.name = lawyerName;
			lawyer.fee = lawyerFee;
			lawyer.lawyerAddress = lawyerAddress;
    }

		//function to view prperties for sale
		function viewProperty(uint propertyID) constant
		returns (string name, uint price, uint area, address seller, bool lawyerReviewed, bool approved) {
			Property storage prop = properties[propertyID];
			return (prop.name, prop.price, prop.area, prop.seller, prop.lawyerReviewed, prop.approved);
		}

		function addPropertyForSale(string propertyName, uint propertyPrice, uint propertyArea, bool propertyIsOK) payable returns (uint propertyID)  {
			require(propertyIsOK == true); //placeholder for property checks

			propertyID = properties.length++;
			Property storage p = properties[propertyID];
			p.assignedLawyer = lawyer;
			require(msg.value == (p.assignedLawyer.fee * 1 ether)); //check property seller has sent enough money to pay fee

			p.name = propertyName;
			p.price = propertyPrice;
			p.area = propertyArea;
			p.seller = msg.sender;

			PropertyAdded(propertyName, propertyPrice, propertyArea);
		}

		function approveProperty(uint propertyID, bool approved) {
			Property storage p = properties[propertyID];
			require (p.assignedLawyer.lawyerAddress == msg.sender);

			//prevent double spending on lawyer
			if (!p.lawyerReviewed) {
				p.assignedLawyer.lawyerAddress.transfer(p.assignedLawyer.fee * 1 ether); //pay the lawyer
				p.lawyerReviewed = true;
			}
			p.approved = approved;

			PropertyApproved(propertyID, approved);
		}

		function launchPTO(uint propertyID, uint ptoFee) internal {
			Property storage p = properties[propertyID];
			require(p.seller == msg.sender && p.approved);
			PtoLib.createPto(p.seller, ptoFee, propertyID, p.assignedLawyer.lawyerAddress);
		}
}

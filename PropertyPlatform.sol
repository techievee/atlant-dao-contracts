pragma solidity ^0.4.11;

import "./TokenRecipient.sol";

contract PropertyPlatform is tokenRecipient{
    //Lawyer[] lawyers; //there will be an array of lawyers in the future
		Lawyer public lawyer;
		Property[] properties;

		event PropertyAdded(string propertyName, uint propertyPrice, uint propertyArea);

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
		}

		//constructor
    function PropertyPlatform(string lawyerName, uint lawyerFee, address lawyerAddress) {
			lawyer.name = lawyerName;
			lawyer.fee = lawyerFee;
			lawyer.lawyerAddress = lawyerAddress;
    }

		//function to view prperties for sale
		function viewProperty(uint propertyID) constant returns (string name, uint price, uint area){
			Property storage prop = properties[propertyID];
			return (prop.name, prop.price, prop.area);
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

			p.assignedLawyer.lawyerAddress.transfer(p.assignedLawyer.fee * 1 ether); //pay the lawyer
			PropertyAdded(propertyName, propertyPrice, propertyArea);
		}
}

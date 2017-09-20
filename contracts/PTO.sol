pragma solidity ^0.4.11;

import "./installed/token/ERC20.sol";
import "./PropertyToken.sol";
import "./PropertyDAO.sol";
import "./ATL.sol";

contract PTO {

  uint public constant TOKEN_PRICE = 100; // min propertyToken per ETH
  uint public constant TOKENS_FOR_SALE = 50 * 1e18;
	uint public PTO_FEE;
	uint RESERVE_RATE = 10;
	uint public propertyID;

	mapping (address => uint) public investors; //mapping in case of ETH moneyback
	address[] investorArray; //address array for looping through mapping

	//address daoAddress;
	//Association public association = Association(daoAddress);
	ATL public atl = ATL(0x5D80e46379800f17c26D39C5f3f90cA0057CA196);
	address[] public atlHolders; //array of ATL token holders
	uint public numberOfBeneficiaries;

  event Buy(address holder, uint propertyTokenValue);
  event RunPto();
  event PausePto();
  event FinishPto();
	event CancelPto();

  PropertyToken public propertyToken;
	PropertyAssociation public propertyAssociation;

  address public propertyOwner;
	address public lawyer;
  modifier propertyOwnerOnly { require(msg.sender == propertyOwner); _; }
	modifier lawyerOnly { require(msg.sender == lawyer); _; }

  enum PtoState { Created, Running, Paused, Finished, Cancelled }
  PtoState ptoState = PtoState.Created;

  function PTO(address _propertyOwner, uint ptoFee, uint _propertyID, address _lawyer){ //, address _manager) {
    propertyToken = new PropertyToken(this);
    propertyOwner = _propertyOwner;
		PTO_FEE = ptoFee;
		propertyID = _propertyID;
		lawyer = _lawyer;
		//daoAddress = dao;
  }

  function() external payable {
    buyFor(msg.sender);
  }

	/*function getPtoBeneficiaries() internal {
		for (uint i = 0; i < numberOfBeneficiaries; i++) {
			atlHolders.push(association.getBeneficiaryAddress(i));
		}
	}*/

  function buyFor(address _investor) public payable {
    require(ptoState == PtoState.Running);
    require(msg.value > 0);
    uint _total = buy(_investor, msg.value * TOKEN_PRICE);
    Buy(_investor, _total);
  }

  function startPto() external propertyOwnerOnly {
    require(ptoState == PtoState.Created || ptoState == PtoState.Paused);
    ptoState = PtoState.Running;
    RunPto();
  }

  function pausePto() external propertyOwnerOnly {
    require(ptoState == PtoState.Running);
    ptoState = PtoState.Paused;
    PausePto();
  }

	function distributeTokens() internal {
		//getPtoBeneficiaries();
		for (uint i = 0; i < atlHolders.length; i++) {
			if(propertyToken.balanceOf(atlHolders[i]) == 0) {
				propertyToken.mint(atlHolders[i], atl.balanceOf(atlHolders[i]) * propertyToken.totalSupply() * PTO_FEE / atl.totalSupply());
			}
		}
	}

  function finishPto() external propertyOwnerOnly {
    require(ptoState == PtoState.Running || ptoState == PtoState.Paused);

    distributeTokens(); //temporary proxy for property token distributon among ATL holders
    propertyToken.unfreeze();

		propertyAssociation = new PropertyAssociation(propertyToken);
		propertyAssociation.transfer(this.balance * RESERVE_RATE / 100); //transfer a crtain percentage to the reserve fund
		propertyOwner.transfer(this.balance); //transfer the rest to property owner

    ptoState = PtoState.Finished;
    FinishPto();
  }

	function cancelPto() external lawyerOnly {
		require(ptoState == PtoState.Created || ptoState == PtoState.Running || ptoState == PtoState.Paused);
		for (uint i=0; i<investorArray.length; i++) {
			if(investors[investorArray[i]] > 0) {
				investorArray[i].transfer(investors[investorArray[i]]);
				investors[investorArray[i]] = 0;
			}
		}
		ptoState = PtoState.Cancelled;
		CancelPto();
	}

  function buy(address _investor, uint _propertyTokenValue) internal returns (uint) {
    propertyToken.mint(_investor, _propertyTokenValue);
		investors[_investor] += _propertyTokenValue / TOKEN_PRICE;
		investorArray.push(_investor);
    return _propertyTokenValue;
  }
}

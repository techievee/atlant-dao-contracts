pragma solidity ^0.4.11;

import "./installed/token/ERC20.sol";
import "./PropertyToken.sol";
import "./PropertyDAO.sol";

contract PTO {

  uint public constant TOKEN_PRICE = 100; // min propertyToken per ETH
  uint public constant TOKENS_FOR_SALE = 50 * 1e18;
	uint public PTO_FEE;
	uint RESERVE_RATE = 10;
	uint public propertyID;

	mapping (address => uint) public investors; //mapping in case of ETH moneyback
	address[] investorArray; //address array for looping through mapping

  event Buy(address holder, uint propertyTokenValue);
  event RunPto();
  event PausePto();
  event FinishPto();
	event CancelPto();

  PropertyToken public propertyToken;
	PropertyAssociation public propertyAssociation;

  address public propertyOwner;
	address public lawyer;
	//address public manager;
  modifier propertyOwnerOnly { require(msg.sender == propertyOwner); _; }
	modifier lawyerOnly { require(msg.sender == lawyer); _; }
	//modifier managerOnly { require(msg.sender == manager); _; }

  enum PtoState { Created, Running, Paused, Finished, Cancelled }
  PtoState ptoState = PtoState.Created;

  function PTO(address _propertyOwner, uint ptoFee, uint _propertyID, address _lawyer){ //, address _manager) {
    propertyToken = new PropertyToken(this);
    propertyOwner = _propertyOwner;
		PTO_FEE = ptoFee;
		propertyID = _propertyID;
		lawyer = _lawyer;
		//manager = _manager;
  }

  function() external payable {
    buyFor(msg.sender);
  }

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

  function finishPto(address _atlFund) external propertyOwnerOnly {
    require(ptoState == PtoState.Running || ptoState == PtoState.Paused);

		uint soldTokens = propertyToken.totalSupply();
    propertyToken.mint(_atlFund, PTO_FEE * soldTokens / 100); //temporary proxy for property token distributon among ATL holders
    propertyToken.unfreeze();

		propertyAssociation = new PropertyAssociation(propertyToken);
		propertyAssociation.transfer(this.balance * RESERVE_RATE / 100); //transfer a crtain percentage to the reserve fund
		propertyOwner.transfer(this.balance);

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

  /*function withdrawEther(address recipient, uint _value) internal {
    recipient.transfer(_value * 1 ether);
  }*/

  /*function withdrawToken(address _tokenContract, uint _val) external {
    ERC20 _tok = ERC20(_tokenContract);
    _tok.transfer(propertyOwner, _val);
  }*/

  function buy(address _investor, uint _propertyTokenValue) internal returns (uint) {
    propertyToken.mint(_investor, _propertyTokenValue);
		investors[_investor] += _propertyTokenValue / TOKEN_PRICE;
		investorArray.push(_investor);
    return _propertyTokenValue;
  }
}

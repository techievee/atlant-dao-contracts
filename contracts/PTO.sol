pragma solidity ^0.4.11;

import "./installed/token/ERC20.sol";
import "./PropertyToken.sol";
import "./PropertyDAO.sol";

contract PTO {
	using SafeMath for uint;

  uint public constant TOKEN_PRICE = 100; // min propertyToken per ETH
  uint public constant TOKENS_FOR_SALE = 50 * 1e18;
	uint public PTO_FEE;
	uint RESERVE_RATE = 10;
	uint public propertyID;

	mapping (address => uint) public investors; //mapping in case of ETH moneyback
	uint public tokensSold;

	ERC20 atl;
  PropertyToken public propertyToken;
	PropertyAssociation public propertyAssociation;

	event Buy(address holder, uint propertyTokenValue);
	event ChangePtoState(PtoState state);
	event Refunded(address investor, uint contribution);

	address daoAddress;
  address public propertyOwner;
	address public lawyer;
  modifier propertyOwnerOnly { require(msg.sender == propertyOwner); _; }
	modifier lawyerOnly { require(msg.sender == lawyer); _; }
	modifier daoOnly { require(msg.sender == daoAddress); _; }

  enum PtoState { Created, Running, Paused, Finished, Cancelled, Allocating }
  PtoState public ptoState = PtoState.Created;

  function PTO(address sharesToken, address _propertyOwner, uint ptoFee, uint _propertyID, address _lawyer, address dao){
    propertyToken = new PropertyToken(this);
    propertyOwner = _propertyOwner;
		PTO_FEE = ptoFee;
		propertyID = _propertyID;
		lawyer = _lawyer;
		daoAddress = dao;
		atl = ERC20(sharesToken);
  }

  function() external payable {
    buyFor(msg.sender);
  }

  function buyFor(address _investor) public payable {
    require(ptoState == PtoState.Running);
    require(msg.value > 0);

		uint _total = msg.value.mul(TOKEN_PRICE);
		propertyToken.mint(_investor, _total);
		investors[_investor] += msg.value;

    Buy(_investor, _total);
  }

  function startPto() external propertyOwnerOnly {
    require(ptoState == PtoState.Created || ptoState == PtoState.Paused);
    ptoState = PtoState.Running;
    ChangePtoState(ptoState);
  }

  function pausePto() external propertyOwnerOnly {
    require(ptoState == PtoState.Running);
    ptoState = PtoState.Paused;
    ChangePtoState(ptoState);
  }

  function stopPto() external propertyOwnerOnly {
    require(ptoState == PtoState.Running || ptoState == PtoState.Paused);

		propertyAssociation = new PropertyAssociation(propertyToken);
		propertyAssociation.transfer(this.balance * RESERVE_RATE / 100); //transfer a crtain percentage to the reserve fund
		propertyOwner.transfer(this.balance); //transfer the rest to property owner

		tokensSold = propertyToken.totalSupply();

		ptoState = PtoState.Allocating;
		ChangePtoState(ptoState);
	}

	function distributeTokens(address atlHolder) public daoOnly{
		require(ptoState == PtoState.Allocating);
		require(propertyToken.balanceOf(atlHolder) == 0 && atl.balanceOf(atlHolder) > 0);

		propertyToken.mint(atlHolder, tokensSold * atl.balanceOf(atlHolder) / atl.totalSupply() * PTO_FEE / 100);
	}

	function finalizePto() external propertyOwnerOnly {
		require(ptoState == PtoState.Allocating);

    ptoState = PtoState.Finished;
		propertyToken.unfreeze();

    ChangePtoState(ptoState);
  }

	function cancelPto() external lawyerOnly {
		require(ptoState == PtoState.Created || ptoState == PtoState.Running || ptoState == PtoState.Paused);

		ptoState = PtoState.Cancelled;
		ChangePtoState(ptoState);
	}


	function refund() public {
		require(ptoState == PtoState.Cancelled);
		uint balance = investors[msg.sender];
		require(balance != 0);

		investors[msg.sender] = 0;
		msg.sender.transfer(balance);
		
		Refunded(msg.sender, balance);
	}
}

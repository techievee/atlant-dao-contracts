pragma solidity ^0.4.11;

import "./Owned.sol";
import "./TokenRecipient.sol";
import "./ATL.sol";

/* The shareholder association contract itself */
contract Association is owned, tokenRecipient {

    /* Contract Variables and events */
    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    Proposal[] public proposals;
    uint public numProposals;
    ATL public sharesTokenAddress;
		uint public percentFee;

    event ProposalAdded(uint proposalID, uint proposedFee, string description);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, uint result, uint quorum, bool active);
    event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, address newSharesTokenAddress);

    struct Proposal {
			uint proposedFee;
      string description;
      uint votingDeadline;
      bool executed;
      bool proposalPassed;
      uint numberOfVotes;
      bytes32 proposalHash;
      Vote[] votes;
      mapping (address => bool) voted;
    }

    struct Vote {
      bool inSupport;
      address voter;
    }

    /* modifier that allows only shareholders to vote and create new proposals */
    modifier onlyShareholders {
        require (sharesTokenAddress.balanceOf(msg.sender) > 0);
        _;
    }

    /* First time setup */
    function Association(ATL sharesAddress, uint minimumSharesToPassAVote, uint minutesForDebate, uint defaultPercentFee) payable {
				percentFee = defaultPercentFee;
				changeVotingRules(sharesAddress, minimumSharesToPassAVote, minutesForDebate);
    }

    /// @notice Make so that proposals need tobe discussed for at least `minutesForDebate/60` hours and all voters combined must own more than `minimumSharesToPassAVote` shares of token `sharesAddress` to be executed
    /// @param sharesAddress token address
    /// @param minimumSharesToPassAVote proposal can vote only if the sum of shares held by all voters exceed this number
    /// @param minutesForDebate the minimum amount of delay between when a proposal is made and when it can be executed
    function changeVotingRules(ATL sharesAddress, uint minimumSharesToPassAVote, uint minutesForDebate) onlyOwner {
        sharesTokenAddress = ATL(sharesAddress);
        if (minimumSharesToPassAVote == 0 ) minimumSharesToPassAVote = 1;
        minimumQuorum = minimumSharesToPassAVote;
        debatingPeriodInMinutes = minutesForDebate;
        ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, sharesTokenAddress);
    }

    function newFeeProposal(uint proposedFee, string JobDescription, bytes transactionBytecode) onlyShareholders
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
				p.proposedFee = proposedFee;
        p.description = JobDescription;
        p.proposalHash = sha3(proposedFee, transactionBytecode);

        p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        ProposalAdded(proposalID, proposedFee, JobDescription);

        numProposals = proposalID + 1;

        return proposalID;
    }

    /* function to check if a proposal code matches */
    function checkProposalCode(uint proposalNumber, uint proposedFee, bytes transactionBytecode) constant
        returns (bool codeChecksOut)
    {
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == sha3(proposedFee, transactionBytecode);
    }

    /* */
    function vote(uint proposalNumber, bool supportsProposal) onlyShareholders returns (uint voteID) {
        Proposal storage p = proposals[proposalNumber];
        require (p.voted[msg.sender] != true);

        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes = voteID +1;
        Voted(proposalNumber,  supportsProposal, msg.sender);
        return voteID;
    }

    function executeProposal(uint proposalNumber, bytes transactionBytecode) {
        Proposal storage p = proposals[proposalNumber];
        /* Check if the proposal can be executed */
        require (now > p.votingDeadline  /* has the voting deadline passed? */
            &&  !p.executed        /* has it been already executed? */
            &&  p.proposalHash == sha3(p.proposedFee, transactionBytecode)); /* Does the transaction code match the proposal? */


        /* tally the votes */
        uint quorum = 0;
        uint yea = 0;
        uint nay = 0;

        for (uint i = 0; i <  p.votes.length; ++i) {
            Vote storage v = p.votes[i];
            uint voteWeight = sharesTokenAddress.balanceOf(v.voter);
            quorum += voteWeight;
            if (v.inSupport) {
                yea += voteWeight;
            } else {
                nay += voteWeight;
            }
        }


        /* execute result */
        require (quorum >= minimumQuorum); /* Not enough significant voters */

        if (yea > nay ) {
            /* has quorum and was approved */
            p.executed = true;
            percentFee = p.proposedFee;
            p.proposalPassed = true;
        } else {
            p.proposalPassed = false;
        }
        // Fire Events
        ProposalTallied(proposalNumber, yea - nay, quorum, p.proposalPassed);
    }
}

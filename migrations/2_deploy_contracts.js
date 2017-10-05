var PtoLib = artifacts.require("./PtoLib");
var Association = artifacts.require("./Association");

var sharesAddress = web3.eth.accounts[0]; //"0x5D80e46379800f17c26D39C5f3f90cA0057CA196";
var minimumSharesToPassAVote = 1;
var minutesForDebate = 1;
var defaultPercentFee = 7;
var lawyerName = "ABC";
var lawyerFee = 10;
var lawyerAddress = web3.eth.accounts[1];//"0x9c8E4537517cCac0e2fd3B2f3cD976EBC94F3547";

module.exports = function(deployer) {
  deployer.deploy(PtoLib);
  deployer.link(PtoLib, Association);
  deployer.deploy(Association, sharesAddress, minimumSharesToPassAVote, minutesForDebate, defaultPercentFee, lawyerName, lawyerFee, lawyerAddress);
};

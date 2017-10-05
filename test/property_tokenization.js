const DAO = artifacts.require("./Association");
const PTO = artifacts.require("./PTO");
const PropertyToken = artifacts.require("./PropertyToken");
const PropertyAssociation = artifacts.require("./PropertyAssociation");
const Token = artifacts.require("./MockToken");

contract("property platform", (accounts) => {
  const [lawyer, seller, investor, atlHolder1, atlHolder2, daoOwner] = web3.eth.accounts;
  let dao;
	let pto;
	let propertyToken;
	let propertyAssociation;
	let atl;
	let investorBalance;

	function getEtherBalance(addr) {
		return web3.fromWei(web3.eth.getBalance(addr).toFixed(), "ether")
	}

	function getGasPrice() {
		return web3.eth.gasPrice.toFixed();
	}

	before(() => {
		return Token.new()
		.then(res => {
			atl = res;
		})
		.then(() => {
			return DAO.new(atl.address, 0, 10, 7, "Mr. Lawyer", 1, lawyer, {from: daoOwner})
		})
		.then(res => {
			dao = res;
		});
	});

	it("should be able to create property", () => {
		return dao.addPropertyForSale("Apartment", 200000, 100, true, {from: seller, value: web3.toWei(1, 'ether')})
			.then((res) => {
				return dao.viewProperty(1).then((prop) => {
					assert.equal(prop[0], "Apartment"); //check property name
					assert.equal(prop[1].toFixed(), 200000); //check property price
					assert.equal(prop[2].toFixed(), 100); //check property area
					assert.notEqual(prop[3], "0x0"); //check property address
					assert.equal(prop[4], false); //check that property is not approved yet
					assert.equal(prop[5], false); //check that property has not been reviewed
				});
			})
	});

	it("should be able to approve property", () => {
		let lawyerBefore, lawyerAfter;
		lawyerBefore = getEtherBalance(lawyer);
		return dao.approveProperty(1, true, {from: lawyer})
			.then((res) => {
				return dao.viewProperty(1).then((prop) => {
					lawyerAfter = getEtherBalance(lawyer);
					assert.equal(prop[4], true); //check that building got approved
					assert.isAbove(lawyerAfter - lawyerBefore, 0); //check that lawyer got paid
				});
			})
	});

	it("should be able to change voting rules", () => {
		return dao.changeVotingRules(0, 0, {from: daoOwner})
		.then(() => dao.debatingPeriodInMinutes())
		.then((debateTime) => assert.equal(debateTime.toFixed(), 0, "could not set debate time to 0"))
	});

	it("should be able to propose fee change", () => {
		return atl.setBalance(100, {from: atlHolder1})
		.then(() => atl.setBalance(200, {from: atlHolder2}))
		.then(() => dao.newFeeProposal(5, "", "", {from: atlHolder1}))
		.then(() => dao.checkProposalCode(0, 5, ""))
		.then((isOK) => assert.isTrue(isOK, "proposal wasn't added"));
	});

	it("should be able to vote on fee change and execute proposal", () => {
		return dao.vote(0, true, {from: atlHolder2})
		.then(() => dao.executeProposal(0, "", {from: atlHolder1}))
		.then(() => dao.percentFee())
		.then((fee) => assert.equal(fee.toFixed(), 5, "unexpected new fee value"))
	});

	it("should be able to launch PTO", () => {
		let watcher = dao.PtoLaunched();
		return dao.launchPropertySale(1, {from: seller})
			.then((res) => {
				let events = watcher.get();
				pto = PTO.at(events[0].args.ptoAddress);
				return pto.propertyToken();
			})
			.then((pToken) => {
				assert.notEqual(pToken, "0x0"); //check for property token
				propertyToken = PropertyToken.at(pToken);
			})
	});

	it("should be able to start PTO", () => {
		return pto.startPto({from: seller})
		.then(() => {
			return pto.ptoState();
		}).
		then((res) => {
			assert.equal(res.toFixed(), 1);
		})
	});

	it("should be able to add pto beneficiaries", () => {
		let watcher = dao.AddPropertyBeneficiary({}, {fromBlock:0, toBlock: 'latest'});
		return dao.addSelfToBeneficiaries({from: atlHolder1})
		.then(() => {
			return dao.addSelfToBeneficiaries({from: atlHolder2});
		})
		.then(() => {
			let events = watcher.get();
			assert.equal(events.length, 2); //check num of beneficiaries
			assert.equal(events[0].args.beneficiaryAddress, atlHolder1); //check addr of beneficiary
			assert.equal(events[1].args.beneficiaryAddress, atlHolder2); //check addr of beneficiary
		});
	});

	it("should be able to invest in PTO", () => {
		return pto.buyFor(investor, {from: investor, value: web3.toWei(100, 'ether')})
		.then(() => {
			assert.equal(getEtherBalance(pto.address), 100); //check that investments have been received
		})
	});

	// it("should be able to cancel PTO", () => {
	// 	return pto.cancelPto({from: lawyer})
	// 	.then(() => pto.ptoState())
	// 	.then((state) => assert(state.toFixed(), 4, "PTO wasn't cancelled"))
	// });

	// it("should be able to refund an investor", () => {
	// 	return pto.investors(investor)
	// 	.then((res) => assert.isAbove(res.toFixed(), 0, "balance was zero"))
	// 	.then(() => pto.refund({from: investor}))
	// 	.then(() => pto.investors(investor))
	// 	.then((res) => assert.equal(res.toFixed(), 0, "contribution was not fully refunded"))
	// });

	it("should be able to stop PTO", () => {
		let sellerBefore = getEtherBalance(seller);
		return pto.stopPto({from: seller})
		.then(() => {
			return pto.ptoState();
		})
		.then((res) => {
			assert.equal(res.toFixed(), 5);
			return pto.propertyAssociation();
		}).then((propAssoc) => {
			propertyAssociation = PropertyAssociation.at(propAssoc);
			assert.isAbove(getEtherBalance(propertyAssociation.address), 0, "reserve fund did not receive any funds");
			let sellerAfter = getEtherBalance(seller);
			assert.isAbove(sellerAfter - sellerBefore, 0, "seller did not receive pto funds");
			assert.equal(getEtherBalance(pto.address), 0, "pto has leftover ether");
		})
	});

	it("should distribute property correctly", () => {
		let atl1, atl2, token1, token2;
		return atl.balanceOf(atlHolder1)
			.then((res) => {
				console.log("atl balance of 1:", res.toFixed());
				atl1 = res.toFixed();
			})
			.then(() => atl.balanceOf(atlHolder2))
			.then((res) => {
				console.log("atl balance of 2:", res.toFixed());
				atl2 = res.toFixed();
			})
			.then(() => {
				return dao.distributeProperty(1, [atlHolder1, atlHolder2], {from: seller})
				.then(() => {
					return propertyToken.balanceOf(atlHolder1);
				})
				.then(res => {
					console.log("Property token balance of 1: ", res.toFixed());
					token1 = res.toFixed();
				})
				.then(() => {
					return propertyToken.balanceOf(atlHolder2);
				})
				.then(res => {
					console.log("Property token balance of 2: ", res.toFixed());
					token2 = res.toFixed();
					assert.equal(atl1/atl2, token1/token2, "tokens not distributed proportionally");
				});
			});
	});

	it("should finish PTO", () => {
		return pto.finalizePto({from: seller})
		.then(() => {
			return pto.ptoState();
		})
		.then((res) => {
			assert.equal(res.toFixed(), 3, "pto not finished");
		})
	});
});

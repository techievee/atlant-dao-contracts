const DAO = artifacts.require("./Association");

contract("property platform", () => {
  const [a, b, c] = web3.eth.accounts;
  let dao;

	it("should be able to create DAO", () =>
    DAO.new(0x5D80e46379800f17c26D39C5f3f90cA0057CA196, 1, 1, 7, "abc", 1, 0x9c8E4537517cCac0e2fd3B2f3cD976EBC94F3547).then(res => {
      assert.isOk(res && res.address, "has invalid address");
      dao = res;
			console.log(dao.address);
    })
  );
})

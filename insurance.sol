// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Insurance {

    using SafeMath for uint;

    mapping (address => bool) insurers;

    enum PolicyState { INITIALIZED, LOCKED, PREMIUM, PAYOUT, COMPLETED }

    address owner;

    struct Policy {
        string terms;
        uint256 premium;
        uint256 payout;
        uint256 claimTime;
        address payable insurer;
        address payable insured;
        PolicyState state;
    }

    mapping (uint256 => Policy) policies;

    uint256 policyCount = 0;

    struct PolicyOwner {
        uint256 count;
        uint256[] policies;
    }

    mapping (address => PolicyOwner) policyOwners;

    mapping (address => bool) agents;

    modifier onlyValidAddress() {
        require(msg.sender == address(0), "ERROR: invalid account");
        _;
    }

    modifier onlyValidPolicy(uint256 id) {
        require(policies[id].insured != address(0), "ERROR: invalid account");
        _;
    }

    modifier onlyNonInitializedPolicy(uint256 id) {
        require(policies[id].state != PolicyState.INITIALIZED, "ERROR: policy has been completed");
        _;
    }

    modifier onlyAgent() {
        require(agents[msg.sender] == true, "ERROR: address does not belong to an agent");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR: address does not belong to owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createPolicy(
        string memory terms,
        uint256 premium,
        uint256 payout,
        uint256 claimTime,
        address payable insurer) public payable {

            require(msg.value == premium, "ERROR: not enough value");

            policies[policyCount] = Policy(
                terms, 
                premium, 
                payout, 
                claimTime, 
                insurer,
                payable(msg.sender),
                PolicyState.INITIALIZED
            );

            policyOwners[msg.sender].policies[policyOwners[msg.sender].count] = policyCount;

            policyOwners[msg.sender].count += 1;

    }

    function getPolicy(uint256 id) public onlyValidPolicy(id) view returns (string memory, uint256, uint256, uint256, address, address) {
        
        return (
            policies[id].terms,
            policies[id].premium,
            policies[id].payout,
            policies[id].claimTime,
            policies[id].insurer,
            policies[id].insured
        );

    }

    function acceptPolicy(uint256 id) public payable onlyValidAddress onlyValidPolicy(id) onlyNonInitializedPolicy(id) {

        require(address(0) == policies[id].insurer, "ERROR: policy already accepted");

        require(msg.sender != policies[id].insured, "ERROR: you can not accept a policy made by you");

        require(policies[id].payout == msg.value, "ERROR: Not enough value to accept policy");

        payable(msg.sender).transfer(policies[id].premium);

        policies[id].insurer = payable(msg.sender);

        policies[id].state = PolicyState.LOCKED;

    }

    function claimPremiumByInsurer(uint256 id) public payable onlyValidAddress onlyValidPolicy(id) {

        require(msg.sender == policies[id].insurer, "ERROR: you can not make a claim");

        require(block.timestamp >= policies[id].claimTime + 3 days, "ERROR: claim not matured");

        require(policies[id].state == PolicyState.PREMIUM, "ERROR: you can not claim the premium");

        payable(msg.sender).transfer(policies[id].payout);
        
        policies[id].state = PolicyState.COMPLETED;

    }

    function claimPayoutByInsured(uint256 id) public payable onlyValidAddress onlyValidPolicy(id)  {

        require(msg.sender == policies[id].insured, "ERROR: you can not make a claim");

        require(block.timestamp >= policies[id].claimTime + 3 days, "ERROR: claim not matured");

        require(policies[id].state == PolicyState.PAYOUT, "ERROR: you can not claim the premium");

        payable(msg.sender).transfer(policies[id].payout);

        policies[id].state = PolicyState.COMPLETED;

    }

    function awardToInsurer(uint256 id) public payable onlyValidAddress onlyAgent onlyValidPolicy(id)  {

        require(block.timestamp >= policies[id].claimTime + 3 days, "ERROR: claim not matured");

        require(policies[id].state == PolicyState.LOCKED, "ERROR: claim is not locked");

        require(agents[msg.sender] == true, "ERROR: not an agent");

        policies[id].state = PolicyState.PREMIUM;

    }

    function awardToInsured(uint256 id) public payable onlyValidAddress onlyAgent onlyValidPolicy(id)  {

        require(block.timestamp >= policies[id].claimTime + 3 days, "ERROR: claim not matured");

        require(policies[id].state == PolicyState.LOCKED, "ERROR: claim is not locked");

        require(agents[msg.sender] == true, "ERROR: not an agent");

        policies[id].state = PolicyState.PAYOUT;

    }

    function addAgent(address agentWallet) public onlyOwner {
        agents[agentWallet] = true;
    }


    function removeAgent(address agentWallet) public onlyOwner {
        agents[agentWallet] = true;
    }


}

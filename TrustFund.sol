// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract CryptoFunding {
    // Mapping to keep track of each contributor's amount
    mapping(address => uint) public Contributors;
    address public CEOAddress;
    uint public minimumContribution;
    uint public deadLine;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    // Struct to define the organization status request
    struct organizationsRequest {
        string description;
        address payable recipient;
        uint value;
        uint noOfVoters;
        bool completed;
        mapping(address => bool) validators;
    }

    // Mapping to store organization status requests
    mapping(uint => organizationsRequest) public requestOrganizationStatus;
    uint public numOfRequests;

    // Constructor to initialize the target and deadline
    constructor(uint _deadLine, uint _target) {
        target = _target;
        deadLine = block.timestamp + _deadLine;
        minimumContribution = 1 * 1e16; // Minimum contribution of 0.01 ETH
        CEOAddress = msg.sender;
    }

    // Function to contribute Ether to the contract
    function sendEther() payable public {
        require(block.timestamp < deadLine, "Deadline has passed");
        require(msg.value >= minimumContribution, "You need to send at least 0.01 ETH");
        
        if (Contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        Contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    // Function to refund contributors if the target is not met by the deadline
    function reFund() public {
        require(block.timestamp > deadLine && raisedAmount < target, "You're not eligible for a refund");
        require(Contributors[msg.sender] > 0, "You have not deposited any money");
        
        address payable user = payable(msg.sender);
        user.transfer(Contributors[msg.sender]);
    }

    // Function to get the contract's current balance
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Modifier to restrict function access to the CEO
    modifier onlyCEO() {
        require(msg.sender == CEOAddress, "You are not authorized");
        _;
    }

    // Function to create a new request for organization funding
    function createNewRequest(string memory _description, address payable _recipient, uint _value) public onlyCEO {
        organizationsRequest storage newRequest = requestOrganizationStatus[numOfRequests];
        numOfRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.noOfVoters = 0;
        newRequest.completed = false;
    }

    // Function for contributors to vote on a request
    function voteRequest(uint requestNo) public {
        require(Contributors[msg.sender] > 0, "You must be a contributor");
        
        organizationsRequest storage thisRequest = requestOrganizationStatus[requestNo];
        require(thisRequest.validators[msg.sender] == false, "You have already voted");
        
        thisRequest.validators[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    // Function to make payment to the recipient if the request is approved
    function makePayment(uint requestNo) public {
        require(raisedAmount >= target, "Target not reached");
        
        organizationsRequest storage thisRequest = requestOrganizationStatus[requestNo];
        require(thisRequest.completed == false, "The request has already been completed");
        require(thisRequest.noOfVoters > noOfContributors / 2, "Majority does not support");
        
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}

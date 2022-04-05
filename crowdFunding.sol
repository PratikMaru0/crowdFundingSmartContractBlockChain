// Smart contract deployed on Rinkeby ethereum blockchain Link :- https://rinkeby.etherscan.io/address/0x0dca06d05c21eda164f38a7dcd446f1474c3a9a2
// Contract address :- 0x0dCA06D05c21Eda164F38a7dCd446f1474C3A9A2

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 < 0.9.0;

contract crowdFunding {
    
    // variables 
    mapping(address=>uint) public contributors;  // here mapping contributorsAddress to ammount they paid
    address public manager ; // the one who'll manage smart contract 
    uint public minimumContribution; // minimum ammount must be >= minimumContribution
    uint public target; // total ammount that needed  
    uint public deadline; // Last date (before last date contribution must be equal to target
    uint public raisedAmmount; // To check the total ammount raised at a particular time
    uint public noOfContributors; // To check 51% criteria  

    // Making request struct (Why ? need of money )
    struct Request{
        string description;  // why money is needed
        address payable recipient; // Whos the beneficiery / To whom this money will be paid
        uint value; // Ammount required 
        bool completed; //Whether request is accepted or rejected 
        uint noOfVoters; // Number of voters voted (it can be yes/no)
        mapping(address=>bool) voters; // it will show wether voters voted or not 
    }

    // Mapping all the requests with number (Becoz request can be multiple it can be for eviornmental cause , educational grants , food , books etc)
    mapping(uint=>Request) public requests; 
    uint public numRequests;  // In mapping there is no such increment thing so thats why we are manually calculating number of requests  

    // Assigning the administrator (manager)
    constructor(uint _target , uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;   // block.timestamp gives time value in UNIX (ie :- Seconds) 
        minimumContribution = 0.1 ether;
        manager = msg.sender;
    }

    receive() external payable{
        require(block.timestamp <= deadline, "Deadline has passed" );
        require(msg.value >= minimumContribution, "Minimum Contribution must be greater or equal to 100 wei" );
        // require(target >= raisedAmmount , "No need of more contribution "  );
        // require(msg.value <= target,"Please enter ammount equal to target");

        // If its new contributor increase count of the TotalNumber of contributor
        if(contributors[msg.sender] == 0){
            noOfContributors++ ;
        }

        contributors[msg.sender] += msg.value;  // Adding ammount corressponding to the Contributer Address k contributed value
        raisedAmmount += msg.value;     // Adding contributed ammount to the main contract wallet
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // If target ammount is not met at deadline then contributors can ask for the refund of the money 
    function refund() public {
        require((target > raisedAmmount) && (block.timestamp > deadline) , "You are not eligible for refund" );
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);   // we must make it payable otherwise we cannot transfer ammount to the sender
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;   // After refunding ether humae us contributor k address k corresponding contributed value ko zero karna hogana.
    }

    // From here main important + complicated part 

    // Only manager can create requests
    modifier onlyManager(){
        require(msg.sender == manager,"Only manager can call this function ");
        _;   // It means after executing modifier function will run from this point
    }

    // If modifier is used with function always remember that modifier will executed first and check conditions and then only function will be executed
    // function for creating request
    function createRequests(string memory _description , address payable _recipient , uint _value) public onlyManager() {
        // If we are using structure in which we used mapping and want to use or make variable thats type of that structure inside the function then humae storage keyword ka use karna padega (we cant use memory keyword here)
        Request storage newRequest = requests[numRequests]; 
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false; // By default we are assigning it false. Means you cant take money without majority voting 
        newRequest.noOfVoters = 0;  // At starting assigning number of voters = 0
    }  

    // Making function for voting 
    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0 , "You must be contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false,"You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    // Decision making function (based on 51%)
    function makePayment(uint _requestNo) public onlyManager {
        require(raisedAmmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false , "The Request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2 , "Majority does not support");  // here comes 51% part
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;   // Dont forget to make it true Otherwise Problem ho sakti hai 
    }
}

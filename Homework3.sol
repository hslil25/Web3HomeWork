// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract fund{
    event Launch(
        uint id,
        address indexed owner,
        uint goal,
        uint32 start,
        uint32 end
    );
//A helper that I added to help while launching an event.
    function time() external view returns (uint){
        return block.timestamp;
    }

    event Delete(uint _id);
    event Pledge(uint indexed id, address user, uint amount);
    event Unpledge(uint indexed id, address user, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed user, uint amount);
    //Definiton for campaign
    struct Campaign{
        address creator;
        uint goal;
        uint32 start;
        uint32 end;
        uint pledged;
        bool claimed;
    }
    //Using count as a dynamic number for "active" campaigns.
    uint public count = 0;
    //Index in order to store in the array
    uint public index = 0;
    
    //ERC20 protocol token creation
    IERC20 public immutable token;
    mapping (uint=>Campaign) public campaigns;
    mapping (uint=>mapping(address=>uint)) public pledgedAmount;


    constructor (address _token) payable {
        token = IERC20(_token);
    }
    
    //Launching the event with three parameters (using time() function here)
    function launch(
        uint _goal,
        uint32 _start,
        uint32 _end
    ) external {
        require(_start>=block.timestamp,"start<now");
        require(_end>_start ,"start<end");
        require(_end<=block.timestamp + 90 days,"dur<max_dur");
        campaigns[index] = Campaign({
            creator: msg.sender,
            goal:_goal,
            start:_start,
            end:_end,
            pledged:0,
            claimed:false
        });

        emit Launch(count,msg.sender,_goal,_start,_end);
        index++;
        count++;


    }
    //Closing an event and decrementing the count however keeping the index same.
    function close(uint id) external{
        Campaign memory cmpn = campaigns[id];
        require(cmpn.creator == msg.sender,"Denied");
        //I didn't use time limit because it should be possible for owner to cancel the campaign anytime.
        require (cmpn.pledged == 0, "Bal != 0");
        count--;
        delete campaigns[id];
        emit Delete(id);

    }
    function pledge(uint _id, uint _amount) payable external {
        Campaign storage campaign = campaigns[_id];
        //Is campaign still going on?
        require(block.timestamp >= campaign.start, "not started");
        require(block.timestamp <= campaign.end, "ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        //Is campaign still going on?
        
        require(block.timestamp <= campaign.end, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }
    //Claim function satisfying the necessary conditions
    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        //Trying to keep error messages short for gas efficiency
        require(campaign.creator == msg.sender, "not creator");
        require(block.timestamp > campaign.end, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(campaign.creator, campaign.pledged);

        emit Claim(_id);
    }

   
    function refund(uint id) external{
        Campaign memory campaign = campaigns[id];
        require(campaign.pledged < campaign.goal, "Pledged >= Goal");
        
        //We are sure that no one has no balance in the campaign as they would use this function and they will pay gas so need to think
        // if bal == 0 condition
        uint bal = pledgedAmount[id][msg.sender];
        pledgedAmount[id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(id, msg.sender, bal);
        
    }

}

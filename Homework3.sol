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

    function time() external view returns (uint){
        return block.timestamp;
    }

    event Delete(uint _id);
    event Pledge(uint indexed id, address user, uint amount);
    event Unpledge(uint indexed id, address user, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed user, uint amount);
    struct Campaign{
        address creator;
        uint goal;
        uint32 start;
        uint32 end;
        uint pledged;
        bool claimed;
    }
    uint public count = 0;
    uint public index = 0;

    IERC20 public immutable token;
    mapping (uint=>Campaign) public campaigns;
    mapping (uint=>mapping(address=>uint)) public pledgedAmount;


    constructor (address _token) payable {
        token = IERC20(_token);
    }

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
        require(block.timestamp >= campaign.start, "not started");
        require(block.timestamp <= campaign.end, "ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.end, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
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
        
        uint bal = pledgedAmount[id][msg.sender];
        pledgedAmount[id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(id, msg.sender, bal);
        
    }

}
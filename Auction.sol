// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract DecentralizedAuction {
    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public highestBindingBid;
    uint256 public numHighestBidders;
    mapping(uint256 => address) public highestBidders;
    mapping(address => uint256) public bids;
    address[] public bidders;
    address winner;


    constructor(uint256 _durationMinutes) {
        owner = msg.sender;
        startTime = block.timestamp;
        if (_durationMinutes < 2)
            endTime = startTime + 120 seconds;
        else 
            endTime = startTime + (_durationMinutes * 60 seconds);
        bids[address(0)] = 0;
        highestBindingBid = 0;
        numHighestBidders = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < endTime, "Auction has ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= endTime, "Auction has not ended yet");
        _;
    }

    function placeBid(uint256 increment) external payable onlyBeforeEnd {
        uint256 minBid = bids[highestBidders[0]] + increment;

        require(msg.value >= minBid, "Bid must be higher than or equal to the minimum bid");

        if (bids[msg.sender] > 0) {
            payable(msg.sender).transfer(bids[msg.sender]);
        }

        bids[msg.sender] = msg.value;

        if (msg.value > highestBindingBid) {
            highestBindingBid = msg.value;
            // empty highestBidders array
            for (uint256 i = 0; i < numHighestBidders; i++) {
                highestBidders[i] = address(0);
            }
            highestBidders[0] = msg.sender;
            numHighestBidders = 1;
        } else if (msg.value == highestBindingBid) {
            highestBidders[numHighestBidders] = msg.sender;
            numHighestBidders++;
        }

        if (bids[msg.sender] > 0) {
            bool alreadyExists = false;
            for (uint256 i = 0; i < bidders.length; i++) {
                if (bidders[i] == msg.sender) {
                    alreadyExists = true;
                    break;
                }
            }
            if (!alreadyExists) {
                bidders.push(msg.sender);
            }
        }
    }

    function cancelAuction() external onlyOwner onlyBeforeEnd {
        for (uint256 i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            payable(bidder).transfer(bids[bidder]);
        }
        selfdestruct(payable(owner));
    }

    function finalizeAuction() external onlyOwner onlyAfterEnd {
        require(numHighestBidders > 0, "No bids received");
        require(bidders.length >= 3, "Need at least 3 people to bid");
        //require(block.timestamp >= startTime + 120 seconds, "Minimum 2 minutes need to be passed before finalizing the Auction");

        uint256 ownerAmount = (highestBindingBid * 10) / 100;

        payable(owner).transfer(ownerAmount);

        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp))) % numHighestBidders;
        winner = highestBidders[random];

        
        // for (uint256 i = 0; i < bidders.length; i++) {
        //     address bidder = bidders[i];
        //     if (bidder != highestBidder) {
        //         payable(bidder).transfer(bids[bidder]);
        //     }
        // }
    }


    function withdrawBid() external {
        require(block.timestamp >= endTime, "Auction has not ended");
        require(msg.sender != winner, "You have won the auction");

        uint256 amount = bids[msg.sender];
        require(amount > 0, "No bids to withdraw");

        bids[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

}

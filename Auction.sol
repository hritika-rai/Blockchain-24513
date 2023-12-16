// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract DecentralizedAuction {
    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public highestBindingBid;
    address public highestBidder;

    mapping(address => uint256) public bids;

    address[] public bidders;

    constructor(uint256 _durationMinutes) {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = startTime + (_durationMinutes * 60 seconds);
        bids[address(0)] = 0;
        highestBindingBid = 0;
        highestBidder = address(0);

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
        uint256 minBid = bids[highestBidder] + increment;

        require(msg.value >= minBid, "Bid must be higher than or equal to the minimum bid");

        if (bids[msg.sender] > 0) {
            payable(msg.sender).transfer(bids[msg.sender]);
        }

        bids[msg.sender] = msg.value;

        if (msg.value > highestBindingBid) {
            highestBindingBid = msg.value;
            highestBidder = msg.sender;
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
        require(highestBidder != address(0), "No bids received");
        
        payable(owner).transfer(highestBindingBid);

        // for (uint256 i = 0; i < bidders.length; i++) {
        //     address bidder = bidders[i];
        //     if (bidder != highestBidder) {
        //         payable(bidder).transfer(bids[bidder]);
        //     }
        // }
    }

    function withdrawBid() external {
        require(block.timestamp >= endTime, "Auction has not ended");
        require(msg.sender != highestBidder, "You have won the auction");

        uint256 amount = bids[msg.sender];
        require(amount > 0, "No bids to withdraw");

        bids[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

    }

}

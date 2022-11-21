// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ticket {
    uint public price;
    string public title;
    uint public place_id;
    address public owner; 
    address public ticketingSystem; 

    enum State {Init, Locked, Inactive, Refund}
    State public state;

    ///This function can't be called at this state
    error InvalidState();

    modifier inState(State state_){
        if(state != state_){
            revert InvalidState();
        }
        _;
    }

    ///You are not the ticket owner!
    error notOwner();

    modifier isOwner(address caller){
        if(caller != owner){
            revert notOwner();
        }
        _;
    }

    ///The ticket details can be modified only by the Ticketing System!
    error notCinema();

    modifier isCinema(){
        if(msg.sender != ticketingSystem){
            revert notCinema();
        }
        _;
    }

    constructor(address ticketBuyer, uint256 place) public {
        owner = ticketBuyer;
        place_id = place;
        ticketingSystem = msg.sender;
    }

     function getPlaceID() public view returns (uint256) {
        return place_id;
    }

    function changePlace(address caller, uint256 new_place) public isCinema isOwner(caller) {
        place_id = new_place;
    }

}


contract CinemaTicketingSystem {
    mapping(address => Ticket) _tickets;

    uint public price;
    uint public qty;
    address payable public buyer;
    address payable public seller;


    function buyTicket(uint256 place) public {
        // require (_tickets[msg.sender] == Ticket(0));
        _tickets[msg.sender] = new Ticket(msg.sender, place);
    }

    function changePlace(uint new_place) public {
        // require (_tickets[msg.sender] != Ticket(0));
        Ticket(_tickets[msg.sender]).changePlace(msg.sender, new_place);
    }

    function getPlace(address account) public view returns (uint256) {
        // require (_tickets[account] != Ticket(0));
        return (_tickets[account].getPlaceID());
    }

    function getMyPlace() public view returns (uint256) {
        return (getPlace(msg.sender));
    }

}

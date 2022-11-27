// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Ticket {
    uint public price;

    uint public place_id;
    address public ticketOwner; 
    address public ticketingSystem;
    address public movieAddress;

    enum State {Init, Locked, Inactive, Refund}
    State public state;

    constructor(address ticketBuyer, uint256 place, address _movieAddress) {
        movieAddress = _movieAddress;
        ticketOwner = ticketBuyer;
        place_id = place;
        ticketingSystem = msg.sender;
    }

    ///This function can't be called at this state
    error InvalidState();

    modifier inState(State state_){
        if(state != state_){
            revert InvalidState();
        }
        _;
    }

    ///You are not the ticket owner!
    error notTicketOwner();

    modifier isTicketOwner(address caller){
        if(caller != ticketOwner){
            revert notTicketOwner();
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

     function getPlaceID() public view returns (uint256) {
        return place_id;
    }

    function changePlace(address caller, uint256 new_place) public isCinema isTicketOwner(caller) {
        place_id = new_place;
    }
}


contract CinemaTicketingSystem {

    mapping(address => Ticket[]) _tickets;
    Movie[] public movies;
    
    uint public price;
    uint public qty;
    address payable public buyer;
    address payable public owner;

    constructor(){
        owner = payable(msg.sender);
    }

    ///You are not owner of this cinema!
    error notOwner();

    modifier isOwner(){
        if(msg.sender != owner){
            revert notOwner();
        }
        _;
    }

    function getAllInformation(Ticket ticket) public view returns( address owner,
        uint place,
        address movieAddress){
        return (ticket.ticketOwner(),ticket.place_id(),ticket.movieAddress());
    }

    function printAllInformations(ticketInformation memory ticketInfo) public view returns(address owner,
        uint place,
        address movieAddress){
        return (ticketInfo.owner, ticketInfo.place, ticketInfo.movieAddress);
    }

    function getAllMovies() public view returns (Movie[] memory) {
        return movies;
    }

    function getTickets(address client) public view returns(Ticket[] memory){
        return _tickets[client];
    }

    function buyTicket(uint256 place, address movieAddress) public payable {
        // require (_tickets[msg.sender] == Ticket(0));
        require(msg.value == movies[0].price(), "Insufficient Balance");
        owner.transfer(msg.value);
        _tickets[msg.sender].push(new Ticket(msg.sender, place, movieAddress));
        movies[0].reserveSeat(place);
    }

    // function changePlace(uint new_place) public {
    //     // require (_tickets[msg.sender] != Ticket(0));
    //     Ticket(_tickets[msg.sender]).changePlace(msg.sender, new_place);
    // }

    // function getPlace(address account) public view returns (uint256) {
    //     // require (_tickets[account] != Ticket(0));
    //     return (_tickets[account].getPlaceID());
    // }

    // function getMyPlace() public view returns (uint256) {
    //     return (getPlace(msg.sender));
    // }

    function addMovie(string memory title, string memory date, uint placesCount, uint hall, string memory cinemaAddress, uint price) isOwner public  {
        movies.push(new Movie(title, date, placesCount, hall, cinemaAddress, price));
    }

    function checkSeat(uint placeNumber, address movieAddress) public view returns(bool){
        return movies[0].isSeatFree(placeNumber);
    }
}


contract Movie {
    string public title;
    string public date;
    uint public price;
    uint public hall;
    uint public placesCount;
    string cinemaAddress;
    mapping(uint => bool) isReserved;

    constructor(string memory _title, string memory _date, uint _placesCount, uint _hall, string memory _cinemaAddress, uint _price) {
        title = _title;
        date = _date;
        hall = _hall;
        price = _price;
        placesCount = _placesCount;
        cinemaAddress = _cinemaAddress;
        for(uint i;i<_placesCount;i++){
            isReserved[i] = false;
        }
    }

    function isSeatFree(uint placeNumber) public view returns(bool){
        return isReserved[placeNumber];
    }

    ///This place is reserved by another person or place number is not valid
    error notFree();

    modifier isFree(uint seatNumber){
        if(isReserved[seatNumber] == true && seatNumber <= placesCount && seatNumber > 0){
            revert notFree();
        }
        _;
    }

    function reserveSeat(uint seatNumber) isFree(seatNumber) public{
        isReserved[seatNumber] = true;
    }
}
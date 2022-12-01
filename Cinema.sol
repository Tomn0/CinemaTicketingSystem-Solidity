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
    
    uint public movieId;
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

    // function printAllInformations(ticketInformation memory ticketInfo) public view returns(address owner,
    //     uint place,
    //     address movieAddress){
    //     return (ticketInfo.owner, ticketInfo.place, ticketInfo.movieAddress);
    // }

    function getAllMovies() public view returns (Movie[] memory) {
        return movies;
    }

    function getTickets(address client) public view returns(Ticket[] memory){
        return _tickets[client];
    }

    function getPrice(Movie movie) public view returns (uint256) {
        // require (_tickets[account] != Ticket(0));
        return (movie.getPrice());
    }


    function buyTicket(uint256 place, address movieAddress, uint movieId) public payable {
        // require (_tickets[msg.sender] == Ticket(0));
        require(msg.value == movies[0].price(), "Insufficient Balance");
        owner.transfer(msg.value);
        _tickets[msg.sender].push(new Ticket(msg.sender, place, movieAddress));
        Movie _movie;
        for(uint i=0;i<movies.length;i++){
            if(movies[i].movieId() == movieId){
                _movie = movies[i];
            }
        }
        _movie.reserveSeat(place);
    }

    function checkMovieInformation(Movie movie) public view returns(string memory title, string  memory date, uint movieId, uint price, uint hall, uint placesCount, string memory cinemaAddress){
        return(movie.title(), movie.date(), movie.movieId(), movie.price(), movie.hall(), movie.placesCount(), movie.cinemaAddress());
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
        movieId++;
        movies.push(new Movie(title, date, placesCount, hall, cinemaAddress, price, movieId));
    }

    function checkSeat(uint placeNumber, address movieAddress,uint movieId) public view returns(bool){
        Movie _movie;
        for(uint i=0;i<movies.length;i++){
            if(movies[i].movieId() == movieId){
                _movie = movies[i];
            }
        }
        return _movie.isSeatFree(placeNumber);
    }
}


contract Movie {
    string public title;
    string public date;
    uint public movieId;
    uint public price;
    uint public hall;
    uint public placesCount;
    string public cinemaAddress;
    mapping(uint => bool) isReserved;

    constructor(string memory _title, string memory _date, uint _placesCount, uint _hall, string memory _cinemaAddress, uint _price, uint _movieId) {
        movieId = _movieId;
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

    // getters
    function getMovieDetails() public view returns (string[] memory) {
        string[] memory details = new string[] (2);
        details[0] = title;
        details[1] = date;
        return details;
    }

    function getmovieID() public view returns (uint) {
        return movieId;
    }

    // function getTitle() public view returns (string memory) {
    //     return title;
    // }

    // function getDate() public view returns (string memory) {
    //     return date;
    // }

    function getPrice() public view returns (uint) {
        return price;
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
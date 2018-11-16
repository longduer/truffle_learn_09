pragma solidity ^0.4.22;

contract Purchase {

    uint256 public value;
    address public seller;
    address public buyer;

    enum State {Created, Locked, Inactive}

    State public state;

    constructor() public payable {
        seller = msg.sender;
        value = msg.value / 2;
        require((2 * value) == msg.value, "value has to be even.");
    }

    modifier condition(bool _condition){
        require(_condition);
        _;
    }

    modifier onlyBuyer(){
        require(
            msg.sender == buyer,
            "only buyer can call this."
        );
        _;
    }

    modifier onlySeller(){
        require(
            msg.sender == seller,
            "only seller can call this."
        );
        _;
    }

    modifier inState(State _state) {
        require(
            state == _state,
            "invalid state"
        );
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();

    function abort()
    public
    onlySeller
    inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }

    function confirmPurchase()
    public
    inState(State.Created)
    condition(msg.value == (2 * value))
    payable
    {
        emit PurchaseConfirmed();
        buyer = msg.sender;
        state = State.Locked;
    }

    function confirmReceived()
    public
    onlyBuyer
    inState(State.Locked)
    {
        emit ItemReceived();
        state = State.Inactive;

        buyer.transfer(value);
        seller.transfer(address(this).balance);
    }
}

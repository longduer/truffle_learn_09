pragma solidity ^0.4.24;

contract BlindAuction {

    // 竞拍标地及出价的Bid对象
    struct Bid {
        bytes32 blindedBid;
        uint256 deposit;
    }

    // 竞拍收益者
    address public beneficiary;
    // 竞拍时间
    uint256 public biddingEnd;
    // 揭秘时间
    uint256 public revealEnd;
    // 竞拍结束否
    bool public ended;
    // 封装用户所有竞拍数据
    mapping(address => Bid[]) public bids;

    // 最高出价人地址
    address public highestBidder;
    // 最高出价标地
    uint256 public highestBid;
    // 取回池
    mapping(address => uint256) pendingReturns;

    event AuctionEnded(address winner, uint256 highestBid);

    modifier onlyBefore(uint256 _time){
        require(now < _time);
        _;
    }

    modifier onlyAfter(uint256 _time){
        require(now > _time);
        _;
    }

    // 构造函数 竞拍时间|揭秘时间|收益人
    constructor(
        uint256 _biddingTime,
        uint256 _revealTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    // 竞拍
    function bid(bytes32 _blindedBid) public payable onlyBefore(biddingEnd)
    {
        bids[msg.sender].push(Bid({
            blindedBid : _blindedBid,
            deposit : msg.value
            }));
    }

    // 揭秘出价
    // 已竞拍[出价ether]数组
    // 已竞拍[true|false出价]数组
    // 已竞拍[出价secret]数组
    function reveal(
        uint256[] _values,
        bool[] _fake,
        bytes32[] _secret
    )
    public
    onlyAfter(biddingEnd)
    onlyBefore(revealEnd)
    {
        // 竞拍次数
        uint256 length = bids[msg.sender].length;

        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        // 退还
        uint256 refund;
        // 循环已出价数组
        for (uint i = 0; i < length; i++) {
            // 竞拍标地及出价的Bid对象
            Bid storage _bid = bids[msg.sender][i];
            (uint256 value, bool fake, bytes32 secret) = (_values[i], _fake[i], _secret[i]);
            if (_bid.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                continue;
            }
            // 退还款总余额
            refund += _bid.deposit;
            // 只有在出价披露阶段被正确披露，已发送的以太币才会被退还
            if (!fake && _bid.deposit >= value) {
                // 如果与出价一起发送的以太币至少为 “value” 且 “fake” 不为真，则出价有效。
                if (placeBid(msg.sender, value)) {
                    refund -= value;
                }
            }
            _bid.blindedBid = bytes32(0);
        }
        msg.sender.transfer(refund);
    }

    // 出价
    function placeBid(address bidder, uint256 value) internal returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    // 取回出价
    function withdraw() public {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    // 结束竞拍
    function auctionEnd() public onlyAfter(revealEnd)
    {
        require(!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
}
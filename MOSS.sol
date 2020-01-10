pragma solidity ^0.5.1;
//pragma experimental ABIEncoderV2;

contract spectrumSharing{
   
    
    uint public bidEnd;
    uint public useEnd;// the end of the spectrum use;
    uint public freeMarketEnd;
    uint bidsLength;
    uint asksLength;
    uint public dealSuccess=0;
    address payable _owner;
    bool Bidended;
    bool Marketended;
    bool doubleAuctionFinish=false;
    
    struct Seller{
        address id;//the address of OP;
        int role;//role=-1,seller OPS；
        uint amount;//the number of channels
        uint price;//price per channel
    }
    
    struct Buyer{
    address id;//the address of OP;
    int role;//role=1,buyer OPS；
    uint amount;//the number of channels
    uint price;//price per channel
    }
    
    struct DealRecord{
        uint price;
        uint amount;
        address seller;
        address buyer;
    }
    
    struct StateRecord{
        bool stateTrade;
        int role;
        uint amount;
        uint price;
    }
    
    mapping(address=>StateRecord) public stateRecord;//true,have already matched；false，do not have already matched；
    mapping(address=>bool) executeORnot;
    mapping (address=>uint) public deposit;
    mapping (address=>uint) public debt;
    Seller[] public asks;
    Buyer[]  public bids;
    DealRecord[] public dealrecord;
    DealRecord[] public freerecord;
    
    event LogNotice(string msg);
    event LogRegisterOp(address op,int role,uint amount,uint price);
    event LogDealRecord(uint dealprice,uint dealamount,address seller, address buyer);
    event LogInsufficientFund(uint amount, string msg);
    event LogFreeMarketOrder(address op, int role, uint price, uint amount);
    
    
    constructor( uint _biddingTime, uint _useEndTime) public payable{
        bidEnd = now + _biddingTime;
        useEnd=_useEndTime;
        _owner=msg.sender;
    }
    
    //；
    function ()external payable{}
    
    modifier ownerOnly {
        require(msg.sender==_owner);
        _;
    }
    
    //submit the bid by seller/buyer OPs；
    function BidOrAskSubmit(int _role,uint _amount,uint _price)public payable {
        require( now <= bidEnd, "Bid already ended.");
        require(_role==1||_role==-1,"operator unqualified");
        require(msg.value>1000000000000000000,"Not enough deposit");
        deposit[msg.sender]=msg.value;
        executeORnot[msg.sender]=true;
        if(_role==1){
           bids.push(Buyer({id:msg.sender,role:_role, amount:_amount, price:_price}));  
           stateRecord[msg.sender]=StateRecord({stateTrade:false,role:1,amount:_amount,price:_price});
        }
        else{
           asks.push(Seller({id:msg.sender,role:_role, amount:_amount, price:_price})); 
           stateRecord[msg.sender]=StateRecord({stateTrade:false,role:-1,amount:_amount,price:_price});
        }
        emit LogRegisterOp(msg.sender,_role,_amount,_price);
    }
    
    //judge whether the bid submission stage is ended；
    function RegistrationEnd() public {

        require(now >= bidEnd, "Bid not yet ended.");
        require(!Bidended, "Bid has already been called.");
        Bidended = true;
        emit LogNotice("Bid has just ended");
    }
    
    
    //；
    function sortAskByIncrease() public ownerOnly  returns(bool) {
        require(now>bidEnd,"Bid not ended");
        if (asks.length == 0) return false;
        quickSortAsk(asks, int(0), int(asks.length-1));
        emit LogNotice("Asks Already sorted");
        return true;
    }
    
    function quickSortAsk(Seller[] storage R, int i, int j) internal {
        if (i < j) {
            int pivotAsk = partitionAsk(R, i, j);
            quickSortAsk(R, i, pivotAsk - 1);
            quickSortAsk(R, pivotAsk + 1, j);
      }
    }

    function partitionAsk(Seller[] storage R, int i, int j)internal returns(int){
        Seller memory temp = Seller({id: R[uint(i)].id, role: R[uint(i)].role, amount: R[uint(i)].amount, price:R[uint(i)].price});
        while (i < j) {
            while (i < j && R[uint(j)].price >= temp.price)
              j--;
            if (i < j) {
              R[uint(i)] = R[uint(j)];
              i++;
            }
            while (i < j && R[uint(i)].price <= temp.price)
              i++;
            if (i < j) {
              R[uint(j)] = R[uint(i)];
              j--;
            }
        }
        R[uint(i)] = Seller({id: temp.id, role: temp.role, amount: temp.amount, price: temp.price});
        delete temp;
        return i;
    }
    
    
    
    //；
    function sortBidByDecrease() public ownerOnly returns(bool){
        require(now>bidEnd,"Bid not ended");
        if (bids.length == 0) return false;
        quickSortBid(bids, int(0),int(bids.length-1));
        emit LogNotice("Bid already sorted");
        return true;
    }
    
    function quickSortBid(Buyer[] storage R, int i, int j) internal {
        if (i < j) {
            int pivotBid = partitionBid(R, i, j);
            quickSortBid(R, i, pivotBid - 1);
            quickSortBid(R, pivotBid + 1, j);
        }
    }

    function partitionBid(Buyer[] storage R, int i, int j) internal  returns(int){
        Buyer memory temp = Buyer({id: R[uint(i)].id, role: R[uint(i)].role, amount: R[uint(i)].amount, price:R[uint(i)].price});
        while (i < j) {
            while (i < j && R[uint(j)].price <= temp.price)
              j--;
            if (i < j) {
              R[uint(i)] = R[uint(j)];
              i++;
            }
            while (i < j && R[uint(i)].price >= temp.price)
              i++;
            if (i < j) {
              R[uint(j)] = R[uint(i)];
              j--;
            }
        }
        R[uint(i)] = Buyer({id: temp.id, role: temp.role, amount: temp.amount, price: temp.price});
        delete temp;
        return i;
    }
    
    //spectrum auction stage；
    function DoubleAuction()public ownerOnly{
        require(now>bidEnd,"Bid not ended");
        Auction1(asks,bids);
        doubleAuctionFinish=true;
    }
    
    function Auction1(Seller[] memory R1,Buyer[] memory R2)internal returns(bool){
        bidsLength=R2.length;
        asksLength=R1.length;
        while(asksLength!=0&&bidsLength!=0&&R2[0].price>=R1[0].price){
            uint _dealPrice=uint((R2[0].price+R1[0].price)/2);
            uint _dealAmount;
            if(R2[0].amount>R1[0].amount){
                 _dealAmount=R1[0].amount;
            }
            else {
                 _dealAmount=R2[0].amount;
            }
            dealrecord.push(DealRecord({price:_dealPrice,amount:_dealAmount,seller:R1[0].id,buyer:R2[0].id}));
            uint _totalMoney=_dealPrice*_dealAmount;
            if(deposit[R2[0].id]>=_totalMoney){
                deposit[R2[0].id]-=_totalMoney;
            }else{
                uint difference=_totalMoney-deposit[R2[0].id];
                debt[R2[0].id]+=difference;
            }
            deposit[R1[0].id]+=_totalMoney;
            emit LogDealRecord(_dealPrice,_dealAmount,R1[0].id,R2[0].id);
            R1[0].amount=R1[0].amount-_dealAmount;
            R2[0].amount=R2[0].amount-_dealAmount;
            if(R2[0].amount==0&&R1[0].amount==0){
                stateRecord[R1[0].id].stateTrade=true;
                stateRecord[R1[0].id].amount=0;
                stateRecord[R2[0].id].stateTrade=true;
                stateRecord[R2[0].id].amount=0;
                dealSuccess++;
                delete R2[0];
                delete R1[0];
                for(uint i=0;i<bidsLength-1;i++){
                    R2[i]=R2[i+1];
                }
                delete R2[bidsLength-1];
                bidsLength--;
                for(uint j=0;j<asksLength-1;j++){
                    R1[j]=R1[j+1];
                }
                delete R1[asksLength-1];
                asksLength--;
            }
            else if(R2[0].amount==0){
                stateRecord[R2[0].id].stateTrade=true;
                stateRecord[R2[0].id].amount=0;
                stateRecord[R1[0].id].stateTrade=false;
                stateRecord[R1[0].id].amount=R1[0].amount;
                dealSuccess++;
                delete R2[0];
                for(uint i=0;i<bidsLength-1;i++){
                    R2[i]=R2[i+1];
                }
                delete R2[bidsLength-1];
                bidsLength--;
            }
            else {
                stateRecord[R1[0].id].stateTrade=true;
                stateRecord[R1[0].id].amount=0;
                stateRecord[R2[0].id].stateTrade=false;
                stateRecord[R2[0].id].amount=R2[0].amount;
                delete R1[0];
                for(uint j=0;j<asksLength-1;j++){
                    R1[j]=R1[j+1];
                }
                delete R1[asksLength-1];
                asksLength--;
            }
        }
        return true;
    }
    
    //free-trading market stage
    function freeTradeBegin(uint _freeMarketTime)public ownerOnly {
        require(doubleAuctionFinish==true,"Double Auction not Ended");
        freeMarketEnd=now+_freeMarketTime;
    }
    
    function deleteOrder()public returns(bool){
        require(doubleAuctionFinish==true,"Double Auction not Ended");
        require(now<=freeMarketEnd,"Invalid delete order");
        delete stateRecord[msg.sender];
        return true;
    }
    
  
    function orderResponse(bool _releaseOrresponse,address _op,int _role, uint _price, uint _amount)public returns(bool){//role=1,buyer;role=-1,seller;
        require(now<=freeMarketEnd,"Free Market Already Ended");
        require(_role==stateRecord[msg.sender].role,"Invalid op");
        require(stateRecord[msg.sender].stateTrade==false,"Completely traded");
        require(stateRecord[msg.sender].amount!=0&&stateRecord[_op].amount!=0,"Invalid Order");
        uint _totalMoney;
        if (_releaseOrresponse==true){//发布；
            require(_amount<=stateRecord[msg.sender].amount,"Invalid amount");
            emit LogFreeMarketOrder(msg.sender, _role, _price, _amount); 
            stateRecord[msg.sender].price=_price;
            return true;
        }
        if(_releaseOrresponse==false){//购买；
            require(_price==stateRecord[_op].price,"Invalid price");
            require(_amount<=stateRecord[msg.sender].amount,"Invalid amount");
            if(_amount<=stateRecord[_op].amount){
                emit LogFreeMarketOrder(_op, _role, _price, _amount);
                _totalMoney=_price*_amount;
                stateRecord[_op].amount-=_amount;
                stateRecord[msg.sender].amount-=_amount;
                return true;
            }
            else if(stateRecord[_op].amount!=0){
                emit LogFreeMarketOrder(_op, _role, _price, stateRecord[_op].amount);
                _totalMoney=_price*stateRecord[_op].amount;
                stateRecord[_op].amount=0;
                stateRecord[msg.sender].amount-=_amount;
                return true;
            }
            if(deposit[msg.sender]>=_totalMoney){
                deposit[msg.sender]-=_totalMoney;
            }else{
                uint difference=_totalMoney-deposit[msg.sender];
                debt[msg.sender]+=difference;
            }
            deposit[_op]+=_totalMoney;
            
        }
    }
    

    
   function MarketEnd() public {

        require(now >= freeMarketEnd, "MarketDeal not yet ended.");
        require(!Marketended, "MarketDeal has already been called.");
        Marketended= true;
        emit LogNotice("MarketDeal has just ended");
    }
    
    //judge whether OPs have exchanged the spectrum usage right correctly;
    function payORnot(address _op,bool violateOrnot)public ownerOnly{
        require(now >= freeMarketEnd);
        executeORnot[_op]=violateOrnot;//false;
    }
    
    function increaseFunds() public payable {
        deposit[msg.sender]+=msg.value;
    }
    
    //withdraw the remained money；
    function withdraw()public returns(bool) {
        //require(now>bidEnd,"Bid not ended");
        require(now>freeMarketEnd);
        require(now>useEnd);//require that the withdraw can only be used after the end use of the spectrum;
        require(executeORnot[msg.sender]==true,"Invalid op");
        if(deposit[msg.sender]!=0){
            uint tempdeposit=deposit[msg.sender];
            deposit[msg.sender]=0;
            if(msg.sender.send(tempdeposit)){
                emit LogNotice("Successful to withdraw.");
                return true;
            }else{
                deposit[msg.sender]+=tempdeposit;
                return false;
            }
        }else if(debt[msg.sender]!=0){
            emit LogInsufficientFund(debt[msg.sender],"Add value to the contract");
            return true;
        }else{
            emit LogNotice("Nothing to withdraw");
            return true;
        }
    }
    
    //
    function selfDestruct() public ownerOnly {
        selfdestruct(_owner);
    }

   
    //
    function changeOwner(address payable _newOwner) public ownerOnly {
        
      if (_owner != _newOwner) {
         _owner = _newOwner;
      }


    }
    

}
